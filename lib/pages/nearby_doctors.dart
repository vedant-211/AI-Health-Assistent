import 'dart:async';

import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../services/doctor_service.dart';

class NearbyDoctorsPage extends StatefulWidget {
  final DoctorService service;
  const NearbyDoctorsPage({super.key, required this.service});

  @override
  State<NearbyDoctorsPage> createState() => _NearbyDoctorsPageState();
}

class _NearbyDoctorsPageState extends State<NearbyDoctorsPage> {
  List<DoctorModel> doctors = [];
  bool loading = true;
  String? error;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _loadAndStartPolling();
  }

  Future<void> _loadAndStartPolling() async {
    await _loadDoctors();
    _poller = Timer.periodic(const Duration(seconds: 60), (_) async {
      await _loadDoctors();
    });
  }

  Future<void> _loadDoctors() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final pos = await widget.service.getCurrentLocation();
      final list = await widget.service.fetchNearbyDoctors(pos.latitude, pos.longitude);
      setState(() {
        doctors = list;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Doctors'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : RefreshIndicator(
                  onRefresh: _loadDoctors,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      final d = doctors[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: AssetImage(d.image),
                            backgroundColor: d.imageBox,
                          ),
                          title: Text(d.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.specialties.join(', ')),
                              const SizedBox(height: 4),
                              Text(d.bio, maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: d.isAvailable ? Colors.green : Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  d.isAvailable ? 'Available' : 'Next: ${d.nextAvailable}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(d.score.toString()),
                            ],
                          ),
                          onTap: () {
                            // TODO: navigate to doctor detail / booking
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
