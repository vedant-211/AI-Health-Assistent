import 'package:cloud_firestore/cloud_firestore.dart';

class DiagnosisRecord {
  final String id;
  final String userId;
  final String? familyMemberId;
  final String? familyMemberName;
  final String condition;
  final String severity;
  final String description;
  final List<String> recommendations;
  final DateTime timestamp;
  final List<String> symptoms;
  final String? imageUrl;

  DiagnosisRecord({
    required this.id,
    required this.userId,
    this.familyMemberId,
    this.familyMemberName,
    required this.condition,
    required this.severity,
    required this.description,
    required this.recommendations,
    required this.timestamp,
    required this.symptoms,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'familyMemberId': familyMemberId,
      'familyMemberName': familyMemberName,
      'condition': condition,
      'severity': severity,
      'description': description,
      'recommendations': recommendations,
      'timestamp': Timestamp.fromDate(timestamp),
      'symptoms': symptoms,
      'imageUrl': imageUrl,
    };
  }

  factory DiagnosisRecord.fromMap(String id, Map<String, dynamic> map) {
    return DiagnosisRecord(
      id: id,
      userId: map['userId'] ?? '',
      familyMemberId: map['familyMemberId'],
      familyMemberName: map['familyMemberName'],
      condition: map['condition'] ?? '',
      severity: map['severity'] ?? '',
      description: map['description'] ?? '',
      recommendations: List<String>.from(map['recommendations'] ?? []),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      symptoms: List<String>.from(map['symptoms'] ?? []),
      imageUrl: map['imageUrl'],
    );
  }
}


