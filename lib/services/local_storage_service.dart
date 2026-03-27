import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

class LocalStorageService {
  static const String _userBoxName = 'userBox';
  static const String _diagnosisBoxName = 'diagnosisBox';
  static const String _doctorsBoxName = 'doctorsBox';
  static const String _appointmentsBoxName = 'appointmentsBox';
  
  // Singleton pattern
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    await Hive.initFlutter();
    
    // Open boxes for caching
    try {
      await Future.wait([
        Hive.openBox(_userBoxName),
        Hive.openBox(_diagnosisBoxName),
        Hive.openBox(_doctorsBoxName),
        Hive.openBox(_appointmentsBoxName),
      ]);
      _isInitialized = true;
      debugPrint('✅ Hive LocalStorage initialized successfully');
    } catch (e) {
      debugPrint('❌ Hive initialization error: $e');
    }
  }

  // --- Generic Generic Get/Put Methods ---
  
  Box _getBox(String boxName) {
    if (!Hive.isBoxOpen(boxName)) {
      throw Exception('Box $boxName is not open. Ensure LocalStorageService.init() is called.');
    }
    return Hive.box(boxName);
  }

  Future<void> saveData(String boxName, String key, dynamic data) async {
    try {
      final box = _getBox(boxName);
      await box.put(key, data);
    } catch (e) {
      debugPrint('❌ Error saving to $boxName: $e');
    }
  }

  dynamic getData(String boxName, String key, {dynamic defaultValue}) {
    try {
      if (!Hive.isBoxOpen(boxName)) return defaultValue;
      final box = Hive.box(boxName);
      return box.get(key, defaultValue: defaultValue);
    } catch (e) {
      debugPrint('❌ Error reading from $boxName: $e');
      return defaultValue;
    }
  }
  
  Future<void> clearAll() async {
    await Future.wait([
      _getBox(_userBoxName).clear(),
      _getBox(_diagnosisBoxName).clear(),
      _getBox(_doctorsBoxName).clear(),
      _getBox(_appointmentsBoxName).clear(),
    ]);
    debugPrint('🧹 Cleared all local cache');
  }

  // Helper getters for explicit typed responses could be added here
  
  // User Profile Caching
  Future<void> cacheUserProfile(String uid, Map<String, dynamic> data) async {
    await saveData(_userBoxName, uid, data);
  }
  
  Map<String, dynamic>? getCachedUserProfile(String uid) {
    var data = getData(_userBoxName, uid);
    if (data != null) {
      // Convert map from dynamic to string keys if necessary
      return Map<String, dynamic>.from(data);
    }
    return null;
  }
  
  // Cache lists
  Future<void> cacheList(String boxName, String key, List<Map<String, dynamic>> items) async {
    await saveData(boxName, key, items);
  }
  
  List<Map<String, dynamic>> getCachedList(String boxName, String key) {
    var data = getData(boxName, key);
    if (data != null && data is List) {
       return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  static const String _lastDiagnosisPrefix = 'last_diagnosis_';

  Future<void> cacheLastDiagnosis(String userId, Map<String, dynamic> payload) async {
    await saveData(_diagnosisBoxName, '$_lastDiagnosisPrefix$userId', payload);
  }

  Map<String, dynamic>? getLastDiagnosis(String userId) {
    final raw = getData(_diagnosisBoxName, '$_lastDiagnosisPrefix$userId');
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }
}
