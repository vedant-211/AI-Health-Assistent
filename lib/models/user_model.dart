import 'package:cloud_firestore/cloud_firestore.dart';
import 'family_member.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? profilePic;
  final int? age;
  final String? gender;
  final double healthScore;
  final DateTime? createdAt;
  final List<FamilyMember> familyMembers;
  final String primaryLocation;
  final String preferredLanguage;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.profilePic,
    this.age,
    this.gender,
    this.healthScore = 80.0,
    this.createdAt,
    this.familyMembers = const [],
    this.primaryLocation = 'Mumbai, India',
    this.preferredLanguage = 'English',
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      profilePic: map['profilePic'],
      age: map['age'],
      gender: map['gender'],
      healthScore: (map['healthScore'] ?? 80.0).toDouble(),
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
      familyMembers: (map['familyMembers'] as List? ?? []).map((e) => FamilyMember.fromMap(e)).toList(),
      primaryLocation: map['primaryLocation'] ?? 'Mumbai, India',
      preferredLanguage: map['preferredLanguage'] ?? 'English',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'profilePic': profilePic,
      'age': age,
      'gender': gender,
      'healthScore': healthScore,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'familyMembers': familyMembers.map((e) => e.toMap()).toList(),
      'primaryLocation': primaryLocation,
      'preferredLanguage': preferredLanguage,
    };
  }
}
