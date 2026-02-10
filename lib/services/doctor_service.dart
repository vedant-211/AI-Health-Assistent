import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/doctor.dart';

class DoctorService {
  final String? endpoint; // optional remote API endpoint
  final String? apiKey; // optional API key

  DoctorService({this.endpoint, this.apiKey});

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
  }

  /// Fetch nearby doctors. If [endpoint] is provided it will call the remote API
  /// with `lat` and `lon` as query parameters. Otherwise it returns local
  /// mock data based on `DoctorModel.getDoctors()` and adds simple availability info.
  Future<List<DoctorModel>> fetchNearbyDoctors(double lat, double lon) async {
    if (endpoint != null) {
      final uri = Uri.parse(endpoint!).replace(queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        if (apiKey != null) 'api_key': apiKey!,
      });

      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is List) {
          return data.map((e) => _parseDoctorFromJson(e)).toList();
        }
        // If API returns object with `doctors` key
        if (data is Map && data['doctors'] is List) {
          return (data['doctors'] as List).map((e) => _parseDoctorFromJson(e)).toList();
        }
        throw Exception('Unexpected API response format');
      } else {
        throw Exception('API error: ${resp.statusCode}');
      }
    }

    // Mock fallback: use bundled doctors and attach random/simple availability
    final local = DoctorModel.getDoctors();
    final now = DateTime.now();
    for (var i = 0; i < local.length; i++) {
      local[i].isAvailable = (i % 2 == 0);
      local[i].nextAvailable = local[i].isAvailable ? 'Now' : '09:00 AM';
      local[i].lastUpdated = now;
    }
    return local;
  }

  DoctorModel _parseDoctorFromJson(Map<String, dynamic> json) {
    // Adapt parsing to your API's response shape. This is a best-effort parser.
    try {
      final name = json['name'] ?? '';
      final image = json['image'] ?? 'assets/images/jenny.png';
      final imageBox = json['imageBox'] ?? 0xFFFFA340;
      final specialties = (json['specialties'] as List?)?.map((e) => e.toString()).toList() ?? ['General'];
      final score = (json['score'] is num) ? (json['score'] as num).toDouble() : 4.5;
      final bio = json['bio'] ?? '';
      final calendar = <CalendarModel>[];
      final time = <TimeModel>[];

      return DoctorModel(
        name: name,
        image: image,
        imageBox: Color(imageBox).withOpacity(0.3),
        specialties: specialties,
        score: score,
        bio: bio,
        calendar: calendar,
        time: time,
        isAvailable: json['isAvailable'] ?? true,
        nextAvailable: json['nextAvailable'] ?? '',
        lastUpdated: json['lastUpdated'] != null ? DateTime.tryParse(json['lastUpdated']) : null,
      );
    } catch (e) {
      // Return a minimal doctor on parse error
      return DoctorModel(
        name: json['name']?.toString() ?? 'Unknown',
        image: 'assets/images/jenny.png',
        imageBox: const Color(0xffFFA340).withOpacity(0.3),
        specialties: ['General'],
        score: 4.5,
        bio: json['bio']?.toString() ?? '',
        calendar: [],
        time: [],
      );
    }
  }
}
