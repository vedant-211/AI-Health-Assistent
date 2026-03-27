import 'package:uuid/uuid.dart';

class FamilyMember {
  final String id;
  final String name;
  final String relation; // e.g., Self, Parent, Child, Spouse
  final int age;
  final String gender;
  final double healthScore;
  final List<String> medicalHistory;
  
  FamilyMember({
    String? id,
    required this.name,
    required this.relation,
    required this.age,
    required this.gender,
    this.healthScore = 80.0,
    this.medicalHistory = const [],
  }) : id = id ?? const Uuid().v4();
  
  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'] ?? const Uuid().v4(),
      name: map['name'] ?? '',
      relation: map['relation'] ?? 'Self',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? '',
      healthScore: (map['healthScore'] ?? 80.0).toDouble(),
      medicalHistory: List<String>.from(map['medicalHistory'] ?? []),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relation': relation,
      'age': age,
      'gender': gender,
      'healthScore': healthScore,
      'medicalHistory': medicalHistory,
    };
  }
}
