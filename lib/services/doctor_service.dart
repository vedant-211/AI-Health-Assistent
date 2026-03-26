import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/doctor.dart';
import '../services/firestore_service.dart';
import 'local_storage_service.dart';

final doctorServiceProvider = Provider<DoctorService>((ref) {
  return DoctorService();
});

class DoctorService {
  final FirestoreService _firestoreService = FirestoreService();

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
  }

  /// Fetch nearby doctors from Firestore.
  /// Note: Real 'nearby' logic would require GeoFirestore, but for now we fetch all
  /// and could filter by proximity in the future.
  Future<List<DoctorModel>> fetchFilteredDoctors({
    double? lat,
    double? lon,
    String? specialty,
    String? language,
    double? maxFee,
    String? searchQuery,
    bool forceRefresh = false,
    bool narrowServerQuery = false,
  }) async {
    List<DoctorModel> allDoctors = [];
    final cacheKey = 'all_doctors_v2';

    if (narrowServerQuery && specialty != null && specialty != 'All') {
      try {
        var list = await _firestoreService.getDoctors(specialty: specialty);
        if (list.isEmpty) {
          await _firestoreService.seedDoctors();
          list = await _firestoreService.getDoctors(specialty: specialty);
        }
        return list.where((doc) {
          if (language != null && language != 'All' && !doc.languages.contains(language)) return false;
          if (maxFee != null && doc.consultationFee > maxFee) return false;
          if (searchQuery != null && searchQuery.isNotEmpty) {
            final q = searchQuery.toLowerCase();
            if (!doc.name.toLowerCase().contains(q) &&
                !doc.bio.toLowerCase().contains(q) &&
                !doc.specialties.any((s) => s.toLowerCase().contains(q))) {
              return false;
            }
          }
          return true;
        }).toList();
      } catch (e) {
        debugPrint('Specialty-scoped doctor fetch failed, falling back: $e');
      }
    }
    
    if (!forceRefresh) {
      final cachedJson = LocalStorageService().getCachedList('doctorsBox', cacheKey);
      if (cachedJson.isNotEmpty) {
        try {
          allDoctors = cachedJson.map((e) => DoctorModel.fromMap(e['id'] ?? '', Map<String, dynamic>.from(e))).toList();
          _asyncSyncDoctors(cacheKey); // Background sync
        } catch (e) {
          debugPrint('Error deserializing cached doctors: $e');
        }
      }
    }

    if (allDoctors.isEmpty || forceRefresh) {
      try {
        allDoctors = await _firestoreService.getDoctors();
        if (allDoctors.isEmpty) {
          await _firestoreService.seedDoctors();
          allDoctors = await _firestoreService.getDoctors();
        }
        
        // Cache them
        await LocalStorageService().cacheList('doctorsBox', cacheKey, allDoctors.map((d) {
          var map = d.toMap();
          map['id'] = d.id;
          return map;
        }).toList());
      } catch (e) {
        debugPrint('Failed to fetch doctors from firestore: $e');
        if (allDoctors.isEmpty) return [];
      }
    }

    // Advanced in-memory filtering
    return allDoctors.where((doc) {
      if (specialty != null && specialty != 'All' && !doc.specialties.contains(specialty)) return false;
      if (language != null && language != 'All' && !doc.languages.contains(language)) return false;
      if (maxFee != null && doc.consultationFee > maxFee) return false;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!doc.name.toLowerCase().contains(query) && 
            !doc.bio.toLowerCase().contains(query) && 
            !doc.specialties.any((s) => s.toLowerCase().contains(query))) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _asyncSyncDoctors(String cacheKey) async {
    try {
      final docs = await _firestoreService.getDoctors();
      if (docs.isNotEmpty) {
        await LocalStorageService().cacheList('doctorsBox', cacheKey, docs.map((d) {
          var map = d.toMap();
          map['id'] = d.id;
          return map;
        }).toList());
      }
    } catch (_) {}
  }
}

