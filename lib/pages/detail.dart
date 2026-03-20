import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medical/models/doctor.dart';
import 'package:medical/services/firestore_service.dart';
import '../theme/app_styles.dart';

class DetailPage extends StatefulWidget {
  final DoctorModel doctorModel;
  const DetailPage({
    required this.doctorModel,
    super.key
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<CalendarModel> calendarData = [];
  List<TimeModel> timeData = [];
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    calendarData = widget.doctorModel.calendar;
    timeData = widget.doctorModel.time;
  }

  @override
  Widget build(BuildContext context) {
    // ... (rest of build remains same)
    return Scaffold(
      backgroundColor: AppStyles.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240.0,
            pinned: true,
            backgroundColor: AppStyles.primaryBlue,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppStyles.primaryGradient),
                child: Center(
                  child: Hero(
                    tag: widget.doctorModel.name,
                    child: Container(
                      width: 140, height: 140,
                      margin: const EdgeInsets.only(top: 40),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.15), width: 3),
                        image: DecorationImage(alignment: Alignment.bottomCenter, image: AssetImage(widget.doctorModel.image)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -32, 0),
              decoration: const BoxDecoration(
                color: AppStyles.bgLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildRefinedProfileHeader(),
                   const SizedBox(height: 32),
                   _sectionTitle("Expert Biography"),
                   const SizedBox(height: 8),
                   _buildBiography(),
                   const SizedBox(height: 32),
                   _sectionTitle("Secure Session Slot"),
                   const SizedBox(height: 16),
                   _buildCalendar(),
                   const SizedBox(height: 32),
                   _buildTimeGrid(),
                   const SizedBox(height: 50),
                   _buildRefinedBookButton(),
                   const SizedBox(height: 24),
                   _buildConsultationInfo(),
                   const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppStyles.textMain, letterSpacing: -0.5));
  }

  Widget _buildRefinedProfileHeader() {
    return Column(
      children: [
        Text(widget.doctorModel.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppStyles.textMain, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(widget.doctorModel.specialties.join(" • "), style: TextStyle(fontSize: 13, color: AppStyles.textSecondary.withOpacity(0.6), fontWeight: FontWeight.w500)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRefinedStat(Icons.star_rounded, Colors.amber, widget.doctorModel.score.toString(), "Rating"),
            const SizedBox(width: 8),
            _buildRefinedStat(Icons.reviews_rounded, Colors.blueAccent, "${(widget.doctorModel.ratingCount / 1000).toStringAsFixed(1)}k", "Reviews"),
            const SizedBox(width: 8),
            _buildRefinedStat(Icons.verified_user_rounded, Colors.green, "${widget.doctorModel.experienceYears}yrs+", "Expert"),
          ],
        )
      ],
    );
  }

  Widget _buildRefinedStat(IconData icon, Color color, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppStyles.bgWhite, borderRadius: BorderRadius.circular(16), boxShadow: AppStyles.subtleShadow, border: Border.all(color: AppStyles.greyAccent.withOpacity(0.2))),
      child: Column(children: [Icon(icon, color: color, size: 20), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppStyles.textMain)), Text(label, style: TextStyle(fontSize: 9, color: AppStyles.textSecondary.withOpacity(0.4), fontWeight: FontWeight.w600))]),
    );
  }

  Widget _buildBiography() {
    return Text(widget.doctorModel.bio, style: TextStyle(fontSize: 14, height: 1.6, color: AppStyles.textSecondary.withOpacity(0.8)));
  }

  Widget _buildConsultationInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppStyles.bgWhite, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppStyles.greyAccent.withOpacity(0.2))),
      child: Column(
        children: [
          _infoRow(Icons.translate_rounded, "Languages", widget.doctorModel.languages.join(", ")),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          _infoRow(Icons.video_camera_back_rounded, "Modes", widget.doctorModel.consultationModes.join(" & ")),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppStyles.primaryBlue),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppStyles.textSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppStyles.textMain)),
      ],
    );
  }

  Widget _buildCalendar() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final isSelected = calendarData[index].isSelected;
          return GestureDetector(
            onTap: () => setState(() { for (var item in calendarData) item.isSelected = false; calendarData[index].isSelected = true; }),
            child: AnimatedContainer(duration: AppStyles.animationDuration, width: 64, decoration: BoxDecoration(color: isSelected ? AppStyles.primaryBlue : AppStyles.bgWhite, borderRadius: BorderRadius.circular(18), boxShadow: isSelected ? AppStyles.floatingShadow : AppStyles.subtleShadow, border: Border.all(color: isSelected ? AppStyles.primaryBlue : AppStyles.greyAccent.withOpacity(0.2))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(calendarData[index].dayNumber.toString(), style: TextStyle(color: isSelected ? Colors.white : AppStyles.textMain, fontWeight: FontWeight.w800, fontSize: 18)), Text(calendarData[index].dayName, style: TextStyle(color: isSelected ? Colors.white70 : AppStyles.textSecondary, fontSize: 12))])),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemCount: calendarData.length,
      ),
    );
  }

  Widget _buildTimeGrid() {
    return Wrap(
      spacing: 10, runSpacing: 10,
      children: timeData.map((t) {
        final isSelected = t.isSelected;
        return GestureDetector(
          onTap: () => setState(() { for (var item in timeData) item.isSelected = false; t.isSelected = true; }),
          child: AnimatedContainer(duration: AppStyles.animationDuration, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: isSelected ? AppStyles.primaryBlue : AppStyles.bgWhite, borderRadius: BorderRadius.circular(14), boxShadow: isSelected ? AppStyles.floatingShadow : AppStyles.subtleShadow, border: Border.all(color: isSelected ? AppStyles.primaryBlue : AppStyles.greyAccent.withOpacity(0.2))), child: Text(t.time, style: TextStyle(color: isSelected ? Colors.white : AppStyles.textMain, fontWeight: FontWeight.w700, fontSize: 13))),
        );
      }).toList(),
    );
  }

  Widget _buildRefinedBookButton() {
    final selDate = calendarData.where((c) => c.isSelected).firstOrNull;
    final selTime = timeData.where((t) => t.isSelected).firstOrNull;
    final enabled = selDate != null && selTime != null;
    return Container(
      width: double.infinity, height: 64,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: enabled ? AppStyles.floatingShadow : null),
      child: ElevatedButton(onPressed: (enabled && !_isBooking) ? _bookAppointment : null, style: ElevatedButton.styleFrom(backgroundColor: AppStyles.primaryBlue, disabledBackgroundColor: AppStyles.greyAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0), child: _isBooking ? const CircularProgressIndicator(color: Colors.white) : const Text("Schedule Clinical Session", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
    );
  }

  Future<void> _bookAppointment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to schedule a session.'), backgroundColor: Colors.orangeAccent)
      );
      return;
    }

    final selDate = calendarData.where((c) => c.isSelected).firstOrNull;
    final selTime = timeData.where((t) => t.isSelected).firstOrNull;
    
    if (selDate == null || selTime == null) return;

    setState(() => _isBooking = true);
    
    try {
      // Standardize data for Firestore
      final appointmentData = {
        'doctorName': widget.doctorModel.name,
        'doctorId': widget.doctorModel.name.hashCode.toString(), // Mock ID for demo
        'specialty': widget.doctorModel.specialties.first,
        'doctorImage': widget.doctorModel.image,
        'date': '${selDate.dayName}, ${selDate.dayNumber}',
        'time': selTime.time,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _firestoreService.bookAppointment(user.uid, appointmentData).timeout(const Duration(seconds: 10));

      if (mounted) {
        // Authentic Pacing: Let the user feel the "Success"
        await Future.delayed(const Duration(milliseconds: 500));
        
        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            content: Text('Hooray! Your session with Dr. ${widget.doctorModel.name} is confirmed for ${selDate.dayName} at ${selTime.time}.', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            backgroundColor: Colors.green,
            actions: [
              TextButton(
                onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                child: const Text('DISMISS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        );
        
        // Hide banner after 3 seconds
        Timer(const Duration(seconds: 4), () {
          if (mounted) ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        });

        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Booking Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('We couldn\'t secure that slot: ${e.toString().split(':').last.trim()}'),
            backgroundColor: Colors.redAccent,
            action: SnackBarAction(label: "RETRY", textColor: Colors.white, onPressed: _bookAppointment),
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

}