import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/diagnosis_record.dart';
import '../models/user_model.dart';
import '../models/doctor.dart';

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
      debugPrint('Firestore Error (createUserProfile): $e');
      rethrow;
    }
  }

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection(userCollection).doc(uid).get(const GetOptions(source: Source.serverAndCache));
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Firestore Error (getUserProfile): $e');
      return null;
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection(userCollection).doc(uid).update(data);
    } catch (e) {
      debugPrint('Firestore Error (updateUserProfile): $e');
      rethrow;
    }
  }

  // --- Optimized Doctors ---

  Future<List<DoctorModel>> getDoctors({String? specialty}) async {
    try {
      Query query = _db.collection(doctorCollection);
      if (specialty != null && specialty != 'All') {
        query = query.where('specialties', arrayContains: specialty);
      }
      
      final snapshot = await query.get(const GetOptions(source: Source.server)).catchError((_) {
        return query.get(const GetOptions(source: Source.cache));
      });
      return snapshot.docs.map((doc) => DoctorModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Firestore Error (getDoctors): $e');
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
      debugPrint('Firestore Error (seedDoctors): $e');
    }
  }

  // --- Diagnosis Records ---

  Future<void> saveDiagnosis(DiagnosisRecord record) async {
    try {
      await _db.collection(diagnosisCollection).add(record.toMap());
    } catch (e) {
      debugPrint('Firestore Error (saveDiagnosis): $e');
      rethrow;
    }
  }

  Future<List<DiagnosisRecord>> getUserDiagnoses(String userId) async {
    try {
      final snapshot = await _db.collection(diagnosisCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get()
        .timeout(const Duration(seconds: 5));
      
      return snapshot.docs.map((doc) => DiagnosisRecord.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      debugPrint('Firestore Error (getUserDiagnoses): $e');
      return [];
    }
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
      debugPrint('Firestore Error (saveChatMessage): $e');
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
      debugPrint('Firestore Error (bookAppointment): $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserAppointments(String userId) async {
    try {
      final snapshot = await _db.collection(appointmentCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
      
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('Firestore Error (getUserAppointments): $e');
      return [];
    }
  }
}


