import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medical/pages/detail.dart';
import 'package:medical/pages/ai_symptoms.dart';
import 'package:medical/pages/nearby_doctors.dart';
import 'package:medical/services/firestore_service.dart';
import 'package:medical/services/doctor_service.dart';
import 'package:medical/models/user_model.dart';
import '../models/category.dart';
import '../models/doctor.dart';
import '../theme/app_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:medical/widgets/safe_asset_image.dart';
import 'package:medical/widgets/safe_svg_asset.dart';


class HomePage extends ConsumerStatefulWidget {
   const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with TickerProviderStateMixin {
  final List<CategoryModel> categoriesData = CategoryModel.getCategories();
  
  List<DoctorModel> _doctors = [];

  late AnimationController _aliveController;
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _aliveController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _breathingController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _loadSpecialists();
  }

  Future<void> _loadSpecialists({bool forceRefresh = false}) async {
    try {
      final docService = ref.read(doctorServiceProvider);
      final list = await docService.fetchFilteredDoctors(
        lat: 19.0760,
        lon: 72.8777,
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() { 
          _doctors = list; 
        });
      }
    } catch (e) {
      debugPrint('Error loading specialists: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Trouble connecting to specialist catalog."),
            action: SnackBarAction(label: "RETRY", onPressed: _loadSpecialists),
          )
        );
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  void dispose() {
    _aliveController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = ref.read(firestoreServiceProvider);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppStyles.bgDark,
      body: StreamBuilder<UserModel?>(
        stream: firestoreService.userProfileStream(user.uid),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) return _buildGlobalError("Profile synchronization failed", _loadSpecialists);
          final userModel = userSnapshot.data;

          final selectedCategory = categoriesData.firstWhere((c) => c.isSelected, orElse: () => categoriesData.first).name;

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: firestoreService.userAppointmentsStream(user.uid),
            builder: (context, journeySnapshot) {
              if (journeySnapshot.hasError) {
                return _buildGlobalError("Clinical journey sync issue. Check Firestore indexes.", _loadSpecialists);
              }
              final journey = journeySnapshot.data ?? [];

              return Stack(
                children: [
                  Positioned(
                    top: 100, left: -100,
                    child: FadeTransition(
                      opacity: Tween(begin: 0.3, end: 0.5).animate(_aliveController),
                      child: Container(width: 400, height: 400, decoration: const BoxDecoration(gradient: AppStyles.auraBlue, shape: BoxShape.circle)),
                    ),
                  ),
                  
                  RefreshIndicator(
                    onRefresh: () => _loadSpecialists(forceRefresh: true),
                    color: AppStyles.primaryBlue,
                    backgroundColor: AppStyles.bgSurface,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildHeader(userModel),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                 _buildWellnessScoreMinimal(userModel),
                                 const SizedBox(height: 40),
                                 _buildAliveHeroAI(context),
                                 const SizedBox(height: 48),
                                 _sectionHeader("Health Journey", "Your recent clinical milestones"),
                                 const SizedBox(height: 24),
                                 _buildHealthJourneyTimeline(journey),
                                 const SizedBox(height: 48),
                                 _sectionHeader("Specialties", "Find curated specialists"),
                                 const SizedBox(height: 24),
                                 categories(),
                                 const SizedBox(height: 48),
                                 _sectionHeader("Top Specialists", selectedCategory == 'All' ? "Trusted experts for you" : "Experts in $selectedCategory", onSeeAll: () {
                                   Navigator.push(context, MaterialPageRoute(builder: (context) => NearbyDoctorsPage(initialSpecialty: selectedCategory)));
                                 }),
                                 const SizedBox(height: 24),
                                 doctors(specialty: selectedCategory),
                                 const SizedBox(height: 40),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );

  }

  Widget _buildGlobalError(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppStyles.textSecondary, size: 60),
            const SizedBox(height: 24),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppStyles.textMain, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 40),
            _primaryButton("Retry Connection", onRetry, Icons.refresh_rounded),
          ],
        ),
      ),
    );
  }


  Widget _buildHealthJourneyTimeline(List<Map<String, dynamic>> journey) {
    if (journey.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppStyles.bgSurface.withOpacity(0.5), borderRadius: BorderRadius.circular(20), border: AppStyles.glassBorder),
        child: const Center(child: Text("No health milestones yet. Start your journey with an AI review!", style: TextStyle(color: AppStyles.textSecondary, fontSize: 13, height: 1.5), textAlign: TextAlign.center)),
      );
    }

    return Column(
      children: List.generate(journey.length.clamp(0, 3), (index) {
        final record = journey[index];
        final isLast = index == (journey.length.clamp(0, 3) - 1);
        final timestamp = (record['timestamp'] as Timestamp?)?.toDate() ?? 
                         (record['createdAt'] as Timestamp?)?.toDate() ?? 
                         DateTime.now();
        
        final date = timestamp.day == DateTime.now().day ? "Today" : 
                    (timestamp.day == DateTime.now().day - 1 ? "Yesterday" : 
                    "${timestamp.day}/${timestamp.month}");
        
        final title = record['condition'] ?? record['specialty'] ?? "Consultation";
        
        return _timelineItem(date, title, isLast: isLast, isCurrent: index == 0);
      }),
    );
  }


  Widget _timelineItem(String date, String title, {bool isLast = false, bool isCurrent = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: isCurrent ? AppStyles.primaryBlue : AppStyles.greyAccent.withOpacity(0.3), shape: BoxShape.circle)),
              if (!isLast) Expanded(child: Container(width: 1, color: AppStyles.greyAccent.withOpacity(0.1), margin: const EdgeInsets.symmetric(vertical: 4))),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isCurrent ? AppStyles.primaryBlue : AppStyles.textSecondary, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text(title, style: TextStyle(fontSize: 14, color: isCurrent ? AppStyles.textMain : AppStyles.textSecondary, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500)),
                if (!isLast) const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWellnessScoreMinimal(UserModel? user) {
    final score = user?.healthScore.toDouble() ?? 80.0;
    return GestureDetector(
      onTap: () => _showHealthAnalysis(context, score),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppStyles.bgSurface.withOpacity(0.72),
              borderRadius: BorderRadius.circular(28),
              border: AppStyles.glassBorder,
              gradient: AppStyles.glassGradient,
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(width: 50, height: 50, child: CircularProgressIndicator(value: score / 100, strokeWidth: 5, backgroundColor: AppStyles.bgLight, valueColor: const AlwaysStoppedAnimation<Color>(AppStyles.primaryBlue), strokeCap: StrokeCap.round)),
                    Text(score.toInt().toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppStyles.primaryBlue)),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Health Score", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppStyles.textMain)),
                      const SizedBox(height: 2),
                      Text("Your health is looking stable today, ${user?.name ?? 'Guest'}.", style: const TextStyle(fontSize: 12, color: AppStyles.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.insights_rounded, color: AppStyles.primaryBlue.withOpacity(0.3), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHealthAnalysis(BuildContext context, double score) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(color: AppStyles.bgSurface, borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppStyles.textSecondary.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text("Clinical Insights", style: TextStyle(color: AppStyles.textMain, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 32),
            _analysisItem(Icons.trending_up_rounded, "Stability", "Your vital signs and reported symptoms show a consistent 92% stability index over the last 7 days."),
            const SizedBox(height: 16),
            _analysisItem(Icons.shield_moon_rounded, "Recovery", "Sleep patterns are optimal, contributing to a high immune resilience score."),
            const SizedBox(height: 40),
            SizedBox(width: double.infinity, height: 60, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: AppStyles.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text("Proceed with Care", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)))),
          ],
        ),
      ),
    );
  }

  Widget _analysisItem(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppStyles.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: AppStyles.primaryBlue, size: 20)),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: AppStyles.textMain, fontWeight: FontWeight.w700, fontSize: 15)), const SizedBox(height: 4), Text(desc, style: const TextStyle(color: AppStyles.textSecondary, fontSize: 13, height: 1.5))])),
      ],
    );
  }


  Widget _sectionHeader(String title, String subtitle, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppStyles.textMain, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppStyles.textSecondary, fontWeight: FontWeight.w400)),
          ],
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text("See All", style: TextStyle(color: AppStyles.primaryBlue, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }


  Widget buildHeader(UserModel? user) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("${_getGreeting()},", style: const TextStyle(color: AppStyles.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)), 
                  Text(user?.name ?? 'Guest', style: const TextStyle(color: AppStyles.textMain, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1, overflow: TextOverflow.ellipsis))
                ]),
              ),
              GestureDetector(
                onTap: () {
                   showDialog(
                     context: context,
                     builder: (context) => AlertDialog(
                       backgroundColor: AppStyles.bgSurface,
                       title: const Text("Sign Out", style: TextStyle(color: AppStyles.textMain)),
                       content: const Text("Are you surely you want to leave your companion?", style: TextStyle(color: AppStyles.textSecondary)),
                       actions: [
                         TextButton(onPressed: () => Navigator.pop(context), child: const Text("Stay", style: TextStyle(color: AppStyles.primaryBlue))),
                         TextButton(onPressed: () async {
                           await FirebaseAuth.instance.signOut();
                           if (context.mounted) Navigator.pop(context);
                         }, child: const Text("Sign Out", style: TextStyle(color: Colors.redAccent))),
                       ],
                     ),
                   );
                },
                child: Semantics(button: true, label: "Profile Options", child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppStyles.bgSurface, shape: BoxShape.circle, border: AppStyles.glassBorder), child: CircleAvatar(radius: 20, backgroundColor: AppStyles.primaryBlue.withOpacity(0.1), child: const Icon(Icons.face_unlock_rounded, color: AppStyles.primaryBlue, size: 22)))),
              )
            ]),

            const SizedBox(height: 32),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xffF8FAFC), Color(0xffC4B5FD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text("Your family's\nhealth partner.", style: TextStyle(color: Colors.white, fontSize: 32, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
            ),
            const SizedBox(height: 24),
            _searchBarMinimal(),
          ],
        ),
      ),
    );
  }


  Widget _searchBarMinimal() {
    return Container(
      height: 60, decoration: BoxDecoration(color: AppStyles.bgSurface, borderRadius: BorderRadius.circular(20), border: AppStyles.glassBorder),
      child: TextField(
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => NearbyDoctorsPage(initialSpecialty: 'All', searchQuery: v.trim())));
          }
        },
        style: const TextStyle(color: AppStyles.textMain), 
        decoration: InputDecoration(hintText: "Search specialists...", hintStyle: const TextStyle(color: AppStyles.textSecondary, fontSize: 14), prefixIcon: const Icon(Icons.search_rounded, color: AppStyles.textSecondary, size: 20), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20))
      ),
    );
  }

  Widget _buildAliveHeroAI(BuildContext context) {
    return AnimatedBuilder(
      animation: _aliveController,
      builder: (context, child) {
        return Hero(
          tag: 'ai_banner',
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppStyles.bgSurface, 
                borderRadius: BorderRadius.circular(40), 
                border: AppStyles.glassBorder,
                boxShadow: [
                  BoxShadow(
                    color: AppStyles.primaryBlue.withOpacity(0.08 * _aliveController.value), 
                    blurRadius: 30, 
                    spreadRadius: 5 + (10 * _aliveController.value)
                  )
                ]
              ),
              child: Column(
                children: [
                   Stack(
                     alignment: Alignment.center,
                     children: [
                       Container(
                         width: 70 + (10 * _aliveController.value),
                         height: 70 + (10 * _aliveController.value),
                         decoration: BoxDecoration(
                           shape: BoxShape.circle,
                           color: AppStyles.primaryBlue.withOpacity(0.15 * _aliveController.value),
                         ),
                       ),
                       Lottie.asset(
                         'assets/lottie/companion_breathe.json',
                         width: 100, height: 100,
                         errorBuilder: (context, error, stackTrace) => Container(
                           width: 64, height: 64,
                           decoration: const BoxDecoration(gradient: AppStyles.primaryGradient, shape: BoxShape.circle),
                           child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 24),
                   const Text("SwasthMitra Companion", style: TextStyle(color: AppStyles.textMain, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                   const SizedBox(height: 8),
                   const Text("I'm sensing your health patterns...\nTap to discuss anything.", textAlign: TextAlign.center, style: TextStyle(color: AppStyles.textSecondary, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500)),
                   const SizedBox(height: 32),
                   SizedBox(
                     width: double.infinity,
                     child: ElevatedButton(
                       onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AISymptomsPage())),
                       style: ElevatedButton.styleFrom(backgroundColor: AppStyles.primaryBlue, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                       child: const Text("Start Clinical Review", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                     ),
                   ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget categories() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final isSelected = categoriesData[index].isSelected;
          return Column(children: [
            GestureDetector(onTap: () {
              setState(() {
                for (var item in categoriesData) item.isSelected = false;
                categoriesData[index].isSelected = true;
              });
              _loadSpecialists(forceRefresh: true);
            }, child: AnimatedContainer(duration: AppStyles.animationDuration, width: 68, height: 68, decoration: BoxDecoration(color: isSelected ? AppStyles.primaryBlue.withOpacity(0.1) : AppStyles.bgSurface, borderRadius: BorderRadius.circular(22), border: isSelected ? Border.all(color: AppStyles.primaryBlue, width: 2) : AppStyles.glassBorder), child: Center(child: SafeSvgAsset(assetPath: categoriesData[index].vector, width: 26, height: 26, colorFilter: ColorFilter.mode(isSelected ? AppStyles.primaryBlue : AppStyles.textSecondary, BlendMode.srcIn))))),
            const SizedBox(height: 8),
            Text(categoriesData[index].name, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: isSelected ? AppStyles.primaryBlue : AppStyles.textSecondary)),
          ]);
        },
        separatorBuilder: (context, index) => const SizedBox(width: 18),
        itemCount: categoriesData.length,
      ),
    );
  }

  Widget doctors({String specialty = 'All'}) {
    final filteredDoctors = specialty == 'All' 
        ? _doctors 
        : _doctors.where((d) => d.specialties.contains(specialty)).toList();

    if (filteredDoctors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.person_search_rounded, color: AppStyles.textSecondary.withOpacity(0.2), size: 48),
              const SizedBox(height: 16),
              const Text("No specialists found locally.", style: TextStyle(color: AppStyles.textSecondary, fontSize: 13)),
              const SizedBox(height: 24),
              _primaryButton("Refresh Catalog", _loadSpecialists, Icons.refresh_rounded),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final doc = filteredDoctors[index];

        return Container(
          decoration: BoxDecoration(color: AppStyles.bgSurface, borderRadius: BorderRadius.circular(24), border: AppStyles.glassBorder),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(doctorModel: doc))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Hero(tag: doc.name, child: _doctorImage(doc)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                               Expanded(child: Text(doc.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppStyles.textMain, letterSpacing: -0.5, overflow: TextOverflow.ellipsis))),
                               _availabilityIndicator(doc.isCurrentlyAvailable),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(doc.specialties.first, style: const TextStyle(color: AppStyles.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 12),
                          Row(children: [const Icon(Icons.star_rounded, color: Colors.amber, size: 16), const SizedBox(width: 4), Text(doc.score.toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppStyles.textMain))]),
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
      itemCount: filteredDoctors.length,
    );
  }

  Widget _doctorImage(DoctorModel doc) {
    return Container(
      width: 70, height: 70,
      decoration: BoxDecoration(color: AppStyles.bgLight, borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SafeNetworkOrAssetImage(path: doc.image, fit: BoxFit.cover, alignment: Alignment.bottomCenter),
      ),
    );
  }

  Widget _availabilityIndicator(bool available) {
    return Container(width: 8, height: 8, decoration: BoxDecoration(color: available ? Colors.greenAccent : Colors.orangeAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: (available ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.4), blurRadius: 8)]));
  }

  Widget _primaryButton(String label, VoidCallback onTap, IconData icon) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppStyles.primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

}