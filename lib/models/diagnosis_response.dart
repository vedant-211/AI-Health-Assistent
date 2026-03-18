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
    this.clinical_notes = const [],
    this.emotionalAnalysis,
    this.suggestedSpecialty,
  });
}