import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_storage_service.dart';
import '../models/diagnosis_record.dart';
import '../models/user_model.dart';
import '../models/doctor.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Collection Names ---
  static const String userCollection = 'users';
  static const String doctorCollection = 'doctors';
  static const String diagnosisCollection = 'diagnoses';
  static const String chatCollection = 'chat_history';
  static const String appointmentCollection = 'appointments';

  // --- Optimized User Profile ---

  Stream<UserModel?> userProfileStream(String uid) {
    return _db.collection(userCollection).doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      // Note: Using fromMap(snapshot.id, snapshot.data()!) to stay consistent with model
      return UserModel.fromMap(snapshot.id, snapshot.data()!);
    });
  }

  Future<void> createUserProfile(UserModel user) async {
    try {
      await _db.collection(userCollection).doc(user.uid).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      if (e is! TimeoutException) debugPrint('Firestore Error (createUserProfile): $e');
      rethrow;
    }
  }

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final cachedProfile = LocalStorageService().getCachedUserProfile(uid);
      if (cachedProfile != null) {
        _asyncFetchAndCacheProfile(uid); // Non-blocking sync
        return UserModel.fromMap(uid, cachedProfile);
      }
      
      final doc = await _db.collection(userCollection).doc(uid).get(const GetOptions(source: Source.serverAndCache));
      if (doc.exists && doc.data() != null) {
        await LocalStorageService().cacheUserProfile(uid, doc.data()!);
        return UserModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      if (e is! TimeoutException) debugPrint('Firestore Error (getUserProfile): $e');
      final cachedProfile = LocalStorageService().getCachedUserProfile(uid);
      if (cachedProfile != null) return UserModel.fromMap(uid, cachedProfile);
      return null;
    }
  }

  void _asyncFetchAndCacheProfile(String uid) async {
    try {
      final doc = await _db.collection(userCollection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        await LocalStorageService().cacheUserProfile(uid, doc.data()!);
      }
    } catch (_) {}
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection(userCollection).doc(uid).update(data);
    } catch (e) {
      if (e is! TimeoutException) debugPrint('Firestore Error (updateUserProfile): $e');
      rethrow;
    }
  }

  // --- Optimized Doctors ---

  Future<List<DoctorModel>> getDoctors({String? specialty}) async {
    try {
      Query<Map<String, dynamic>> query = _db.collection(doctorCollection);
      if (specialty != null && specialty.isNotEmpty && specialty != 'All') {
        query = query.where('specialties', arrayContains: specialty);
      }

      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await query.get(const GetOptions(source: Source.serverAndCache));
      } catch (_) {
        snapshot = await query.get(const GetOptions(source: Source.cache));
      }
      return snapshot.docs.map((doc) => DoctorModel.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      if (e is! TimeoutException) debugPrint('Firestore Error (getDoctors): $e');
      return [];
    }
  }

  Future<void> seedDoctors() async {
    try {
      final doctors = DoctorModel.getDoctors();
      final batch = _db.batch();
      for (var doc in doctors) {
        // Use normalized name as stable ID to prevent duplicates
        final docId = doc.name.toLowerCase().replaceAll(' ', '_').replaceAll('.', '');
        final ref = _db.collection(doctorCollection).doc(docId);
        batch.set(ref, doc.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
    } catch (e) {
      if (e is! TimeoutException) debugPrint('Firestore Error (seedDoctors): $e');
    }
  }

  // --- Diagnosis Records ---

  Future<void> saveDiagnosis(DiagnosisRecord record) async {
    try {
      await _db.collection(diagnosisCollection).add(record.toMap());
    } catch (e) {
      if (e is! TimeoutException) debugPrint('Firestore Error (saveDiagnosis): $e');
      rethrow;
    }
  }

  Future<List<DiagnosisRecord>> getUserDiagnoses(String userId) async {
    final cacheKey = 'diagnoses_$userId';
    try {
      final cachedData = LocalStorageService().getCachedList('diagnosisBox', cacheKey);
      if (cachedData.isNotEmpty) {
        _asyncSyncDiagnoses(userId, cacheKey);
        // We cached maps with 'id' added inside.
        return cachedData.map((e) => DiagnosisRecord.fromMap(e['id'] ?? '', e)).toList();
      }

      return await _fetchAndCacheDiagnoses(userId, cacheKey);
    } catch (e) {
      if (e is! TimeoutException) debugPrint('Firestore Error (getUserDiagnoses): $e');
      final cachedData = LocalStorageService().getCachedList('diagnosisBox', cacheKey);
      return cachedData.map((e) => DiagnosisRecord.fromMap(e['id'] ?? '', e)).toList();
    }
  }

  Future<List<DiagnosisRecord>> _fetchAndCacheDiagnoses(String userId, String cacheKey) async {
    final snapshot = await _db.collection(diagnosisCollection)
      .where('userId', isEqualTo: userId)
      .orderBy('timestamp', descending: true)
      .get()
      .timeout(const Duration(seconds: 5));
    
    final records = snapshot.docs.map((doc) => DiagnosisRecord.fromMap(doc.id, doc.data())).toList();
    
    // add doc.id into the map so we can deserialize offline
    final cacheableList = records.map((e) {
      final map = e.toMap();
      map['id'] = e.id; 
      // timestamp needs to be saved properly for Hive dynamic serialization if using string mapping, 
      // but Hive can store DateTime directly.
      return map;
    }).toList();
    
    await LocalStorageService().cacheList('diagnosisBox', cacheKey, cacheableList);
    return records;
  }

  void _asyncSyncDiagnoses(String userId, String cacheKey) async {
    try {
      await _fetchAndCacheDiagnoses(userId, cacheKey);
    } catch (_) {}
  }

  // --- Real-time Chat ---

  Future<void> saveChatMessage(String userId, String role, String message) async {
    try {
      await _db.collection(chatCollection).add({
        'userId': userId,
        'role': role,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e is! TimeoutException) debugPrint('Firestore Error (saveChatMessage): $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getChatStream(String userId) {
    return _db.collection(chatCollection)
      .where('userId', isEqualTo: userId)
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // --- Real-time Appointments ---

  Stream<List<Map<String, dynamic>>> userAppointmentsStream(String userId) {
    return _db.collection(appointmentCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> bookAppointment(String userId, Map<String, dynamic> appointmentData) async {
    try {
      await _db.collection(appointmentCollection).add({
        'userId': userId,
        ...appointmentData,
        'status': 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e is! TimeoutException) debugPrint('Firestore Error (bookAppointment): $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserAppointments(String userId) async {
    final cacheKey = 'appointments_$userId';
    try {
      final cachedData = LocalStorageService().getCachedList('appointmentsBox', cacheKey);
      if (cachedData.isNotEmpty) {
        _asyncSyncAppointments(userId, cacheKey);
        return cachedData;
      }
      return await _fetchAndCacheAppointments(userId, cacheKey);
    } catch (e) {
      if (e is! TimeoutException) debugPrint('Firestore Error (getUserAppointments): $e');
      return LocalStorageService().getCachedList('appointmentsBox', cacheKey);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAndCacheAppointments(String userId, String cacheKey) async {
    final snapshot = await _db.collection(appointmentCollection)
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .get();
    
    final records = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    await LocalStorageService().cacheList('appointmentsBox', cacheKey, records);
    return records;
  }

  void _asyncSyncAppointments(String userId, String cacheKey) async {
    try {
      await _fetchAndCacheAppointments(userId, cacheKey);
    } catch (_) {}
  }
}


