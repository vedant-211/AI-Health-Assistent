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