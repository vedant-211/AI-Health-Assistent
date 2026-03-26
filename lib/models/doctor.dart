import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/asset_path.dart';

class DoctorModel {
  String id;
  String name;
  String image;
  Color imageBox;
  List<String> specialties;
  double score;
  String bio;
  bool isAvailable;
  String nextAvailable;
  DateTime? lastUpdated;
  int experienceYears;
  List<String> languages;
  List<String> consultationModes;
  int ratingCount;
  List<CalendarModel> calendar;
  List<TimeModel> time;
  String nmcRegistrationNumber;
  double consultationFee;
  String clinicAddress;
  double latitude;
  double longitude;

  DoctorModel({
    required this.id,
    required this.name,
    required this.image,
    required this.imageBox,
    required this.specialties,
    required this.score,
    required this.bio,
    required this.calendar,
    required this.time,
    required this.experienceYears,
    required this.languages,
    required this.consultationModes,
    required this.ratingCount,
    this.isAvailable = true,
    this.nextAvailable = '',
    this.lastUpdated,
    this.nmcRegistrationNumber = 'NMC-PENDING',
    this.consultationFee = 500.0,
    this.clinicAddress = 'Online Clinic',
    this.latitude = 19.0760,
    this.longitude = 72.8777,
  });

  bool get isCurrentlyAvailable {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    
    // Check if any calendar entry matches today
    final todayEntry = calendar.firstWhere(
      (c) => c.dayName == dayName, 
      orElse: () => CalendarModel(dayNumber: 0, dayName: '', isSelected: false)
    );
    
    if (todayEntry.dayNumber == 0) return false;

    // Check if current time falls within any of the time slots
    // For simplicity in this mock, we'll assume slots like '09:00 AM' cover an hour
    final currentTimeStr = _formatTime(now);
    return time.any((t) => _isWithinSlot(t.time, currentTimeStr));
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return 'Mon';
    }
  }

  String _formatTime(DateTime time) {
    int hour = time.hour;
    String period = 'AM';
    if (hour >= 12) {
      period = 'PM';
      if (hour > 12) hour -= 12;
    }
    if (hour == 0) hour = 12;
    return "${hour.toString().padLeft(2, '0')}:00 $period";
  }

  bool _isWithinSlot(String slotTime, String currentTime) {
    // Very basic string comparison for mock logic
    return slotTime == currentTime;
  }

  factory DoctorModel.fromMap(String id, Map<String, dynamic> map) {
    return DoctorModel(
      id: id,
      name: map['name'] ?? '',
      image: normalizeBundleAssetPath(map['image']?.toString() ?? 'assets/images/placeholder_doctor.png'),
      imageBox: Color(map['imageBox'] ?? 0xFFFFA340).withOpacity(0.3),
      specialties: List<String>.from(map['specialties'] ?? []),
      score: (map['score'] ?? 0.0).toDouble(),
      bio: map['bio'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      nextAvailable: map['nextAvailable'] ?? '',
      lastUpdated: map['lastUpdated'] != null ? (map['lastUpdated'] as Timestamp).toDate() : null,
      experienceYears: map['experienceYears'] ?? 5,
      languages: List<String>.from(map['languages'] ?? ['English']),
      consultationModes: List<String>.from(map['consultationModes'] ?? ['Clinic']),
      ratingCount: map['ratingCount'] ?? 100,
      calendar: (map['calendar'] as List? ?? []).map((e) => CalendarModel.fromMap(e as Map<String, dynamic>)).toList(),
      time: (map['time'] as List? ?? []).map((e) => TimeModel.fromMap(e as Map<String, dynamic>)).toList(),
      nmcRegistrationNumber: map['nmcRegistrationNumber'] ?? 'NMC-PENDING',
      consultationFee: (map['consultationFee'] ?? 500.0).toDouble(),
      clinicAddress: map['clinicAddress'] ?? 'Online Clinic',
      latitude: (map['latitude'] ?? 19.0760).toDouble(),
      longitude: (map['longitude'] ?? 72.8777).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image,
      'imageBox': 0xFFFFA340, // Storing base color
      'specialties': specialties,
      'score': score,
      'bio': bio,
      'isAvailable': isAvailable,
      'nextAvailable': nextAvailable,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : FieldValue.serverTimestamp(),
      'experienceYears': experienceYears,
      'languages': languages,
      'consultationModes': consultationModes,
      'ratingCount': ratingCount,
      'calendar': calendar.map((e) => e.toMap()).toList(),
      'time': time.map((e) => e.toMap()).toList(),
      'nmcRegistrationNumber': nmcRegistrationNumber,
      'consultationFee': consultationFee,
      'clinicAddress': clinicAddress,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
  
  static List<DoctorModel> getDoctors() {
    return [
      DoctorModel(
        id: 'doc1',
        name: 'Dr. Ananya Sharma',
        image: 'assets/images/doctor1.png',
        imageBox: const Color(0xffFFA340).withOpacity(0.3),
        specialties: ['Cardiology', 'Internal Medicine'],
        score: 4.9,
        experienceYears: 14,
        languages: ['English', 'Hindi', 'Marathi'],
        consultationModes: ['Clinic', 'Video'],
        ratingCount: 1240,
        isAvailable: true,
        bio: 'Senior Consultant at Lilavati Hospital. Specialized in preventive cardiology and heart health management.',
        nmcRegistrationNumber: 'MCI-84729',
        consultationFee: 1500.0,
        clinicAddress: 'Bandra West, Mumbai',
        latitude: 19.0596,
        longitude: 72.8295,
        calendar: [
          CalendarModel(dayNumber: 18, dayName: 'Mon', isSelected: true),
          CalendarModel(dayNumber: 19, dayName: 'Tue', isSelected: false),
        ],
        time: [
          TimeModel(time: '09:00 AM', isSelected: true),
          TimeModel(time: '10:00 AM', isSelected: false),
        ],
      ),
      DoctorModel(
        id: 'doc2',
        name: 'Dr. Rajesh Iyer',
        image: 'assets/images/doctor2.png',
        imageBox: const Color(0xff3CFFC4).withOpacity(0.3),
        specialties: ['Orthopedics', 'Sports Medicine'],
        score: 4.8,
        experienceYears: 12,
        languages: ['English', 'Tamil', 'Hindi'],
        consultationModes: ['Clinic'],
        ratingCount: 850,
        isAvailable: true,
        bio: 'Expert in joint reconstructions and sports-related injuries. Focused on quick recovery and holistic bone health.',
        nmcRegistrationNumber: 'MMC-49382',
        consultationFee: 1200.0,
        clinicAddress: 'Matunga East, Mumbai',
        latitude: 19.0269,
        longitude: 72.8553,
        calendar: [
          CalendarModel(dayNumber: 19, dayName: 'Tue', isSelected: true),
        ],
        time: [
          TimeModel(time: '10:00 AM', isSelected: true),
        ],
      ),
      DoctorModel(
        id: 'doc3',
        name: 'Dr. Priya Venkat',
        image: 'assets/images/doctor3.png',
        imageBox: const Color(0xffFF3C3C).withOpacity(0.3),
        specialties: ['Pediatrics', 'Neonatology'],
        score: 4.9,
        experienceYears: 15,
        languages: ['English', 'Malayalam', 'Hindi'],
        consultationModes: ['Video'],
        ratingCount: 2100,
        isAvailable: false,
        bio: 'Compassionate pediatrician focused on child nutrition and developmental milestones.',
        nmcRegistrationNumber: 'TMC-11092',
        consultationFee: 800.0,
        clinicAddress: 'Andheri East, Mumbai',
        latitude: 19.1136,
        longitude: 72.8697,
        calendar: [
          CalendarModel(dayNumber: 20, dayName: 'Wed', isSelected: true),
        ],
        time: [
          TimeModel(time: '09:00 AM', isSelected: true),
        ],
      ),
      DoctorModel(
        id: 'doc4',
        name: 'Dr. Sameer Khan',
        image: 'assets/images/doctor1.png',
        imageBox: const Color(0xffA340FF).withOpacity(0.3),
        specialties: ['Neurology', 'Sleep Medicine'],
        score: 4.7,
        experienceYears: 9,
        languages: ['English', 'Urdu', 'Hindi'],
        consultationModes: ['Clinic', 'Video'],
        ratingCount: 620,
        isAvailable: true,
        bio: 'Specializes in neuro-restorative therapies and sleep-related disorders. Attached to Kokilaben Hospital.',
        nmcRegistrationNumber: 'MMC-73629',
        consultationFee: 2000.0,
        clinicAddress: 'Andheri West, Mumbai',
        latitude: 19.1363,
        longitude: 72.8277,
        calendar: [
          CalendarModel(dayNumber: 18, dayName: 'Mon', isSelected: true),
        ],
        time: [
          TimeModel(time: '11:00 AM', isSelected: true),
        ],
      ),
      DoctorModel(
        id: 'doc5',
        name: 'Dr. Kavita Desai',
        image: 'assets/images/doctor2.png',
        imageBox: const Color(0xff5EEAD4).withOpacity(0.3),
        specialties: ['Dentist', 'Oral Surgery'],
        score: 4.9,
        experienceYears: 11,
        languages: ['English', 'Hindi', 'Gujarati'],
        consultationModes: ['Clinic', 'Video'],
        ratingCount: 980,
        isAvailable: true,
        bio: 'Consultant dental surgeon focused on painless procedures and preventive oral care.',
        nmcRegistrationNumber: 'DCI-55201',
        consultationFee: 900.0,
        clinicAddress: 'Fort, Mumbai',
        latitude: 18.9345,
        longitude: 72.8370,
        calendar: [
          CalendarModel(dayNumber: 18, dayName: 'Mon', isSelected: true),
        ],
        time: [
          TimeModel(time: '09:00 AM', isSelected: true),
        ],
      ),
      DoctorModel(
        id: 'doc6',
        name: 'Dr. Arjun Mehta',
        image: 'assets/images/doctor3.png',
        imageBox: const Color(0xffFBBF24).withOpacity(0.3),
        specialties: ['Medicine', 'Internal Medicine', 'General Physician'],
        score: 4.8,
        experienceYears: 16,
        languages: ['English', 'Hindi', 'Marathi'],
        consultationModes: ['Clinic', 'Video'],
        ratingCount: 1750,
        isAvailable: true,
        bio: 'Senior physician for chronic disease management, preventive health, and complex primary care.',
        nmcRegistrationNumber: 'MMC-88102',
        consultationFee: 1100.0,
        clinicAddress: 'Powai, Mumbai',
        latitude: 19.1183,
        longitude: 72.9058,
        calendar: [
          CalendarModel(dayNumber: 19, dayName: 'Tue', isSelected: true),
        ],
        time: [
          TimeModel(time: '10:00 AM', isSelected: true),
        ],
      ),
    ];
  }

}

class CalendarModel {
  final int dayNumber;
  final String dayName;
  bool isSelected;
  CalendarModel({
    required this.dayNumber, 
    required this.dayName,
    required this.isSelected
  });

  factory CalendarModel.fromMap(Map<String, dynamic> map) {
    return CalendarModel(
      dayNumber: map['dayNumber'] ?? 0,
      dayName: map['dayName'] ?? '',
      isSelected: map['isSelected'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayNumber': dayNumber,
      'dayName': dayName,
      'isSelected': isSelected,
    };
  }
}

class TimeModel {
  final String time;
  bool isSelected;
  TimeModel({
    required this.time,
    required this.isSelected
  });

  factory TimeModel.fromMap(Map<String, dynamic> map) {
    return TimeModel(
      time: map['time'] ?? '',
      isSelected: map['isSelected'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'isSelected': isSelected,
    };
  }
}

