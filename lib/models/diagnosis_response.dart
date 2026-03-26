class DiagnosisResponse {
  final String condition;
  final String severity;
  final String description;
  final String urgency;
  final List<String> recommendations;
  final bool shouldConsultDoctor;
  final bool isEmergency;
  final List<String> clinical_notes;
  final String? emotionalAnalysis;
  final String? suggestedSpecialty;

  DiagnosisResponse({
    required this.condition,
    required this.severity,
    required this.description,
    required this.urgency,
    required this.recommendations,
    required this.shouldConsultDoctor,
    this.isEmergency = false,
    List<String>? clinical_notes,
    this.emotionalAnalysis,
    this.suggestedSpecialty,
  }) : clinical_notes = clinical_notes ?? [];

  static String _cleanStr(dynamic v, {String fallback = '', int max = 8000}) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    if (s.isEmpty) return fallback;
    final stripped = s.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    if (stripped.length > max) return stripped.substring(0, max);
    return stripped;
  }

  static List<String> _stringList(dynamic v) {
    if (v is! List) return [];
    return v.map((e) => _cleanStr(e, max: 2000)).where((s) => s.isNotEmpty).toList();
  }

  /// Builds a clinically safe response from parsed JSON with strict type checks.
  factory DiagnosisResponse.fromValidatedMap(Map<String, dynamic> data, String userName) {
    final name = _cleanStr(userName, max: 120);
    final condition = _cleanStr(data['condition'], fallback: 'General concern', max: 200);
    final severityRaw = _cleanStr(data['severity'], fallback: 'mild', max: 32).toLowerCase();
    final severity = ['mild', 'moderate', 'severe'].contains(severityRaw) ? severityRaw : 'mild';
    var description = _cleanStr(data['description'], max: 4000);
    if (description.isEmpty) {
      description = "I'm here to support you through this${name.isEmpty ? '' : ', $name'}.";
    }
    final urgencyRaw = _cleanStr(data['urgency'], fallback: 'low', max: 32).toLowerCase();
    final urgency = ['low', 'moderate', 'high', 'emergency'].contains(urgencyRaw) ? urgencyRaw : 'low';
    var recs = _stringList(data['recommendations']);
    if (recs.isEmpty) {
      recs = ['Rest and monitor how you feel', 'Stay hydrated', 'Reach out to a clinician if symptoms persist'];
    }
    final shouldConsult = data['shouldConsultDoctor'] is bool
        ? data['shouldConsultDoctor'] as bool
        : true;
    final isEmerg = data['isEmergency'] is bool ? data['isEmergency'] as bool : false;
    final notes = _stringList(data['clinical_notes']);
    final emotional = data['emotional_analysis'] != null ? _cleanStr(data['emotional_analysis'], max: 500) : null;
    final specialty =
        data['suggested_specialty'] != null ? _cleanStr(data['suggested_specialty'], max: 120) : null;

    return DiagnosisResponse(
      condition: condition,
      severity: severity,
      description: description,
      urgency: urgency,
      recommendations: recs,
      shouldConsultDoctor: shouldConsult,
      isEmergency: isEmerg,
      clinical_notes: notes,
      emotionalAnalysis: (emotional == null || emotional.isEmpty) ? null : emotional,
      suggestedSpecialty: (specialty == null || specialty.isEmpty) ? null : specialty,
    );
  }

  Map<String, dynamic> toCacheMap() {
    return {
      'condition': condition,
      'severity': severity,
      'description': description,
      'urgency': urgency,
      'recommendations': recommendations,
      'shouldConsultDoctor': shouldConsultDoctor,
      'isEmergency': isEmergency,
      'clinical_notes': clinical_notes,
      'emotional_analysis': emotionalAnalysis,
      'suggested_specialty': suggestedSpecialty,
    };
  }

  static DiagnosisResponse? fromCacheMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    try {
      return DiagnosisResponse.fromValidatedMap(m, '');
    } catch (_) {
      return null;
    }
  }
}
