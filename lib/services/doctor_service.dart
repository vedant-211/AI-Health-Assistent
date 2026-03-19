import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/doctor.dart';
import '../services/firestore_service.dart';
import 'cache_service.dart';

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
  Future<List<DoctorModel>> fetchNearbyDoctors(double lat, double lon) async {
    final cacheKey = 'nearby_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';
    final cached = CacheService().getCachedDoctors(cacheKey);
    if (cached != null) {
      debugPrint('⚡ Doctor list served from cache');
      return cached;
    }

    try {
      final doctors = await _firestoreService.getDoctors();
      
      if (doctors.isEmpty) {
        await _firestoreService.seedDoctors();
        final seeded = await _firestoreService.getDoctors();
        CacheService().cacheDoctors(cacheKey, seeded);
        return seeded;
      }
      
      CacheService().cacheDoctors(cacheKey, doctors);
      return doctors;
    } catch (e) {
      rethrow;
    }
  }
}

