import 'dart:async';
import '../models/doctor.dart';
import '../models/diagnosis_response.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // In-memory cache for demo/session resilience
  final Map<String, List<DoctorModel>> _doctorCache = {};
  final Map<String, DiagnosisResponse> _aiCache = {};
  
  // Last updated timestamps
  final Map<String, DateTime> _doctorTimestamps = {};

  void cacheDoctors(String key, List<DoctorModel> doctors) {
    _doctorCache[key] = doctors;
    _doctorTimestamps[key] = DateTime.now();
  }

  List<DoctorModel>? getCachedDoctors(String key) {
    final timestamp = _doctorTimestamps[key];
    if (timestamp == null) return null;
    
    // Cache valid for 30 minutes
    if (DateTime.now().difference(timestamp).inMinutes > 30) {
      _doctorCache.remove(key);
      _doctorTimestamps.remove(key);
      return null;
    }
    return _doctorCache[key];
  }

  void cacheAIResponse(String key, DiagnosisResponse response) {
    _aiCache[key] = response;
  }

  DiagnosisResponse? getCachedAIResponse(String key) {
    return _aiCache[key];
  }

  void clearCache() {
    _doctorCache.clear();
    _aiCache.clear();
    _doctorTimestamps.clear();
  }
}
