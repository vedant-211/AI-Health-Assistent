class SymptomModel {
  String name;
  bool isSelected;
  String? severity; // mild, moderate, severe

  SymptomModel({
    required this.name,
    this.isSelected = false,
    this.severity
  });

  static List<SymptomModel> getCommonSymptoms() {
    return [
      SymptomModel(name: 'Fever'),
      SymptomModel(name: 'Cough'),
      SymptomModel(name: 'Headache'),
      SymptomModel(name: 'Body Ache'),
      SymptomModel(name: 'Sore Throat'),
      SymptomModel(name: 'Fatigue'),
      SymptomModel(name: 'Shortness of Breath'),
      SymptomModel(name: 'Nausea'),
      SymptomModel(name: 'Vomiting'),
      SymptomModel(name: 'Diarrhea'),
      SymptomModel(name: 'Congestion'),
      SymptomModel(name: 'Rash'),
      SymptomModel(name: 'Dizziness'),
      SymptomModel(name: 'Chest Pain'),
      SymptomModel(name: 'Stomach Pain'),
      SymptomModel(name: 'Joint Pain'),
    ];
  }
}

class DiagnosisResponse {
  String condition;
  String severity;
  String description;
  List<String> recommendations;
  String urgency; // low, moderate, high, emergency
  bool shouldConsultDoctor;

  DiagnosisResponse({
    required this.condition,
    required this.severity,
    required this.description,
    required this.recommendations,
    required this.urgency,
    required this.shouldConsultDoctor
  });
}
