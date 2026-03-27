import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/doctor.dart';
import '../services/doctor_service.dart';
import '../theme/app_styles.dart';
import '../widgets/safe_asset_image.dart';
import 'detail.dart';

class NearbyDoctorsPage extends ConsumerStatefulWidget {
  final String initialSpecialty;
  final String? searchQuery;
  const NearbyDoctorsPage({super.key, this.initialSpecialty = 'All', this.searchQuery});

  @override
  ConsumerState<NearbyDoctorsPage> createState() => _NearbyDoctorsPageState();
}

class _NearbyDoctorsPageState extends ConsumerState<NearbyDoctorsPage> with SingleTickerProviderStateMixin {
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
    await _loadDoctors(forceRefresh: false);
    _poller = Timer.periodic(const Duration(seconds: 60), (_) async {
      await _loadDoctors(forceRefresh: false);
    });
  }

  Future<void> _loadDoctors({required bool forceRefresh}) async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final service = ref.read(doctorServiceProvider);
      final list = await service.fetchFilteredDoctors(
        lat: 19.0760,
        lon: 72.8777,
        specialty: widget.initialSpecialty == 'All' ? null : widget.initialSpecialty,
        searchQuery: widget.searchQuery,
        forceRefresh: forceRefresh,
        narrowServerQuery: widget.initialSpecialty != 'All',
      );
      if (!mounted) return;
      setState(() {
        doctors = list;
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
      floatingActionButton: loading
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _loadDoctors(forceRefresh: true),
              backgroundColor: AppStyles.primaryBlue,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text('Refresh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppStyles.textSecondary, size: 48),
            const SizedBox(height: 16),
            Text('Could not refresh specialists.', textAlign: TextAlign.center, style: TextStyle(color: AppStyles.textMain, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(error ?? '', textAlign: TextAlign.center, style: const TextStyle(color: AppStyles.textSecondary, fontSize: 12)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadDoctors(forceRefresh: true),
              style: ElevatedButton.styleFrom(backgroundColor: AppStyles.primaryBlue, foregroundColor: Colors.white),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 76,
                        height: 76,
                        color: AppStyles.bgWhite.withOpacity(0.5),
                        child: SafeNetworkOrAssetImage(path: d.image, fit: BoxFit.cover, alignment: Alignment.bottomCenter),
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
