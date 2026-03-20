import 'dart:async';
import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../services/doctor_service.dart';
import '../theme/app_styles.dart';
import 'detail.dart';

class NearbyDoctorsPage extends StatefulWidget {
  final DoctorService service;
  final String initialSpecialty;
  final String? searchQuery;
  const NearbyDoctorsPage({super.key, required this.service, this.initialSpecialty = 'All', this.searchQuery});

  @override
  State<NearbyDoctorsPage> createState() => _NearbyDoctorsPageState();
}

class _NearbyDoctorsPageState extends State<NearbyDoctorsPage> with SingleTickerProviderStateMixin {
  List<DoctorModel> doctors = [];
  bool loading = true;
  String? error;
  Timer? _poller;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _loadAndStartPolling();
  }

  Future<void> _loadAndStartPolling() async {
    await _loadDoctors();
    _poller = Timer.periodic(const Duration(seconds: 60), (_) async {
      await _loadDoctors();
    });
  }

  Future<void> _loadDoctors() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final pos = await widget.service.getCurrentLocation();
      final list = await widget.service.fetchNearbyDoctors(pos.latitude, pos.longitude);
      if (!mounted) return;
      if (!mounted) return;
      setState(() {
        Iterable<DoctorModel> filtered = list;
        if (widget.initialSpecialty != 'All') {
          filtered = filtered.where((d) => d.specialties.contains(widget.initialSpecialty));
        }
        if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
          final q = widget.searchQuery!.toLowerCase();
          filtered = filtered.where((d) => d.name.toLowerCase().contains(q) || d.specialties.any((s) => s.toLowerCase().contains(q)));
        }
        doctors = filtered.toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    _poller?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: AppStyles.primaryBlue,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                widget.initialSpecialty == 'All' ? 'Nearby Specialists' : '${widget.initialSpecialty} Near You',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5),
              ),
              background: Container(decoration: const BoxDecoration(gradient: AppStyles.primaryGradient)),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: loading
                ? _buildLoadingState()
                : error != null
                    ? _buildErrorState()
                    : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppStyles.primaryBlue, strokeWidth: 3),
          const SizedBox(height: 24),
          Text(
            'Locating top specialists near you...',
            style: TextStyle(color: AppStyles.textSecondary.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500),
          )
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('Failed to load: $error')));
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: doctors.length,
      itemBuilder: (context, index) {
        final d = doctors[index];
        return Container(
          decoration: BoxDecoration(
            color: AppStyles.bgSurface, // Changed to surface for consistency
            borderRadius: BorderRadius.circular(28),
            border: AppStyles.glassBorder,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(doctorModel: d))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppStyles.bgWhite.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(alignment: Alignment.bottomCenter, image: AssetImage(d.image)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(d.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppStyles.textMain, letterSpacing: -0.5)),
                              if (d.isCurrentlyAvailable) 
                                _buildLiveIndicator()
                              else
                                _buildOfflineIndicator(d.nextAvailable),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(d.specialties.join(", "), style: const TextStyle(color: AppStyles.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(d.score.toString(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppStyles.textMain)),
                              const SizedBox(width: 12),
                              Icon(Icons.location_on_rounded, color: AppStyles.primaryBlue.withOpacity(0.4), size: 14),
                              const SizedBox(width: 4),
                              Text("${(0.5 + (index * 0.7) % 4.5).toStringAsFixed(1)} km", style: TextStyle(color: AppStyles.textSecondary.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600)),

                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 16),
    );
  }

  Widget _buildLiveIndicator() {
    return FadeTransition(
      opacity: _pulseController,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.green, blurRadius: 4)])),
            const SizedBox(width: 6),
            const Text("LIVE", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineIndicator(String next) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AppStyles.textSecondary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(Icons.access_time_filled_rounded, color: AppStyles.textSecondary.withOpacity(0.5), size: 12),
          const SizedBox(width: 6),
          Text(next.isNotEmpty ? next : "OFFLINE", style: TextStyle(color: AppStyles.textSecondary.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
