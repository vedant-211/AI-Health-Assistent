import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:medical/models/symptom.dart';
import 'ai_diagnosis.dart';
import '../theme/app_styles.dart';

class AISymptomsPage extends StatefulWidget {
  const AISymptomsPage({super.key});

  @override
  State<AISymptomsPage> createState() => _AISymptomsPageState();
}

class _AISymptomsPageState extends State<AISymptomsPage> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  List<SymptomModel> symptoms = SymptomModel.getCommonSymptoms();
  int selectedAge = 25;
  String selectedGender = 'Male';
  TextEditingController additionalInfoController = TextEditingController();
  Map<String, String> symptomSeverity = {};

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isListening = false;
  
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _waveController.dispose();
    additionalInfoController.dispose();
    super.dispose();
  }

  void _nextStep() { if (_currentStep < 2) _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut); }
  void _prevStep() { if (_currentStep > 0) _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut); }

  Future<String?> _uploadImage(String userId) async {
    if (_selectedImage == null) return null;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('symptom_images')
          .child(userId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await ref.putFile(_selectedImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Storage Error: $e');
      return null;
    }
  }

  Future<void> _handleAnalyze() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to proceed with the health review.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final selectedNames = symptoms.where((s) => s.isSelected).map((s) => s.name).toList();
    
    try { 
      // Image upload with fallback & timeout
      String? imageUrl;
      if (_selectedImage != null) {
        try {
          imageUrl = await _uploadImage(user.uid).timeout(const Duration(seconds: 30));
        } catch (e) {
          debugPrint('Image upload timed out/failed, proceeding: $e');
        }
      }

      // Record the report for history/audit (Non-blocking for better UX)
      FirebaseFirestore.instance.collection('symptom_reports').add({
        'userId': user.uid,
        'age': selectedAge, 
        'gender': selectedGender, 
        'symptoms': selectedNames, 
        'additionalInfo': additionalInfoController.text, 
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp()
      }).timeout(const Duration(seconds: 15)).catchError((e) {
        debugPrint('Audit report failed (non-blocking): $e');
        return null; // Return null to complete the future
      });

      if (mounted) { 
        setState(() => _isLoading = false); 
        Navigator.push(context, MaterialPageRoute(builder: (context) => AIDiagnosisPage(
          symptoms: selectedNames, 
          age: selectedAge, 
          gender: selectedGender, 
          additionalInfo: additionalInfoController.text, 
          symptomSeverity: symptomSeverity,
          userId: user.uid,
          imageUrl: imageUrl,
        ))); 
      }
    } catch (e) { 
      debugPrint('Error during analysis: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMsg = e is TimeoutException ? "Connection is taking longer than expected. Please check your signal." : 'Could not start analysis: ${e.toString().split(':').last.trim()}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
            action: SnackBarAction(label: "RETRY", textColor: Colors.white, onPressed: _handleAnalyze),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgDark,
      appBar: AppBar(
        backgroundColor: AppStyles.bgDark, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppStyles.textMain, size: 20), onPressed: _currentStep == 0 ? () => Navigator.pop(context) : _prevStep),
        title: _buildProgressIndicator(),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentStep = i),
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStep1(),
              _buildStep2(),
              _buildStep3(),
            ],
          ),
          if (_isListening) _buildMagicVoiceOverlay(),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppStyles.primaryBlue),
            SizedBox(height: 24),
            Text("Preparing Clinical Review...", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(color: AppStyles.bgSurface, borderRadius: BorderRadius.circular(20), border: AppStyles.glassBorder),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentStep == index ? 20 : 6, height: 6,
          decoration: BoxDecoration(color: _currentStep == index ? AppStyles.primaryBlue : AppStyles.textSecondary.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
        )),
      ),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("1. Personal Details", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppStyles.textMain, letterSpacing: -1)),
          const SizedBox(height: 8),
          const Text("Helps me understand you better as a companion.", style: TextStyle(color: AppStyles.textSecondary, fontSize: 13)),
          const SizedBox(height: 48),
          _sectionHeader("How old are you?", "Your age helps identify pattern risks"),
          const SizedBox(height: 24),
          _buildAgeSlider(),
          const SizedBox(height: 48),
          _sectionHeader("Gender identity", "Crucial for specific biological markers"),
          const SizedBox(height: 24),
          _buildGenderSelector(),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("2. Physical Feelings", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppStyles.textMain, letterSpacing: -1)),
          const SizedBox(height: 8),
          const Text("Select what you're noticing lately.", style: TextStyle(color: AppStyles.textSecondary, fontSize: 13)),
          const SizedBox(height: 40),
          Expanded(child: SingleChildScrollView(child: _buildSymptomsGrid())),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("3. Deeper Context", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppStyles.textMain, letterSpacing: -1)),
          const SizedBox(height: 8),
          const Text("Tell me more, just like talking to a family doctor.", style: TextStyle(color: AppStyles.textSecondary, fontSize: 13)),
          const SizedBox(height: 40),
          _sectionHeader("Describe with voice or text", "The more detail, the better I can assist"),
          const SizedBox(height: 20),
          _buildInfoInput(),
          const SizedBox(height: 40),
          _sectionHeader("Add a visual hint", "Optional photo for physical context"),
          const SizedBox(height: 20),
          _buildPhotoSection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final hasSymptoms = symptoms.any((s) => s.isSelected);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Row(
        children: [
          if (_currentStep == 0) Expanded(child: _primaryButton("Get Started", _nextStep, Icons.arrow_forward_rounded)),
          if (_currentStep == 1) ...[
            Expanded(child: _primaryButton("Continue", _nextStep, Icons.arrow_forward_rounded, isEnabled: hasSymptoms)),
          ],
          if (_currentStep == 2) Expanded(child: _primaryButton("Check My Health", _handleAnalyze, Icons.auto_awesome_rounded)),
        ],
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onTap, IconData icon, {bool isEnabled = true, bool isLoading = false}) {
    return SizedBox(
      height: 64,
      child: ElevatedButton(
        onPressed: (isEnabled && !isLoading) ? onTap : null,
        style: ElevatedButton.styleFrom(backgroundColor: AppStyles.primaryBlue, disabledBackgroundColor: AppStyles.primaryBlue.withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), elevation: 0),
        child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5)), const SizedBox(width: 8), Icon(icon, color: Colors.white, size: 20)]),
      ),
    );
  }

  // --- Components ---

  Widget _sectionHeader(String title, String subtitle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppStyles.textMain)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 12, color: AppStyles.textSecondary, fontWeight: FontWeight.w500))]);
  }

  Widget _buildAgeSlider() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppStyles.bgSurface, borderRadius: BorderRadius.circular(28), border: AppStyles.glassBorder),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Age", style: TextStyle(color: AppStyles.textMain, fontWeight: FontWeight.w800)), Text("$selectedAge years", style: const TextStyle(color: AppStyles.primaryBlue, fontWeight: FontWeight.w900, fontSize: 18))]),
          const SizedBox(height: 12),
          SliderTheme(data: SliderTheme.of(context).copyWith(activeTrackColor: AppStyles.primaryBlue, inactiveTrackColor: AppStyles.bgWhite, thumbColor: AppStyles.primaryBlue, overlayColor: AppStyles.primaryBlue.withOpacity(0.2), trackHeight: 4), child: Slider(value: selectedAge.toDouble(), min: 1, max: 100, onChanged: (v) => setState(() => selectedAge = v.toInt()))),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(children: ['Male', 'Female', 'Other'].map((g) {
      final isSelected = selectedGender == g;
      return Expanded(child: GestureDetector(onTap: () => setState(() => selectedGender = g), child: AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 20), decoration: BoxDecoration(color: isSelected ? AppStyles.primaryBlue : AppStyles.bgSurface, borderRadius: BorderRadius.circular(24), border: AppStyles.glassBorder), alignment: Alignment.center, child: Text(g, style: TextStyle(color: isSelected ? Colors.white : AppStyles.textSecondary, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, fontSize: 14)))));
    }).toList());
  }

  Widget _buildSymptomsGrid() {
    return Wrap(
      spacing: 10, runSpacing: 10,
      children: symptoms.map((s) {
        final isSelected = s.isSelected;
        return GestureDetector(
          onTap: () => setState(() { s.isSelected = !s.isSelected; if (isSelected) symptomSeverity.remove(s.name); else symptomSeverity[s.name] = 'moderate'; }),
          child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), decoration: BoxDecoration(color: isSelected ? AppStyles.primaryBlue : AppStyles.bgSurface, borderRadius: BorderRadius.circular(20), border: AppStyles.glassBorder), child: Text(s.name, style: TextStyle(color: isSelected ? Colors.white : AppStyles.textSecondary, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, fontSize: 13))),
        );
      }).toList(),
    );
  }

  Widget _buildInfoInput() {
    return Container(
      decoration: BoxDecoration(color: AppStyles.bgSurface, borderRadius: BorderRadius.circular(28), border: AppStyles.glassBorder),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(controller: additionalInfoController, maxLines: 5, style: const TextStyle(color: AppStyles.textMain, fontSize: 14), decoration: const InputDecoration(hintText: "How have you been feeling lately?", hintStyle: TextStyle(color: AppStyles.textSecondary, fontSize: 13), border: InputBorder.none)),
          const Divider(color: AppStyles.bgWhite, height: 32),
          GestureDetector(onTap: _startVoiceInput, child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), decoration: BoxDecoration(color: AppStyles.primaryBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(16)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.mic_rounded, color: AppStyles.primaryBlue, size: 20), SizedBox(width: 8), Text("Voice input", style: TextStyle(color: AppStyles.primaryBlue, fontWeight: FontWeight.w800, fontSize: 12))]))),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: () => _pickImage(ImageSource.gallery),
      child: Container(width: double.infinity, height: 160, decoration: BoxDecoration(color: AppStyles.bgSurface, borderRadius: BorderRadius.circular(28), border: AppStyles.glassBorder), child: _selectedImage != null ? ClipRRect(borderRadius: BorderRadius.circular(28), child: Image.file(_selectedImage!, fit: BoxFit.cover)) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.add_photo_alternate_rounded, color: AppStyles.textSecondary, size: 32), const SizedBox(height: 8), Text("Camera context", style: TextStyle(color: AppStyles.textSecondary.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600))])),
    );
  }

  Widget _buildMagicVoiceOverlay() {
    return Container(
      color: AppStyles.bgDark.withOpacity(0.95),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 120,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(16, (index) {
                      // Physics-based wave simulation
                      final phase = _waveController.value * 2 * math.pi;
                      final baseHeight = math.sin(phase + (index * 0.4)).abs();
                      // Random-ish "Audio Activity" jitter
                      final noise = math.sin(phase * 2.5 + index).abs() * 0.4;
                      final amplitude = (baseHeight + noise).clamp(0.2, 1.0);
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 5,
                        height: 15 + (amplitude * 75 * (1 - (index - 7.5).abs() / 8)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppStyles.primaryBlue.withOpacity(0.3 + (noise * 0.2)),
                              AppStyles.primaryBlue,
                              AppStyles.primaryBlue.withOpacity(0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppStyles.primaryBlue.withOpacity(0.3 * amplitude),
                              blurRadius: 15,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 60),
            ShaderMask(
              shaderCallback: (bounds) => AppStyles.auraBlue.createShader(bounds),
              child: const Text(
                "Listening Deeply...",
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.5),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return Text(
                  _isListening ? "I'm sensing your health story..." : "Speak naturally about how you feel",
                  style: TextStyle(color: AppStyles.textSecondary.withOpacity(0.8 + 0.2 * math.sin(_waveController.value * math.pi)), fontSize: 15, fontWeight: FontWeight.w500),
                );
              },
            ),
            const SizedBox(height: 80),
            GestureDetector(
              onTap: () => setState(() => _isListening = false),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _startVoiceInput() {
    setState(() => _isListening = true);
    // Simulate natural processing delay and audio-to-text conversion
    Timer(const Duration(milliseconds: 2800), () {
      if (mounted && _isListening) {
        setState(() => _isListening = false);
        _typewriterTranscription("I've been feeling a bit low on energy lately, and there's a recurring discomfort in my upper back, especially after long hours of sitting at my desk. It's making me a bit anxious.");
      }
    });
  }

  void _typewriterTranscription(String text) async {
    additionalInfoController.text = "";
    for (int i = 0; i < text.length; i++) {
       await Future.delayed(const Duration(milliseconds: 25));
       if (mounted) {
         setState(() {
           additionalInfoController.text += text[i];
           // Scroll to end if needed (handled by TextField defaults usually)
         });
       }
    }
  }


  Future<void> _pickImage(ImageSource source) async { final pickedFile = await _picker.pickImage(source: source); if (pickedFile != null) setState(() => _selectedImage = File(pickedFile.path)); }
}

