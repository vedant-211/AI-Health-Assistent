import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medical/services/ai_service.dart';
import '../models/diagnosis_response.dart';
import '../theme/app_styles.dart';
import 'nearby_doctors.dart';
import 'package:lottie/lottie.dart';
import '../models/message.dart';
import '../services/connectivity_service.dart';

class AIDiagnosisPage extends ConsumerStatefulWidget {
  final List<String> symptoms;
  final int age;
  final String gender;
  final String additionalInfo;
  final Map<String, String> symptomSeverity;
  final String userId;
  final String? imageUrl;
  final String? familyMemberId;
  final String? familyMemberName;

  const AIDiagnosisPage({
    super.key,
    required this.symptoms,
    required this.age,
    required this.gender,
    required this.additionalInfo,
    required this.symptomSeverity,
    required this.userId,
    this.imageUrl,
    this.familyMemberId,
    this.familyMemberName,
  });

  @override
  ConsumerState<AIDiagnosisPage> createState() => _AIDiagnosisPageState();
}

class _AIDiagnosisPageState extends ConsumerState<AIDiagnosisPage> with TickerProviderStateMixin {
  late Future<DiagnosisResponse> diagnosisFuture;
  late final AIService aiService;
  late AnimationController _loadingController;
  final PageController _pageController = PageController();
  
  String _displayedAssessment = "";
  final List<String> _thinkingSteps = ["Listening with care...", "Reflecting on your symptoms...", "Finding the right words to help..."];
  int _stepIndex = 0;
  int _currentPage = 0;
  
  Timer? _stepTimer;
  Timer? _typewriterTimer;
  bool _isDataReady = false;
  DiagnosisResponse? _diagnosis;
  bool _assessmentRevealScheduled = false;

  @override
  void initState() {
    super.initState();
    aiService = ref.read(aiServiceProvider);
    _loadingController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _startThinkingAnimation();
    
    final currentUser = FirebaseAuth.instance.currentUser;
    final actualUserName = widget.familyMemberName ?? currentUser?.displayName ?? "Guest";

    diagnosisFuture = aiService.analyzeSymptoms(
      symptoms: widget.symptoms,
      severity: widget.symptomSeverity,
      age: widget.age,
      gender: widget.gender,
      additionalInfo: widget.additionalInfo,
      userId: widget.userId,
      imageUrl: widget.imageUrl,
      familyMemberId: widget.familyMemberId,
      familyMemberName: widget.familyMemberName,
      userName: actualUserName,
    );
  }


  void _startThinkingAnimation() {
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (_stepIndex < _thinkingSteps.length - 1) {
        setState(() => _stepIndex++);
      } else { timer.cancel(); }
    });
  }

  void _startStoryReveal(String text) {
    _typewriterTimer?.cancel();
    _isDataReady = false;
    _displayedAssessment = '';
    if (text.isEmpty) {
      setState(() => _isDataReady = true);
      return;
    }
    final chars = text.characters.toList();
    var i = 0;
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 12), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (i < chars.length) {
        setState(() => _displayedAssessment += chars[i]);
        i++;
      } else {
        timer.cancel();
        setState(() => _isDataReady = true);
      }
    });
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _pageController.dispose();
    if (_stepTimer != null && _stepTimer!.isActive) _stepTimer!.cancel();
    if (_typewriterTimer != null && _typewriterTimer!.isActive) _typewriterTimer!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgDark,
      appBar: AppBar(
        backgroundColor: AppStyles.bgDark, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: AppStyles.textMain), onPressed: () => Navigator.pop(context)),
        title: _buildStepIndicator(), centerTitle: true,
      ),
      body: FutureBuilder<DiagnosisResponse>(
        future: diagnosisFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return _buildThinkingOverlay();
          if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
          if (snapshot.hasData) {
            final data = snapshot.data!;
            _diagnosis = data;
            if (!_assessmentRevealScheduled) {
              _assessmentRevealScheduled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _startStoryReveal(data.description);
              });
            }
            return _buildNarrativeFlow(data);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStepIndicator() {
    if (_diagnosis == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 12, height: 2,
        decoration: BoxDecoration(color: _currentPage == i ? AppStyles.primaryBlue : AppStyles.textSecondary.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
      )),
    );
  }

  Widget _buildThinkingOverlay() {
    return Container(width: double.infinity, color: AppStyles.bgDark, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Lottie.asset('assets/lottie/companion_breathe.json', width: 150, height: 150, fit: BoxFit.contain, errorBuilder: (c, e, s) => ScaleTransition(scale: Tween(begin: 1.0, end: 1.1).animate(_loadingController), child: const Icon(Icons.auto_awesome_rounded, color: AppStyles.primaryBlue, size: 40))), 
      const SizedBox(height: 32), 
      Text(_thinkingSteps[_stepIndex], style: const TextStyle(color: AppStyles.textMain, fontSize: 13, fontWeight: FontWeight.w700))
    ])));
  }

  Widget _buildNarrativeFlow(DiagnosisResponse diagnosis) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: 3,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.5)).clamp(0.0, 1.0);
                  }
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 100),
                      child: _buildNarrativePage(index, diagnosis),
                    ),
                  );
                },
              );
            },
          ),
        ),
        _buildBottomActions(diagnosis),
      ],
    );
  }

  Widget _buildNarrativePage(int index, DiagnosisResponse diagnosis) {
    if (index == 0) return _buildPage(0, "A Gentle Assessment", _chapterCard(diagnosis.condition, _displayedAssessment, isPrimary: true));
    if (index == 1) {
      return _buildPage(1, "What This Means", Column(children: [
        _chapterCard(null, "Based on what you've shared, this seems to be ${diagnosis.severity} in nature. I sense this might be a ${diagnosis.emotionalAnalysis ?? 'new'} experience for you, and I am right here to help you navigate it.", isEmoji: true),
        if (diagnosis.emotionalAnalysis != null && diagnosis.emotionalAnalysis!.trim().isNotEmpty) ...[
          const SizedBox(height: 20),
          _emotionalOverlay(diagnosis.emotionalAnalysis!.trim()),
        ],
      ]));
    }
    return _buildPage(2, "The Path Forward", Column(children: [
       ...diagnosis.recommendations.map((r) => _recommendationItem(r)).toList(),
       if (diagnosis.suggestedSpecialty != null) ...[
         const SizedBox(height: 24),
         _specialistPrompt(diagnosis.suggestedSpecialty!),
       ]
    ]));
  }

  Widget _emotionalOverlay(String text) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppStyles.primaryBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(28), border: Border.all(color: AppStyles.primaryBlue.withOpacity(0.1))),
      child: Row(
        children: [
          const Icon(Icons.psychology_outlined, color: AppStyles.primaryBlue, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text("Sensed State: $text", style: const TextStyle(color: AppStyles.textSecondary, fontSize: 13, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic))),
        ],
      ),
    );
  }

  Widget _specialistPrompt(String specialty) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppStyles.bgSurface, borderRadius: BorderRadius.circular(32), border: Border.all(color: AppStyles.primaryBlue.withOpacity(0.3), width: 2)),
      child: Column(
        children: [
          const Icon(Icons.medical_services_outlined, color: AppStyles.primaryBlue, size: 32),
          const SizedBox(height: 16),
          Text("Recommend $specialty Care", style: const TextStyle(color: AppStyles.textMain, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text("I've found top-rated experts who specialize in exactly what you're experiencing.", textAlign: TextAlign.center, style: TextStyle(color: AppStyles.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NearbyDoctorsPage(initialSpecialty: specialty))), 
              style: ElevatedButton.styleFrom(backgroundColor: AppStyles.primaryBlue, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text("View Specialists", style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPage(int index, String title, Widget content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Text("0${index + 1}", style: const TextStyle(color: AppStyles.primaryBlue, fontSize: 12, fontWeight: FontWeight.w900)), const SizedBox(width: 8), Text(title.toUpperCase(), style: const TextStyle(color: AppStyles.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2))]),
          const SizedBox(height: 40),
          content,
        ],
      ),
    );
  }

  Widget _chapterCard(String? title, String body, {bool isPrimary = false, bool isEmoji = false}) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: AppStyles.bgSurface, borderRadius: BorderRadius.circular(40), border: AppStyles.glassBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPrimary && widget.imageUrl != null) ...[
            Container(
              height: 180, width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                image: DecorationImage(image: NetworkImage(widget.imageUrl!), fit: BoxFit.cover),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, spreadRadius: -5)],
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              ),
            ),
          ],
          if (isEmoji) const Text("📖", style: TextStyle(fontSize: 32)),
          if (isEmoji) const SizedBox(height: 20),
          if (title != null) ...[
             Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppStyles.textMain, letterSpacing: -1)), 
             const SizedBox(height: 12)
          ],
          Text(body, style: TextStyle(fontSize: 16, color: isPrimary ? AppStyles.textMain : AppStyles.textSecondary, height: 1.6, fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w500)),
        ],
      ),
    );
  }


  Widget _recommendationItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(24), 
      decoration: BoxDecoration(color: AppStyles.bgSurface, borderRadius: BorderRadius.circular(28), border: AppStyles.glassBorder), 
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6), decoration: const BoxDecoration(color: AppStyles.primaryBlue, shape: BoxShape.circle)),
          const SizedBox(width: 16), 
          Expanded(child: Text(text, style: const TextStyle(color: AppStyles.textMain, fontSize: 15, height: 1.4, fontWeight: FontWeight.w600)))
        ]
      )
    );
  }

  Widget _buildBottomActions(DiagnosisResponse diagnosis) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
      child: Row(
        children: [
          if (_currentPage < 2) Expanded(child: _navButton("Next Chapter", (_currentPage == 0 && !_isDataReady) ? null : () => _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut), Icons.arrow_forward_ios_rounded)),
          if (_currentPage == 2) Expanded(child: _navButton("Talk to Companion", () => _openCompanionChat(diagnosis), Icons.chat_bubble_outline_rounded, isPrimary: true)),
        ],
      ),
    );
  }

  Widget _navButton(String label, VoidCallback? onTap, IconData icon, {bool isPrimary = false}) {
    return SizedBox(height: 64, child: ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(backgroundColor: isPrimary ? AppStyles.primaryBlue : AppStyles.bgSurface, foregroundColor: isPrimary ? Colors.white : AppStyles.textMain, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 24), disabledBackgroundColor: AppStyles.bgSurface.withOpacity(0.5)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)), const SizedBox(width: 8), Icon(icon, size: 16)])));
  }

  void _openCompanionChat(DiagnosisResponse diagnosis) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => CompanionChatPage(diagnosis: diagnosis, symptoms: widget.symptoms, userId: widget.userId, familyMemberName: widget.familyMemberName)));
  }

  void _retryDiagnosis() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final actualUserName = widget.familyMemberName ?? currentUser?.displayName ?? "Guest";

    setState(() {
      _displayedAssessment = "";
      _isDataReady = false;
      _assessmentRevealScheduled = false;
      diagnosisFuture = aiService.analyzeSymptoms(
        symptoms: widget.symptoms,
        severity: widget.symptomSeverity,
        age: widget.age,
        gender: widget.gender,
        additionalInfo: widget.additionalInfo,
        userId: widget.userId,
        imageUrl: widget.imageUrl,
        familyMemberId: widget.familyMemberId,
        familyMemberName: widget.familyMemberName,
        userName: actualUserName,
      );
    });
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.orangeAccent, size: 48),
            const SizedBox(height: 24),
            const Text(
              "I'm having a little trouble formulating your health story right now.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppStyles.textMain, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              "Connection issue: ${error.split(':').last.trim()}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppStyles.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _retryDiagnosis,
              style: ElevatedButton.styleFrom(backgroundColor: AppStyles.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
              child: const Text("Try Again", style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}

class CompanionChatPage extends ConsumerStatefulWidget {
  final DiagnosisResponse diagnosis;
  final List<String> symptoms;
  final String userId;
  final String? familyMemberName;

  const CompanionChatPage({
    super.key,
    required this.diagnosis,
    required this.symptoms,
    required this.userId,
    this.familyMemberName,
  });

  @override
  ConsumerState<CompanionChatPage> createState() => _CompanionChatPageState();
}

class _CompanionChatPageState extends ConsumerState<CompanionChatPage> with TickerProviderStateMixin {
  final List<Message> _messages = List<Message>.empty(growable: true);
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AIService _aiService;
  late CompanionSession _session;
  List<String> _suggestions = [];
  bool _isTyping = false;
  bool _isListening = false;
  late AnimationController _waveController;
  final _connectivity = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _aiService = ref.read(aiServiceProvider);
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    final user = FirebaseAuth.instance.currentUser;
    final actualUserName = widget.familyMemberName ?? user?.displayName ?? "Guest";
    _session = CompanionSession(
      symptoms: widget.symptoms, 
      diagnosis: widget.diagnosis.condition, 
      userId: widget.userId,
      userName: actualUserName,
      history: [],
      clinicalNotes: widget.diagnosis.clinical_notes.toList(),
    );
    _messages.add(Message(
      text: "I'm right here with you, ${_session.userName}. I've spent some time reflecting on what you've shared, and I want to help you through this with care. How are you feeling now that we have this assessment?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
    _loadSuggestions();
  }

  void _loadSuggestions() async {
    try {
      final s = await _aiService.getSmartFollowUps(session: _session);
      if (mounted) setState(() => _suggestions = s);
    } catch (_) {
      if (mounted) setState(() => _suggestions = ["How to recover?", "What to avoid?", "Next steps?"]);
    }
  }

  void _handleSend([String? presetText]) async {
    final text = presetText ?? _controller.text.trim();
    // Step 1/6: Disable and check state
    if (text.isEmpty || _isTyping) {
      if (text.isEmpty && !_isTyping) {
        setState(() {
          _messages.add(Message(text: "I’m here to help. What’s on your mind?", isUser: false, timestamp: DateTime.now()));
        });
        _autoScroll();
      }
      return;
    }

    // Step 8: Connectivity check
    if (!_connectivity.isOnline) {
      setState(() {
        _messages.add(Message(text: "You seem offline. I'm here for you, but I might need a connection for some questions.", isUser: false, timestamp: DateTime.now()));
      });
      _autoScroll();
      return;
    }

    setState(() {
      _messages.add(Message(text: text, isUser: true, timestamp: DateTime.now()));
      _isTyping = true; // State lock
      _suggestions = [];
    });

    _controller.clear();
    _autoScroll();
    _session.history.add({"role": "user", "message": text});

    try {
      // Step 1: 12s HARD UI TIMEOUT
      final botResponse = await _aiService
          .chatWithBuddy(userQuery: text, session: _session)
          .timeout(const Duration(seconds: 60), onTimeout: () {
            debugPrint('🚨 Chat UI Hardware Timeout (60s)'); // Step 8 Logging
            return "I'm here for you. Let's try again 💛"; // Step 7: Global Fallback
          });

      if (!mounted) return;
      setState(() {
        _messages.add(Message(text: botResponse, isUser: false, timestamp: DateTime.now()));
      });
      _session.history.add({"role": "bot", "message": botResponse});
      _autoScroll();
      _loadSuggestions();
    } catch (e) {
      debugPrint('🚨 Chat Failure: $e'); // Step 8 Logging
      if (!mounted) return;
      setState(() {
        _messages.add(Message(
          text: "I'm here for you. Let's try again 💛", // Step 7: Global Fallback
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _autoScroll();
    } finally {
      // Step 1: MUST Reset loading state
      if (mounted) setState(() => _isTyping = false);
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _autoScroll() { 
    Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 600), curve: Curves.easeOut);
      }
    }); 
  }

  void _startVoiceInput() {
    setState(() => _isListening = true);
    Timer(const Duration(milliseconds: 3000), () {
      if (mounted && _isListening) {
        setState(() => _isListening = false);
        final simulatedText = "How can I manage my stress better while recovering?";
        _controller.text = simulatedText;
        _handleSend();
      }
    });
  }

  Widget _buildMagicVoiceOverlay() {
    return Container(
      color: AppStyles.bgDark.withOpacity(0.95),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 100,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(12, (index) {
                      final phase = _waveController.value * 2 * math.pi;
                      final baseHeight = math.sin(phase + (index * 0.5)).abs();
                      final noise = math.sin(phase * 3 + index).abs() * 0.3;
                      final amplitude = (baseHeight + noise).clamp(0.2, 1.0);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 4,
                        height: (12 + (amplitude * 60 * (1 - (index - 5.5).abs() / 6))).toDouble(),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppStyles.primaryBlue.withOpacity(0.3),
                              AppStyles.primaryBlue,
                              AppStyles.primaryBlue.withOpacity(0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppStyles.primaryBlue.withOpacity(0.2 * amplitude),
                              blurRadius: 12,
                            )
                          ],
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
            const Text("Listening...", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 60),
            GestureDetector(
              onTap: () => setState(() => _isListening = false),
              child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgDark,
      appBar: AppBar(
        backgroundColor: AppStyles.bgDark, elevation: 0, centerTitle: true, 
        title: const Text("Family Companion", style: TextStyle(color: AppStyles.textMain, fontWeight: FontWeight.w900, fontSize: 16)), 
        leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppStyles.textMain, size: 30), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, color: AppStyles.primaryBlue, size: 26), 
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            tooltip: 'Return to Home',
          ),
        ]
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: ListView.builder(controller: _scrollController, padding: const EdgeInsets.all(24), itemCount: _messages.length, itemBuilder: (context, i) => _buildMessageBubble(_messages[i]))),
              if (_isTyping) Padding(padding: const EdgeInsets.only(left: 24, bottom: 20), child: Align(alignment: Alignment.centerLeft, child: Row(children: [const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppStyles.primaryBlue)), const SizedBox(width: 12), Text("Thinking carefully...", style: TextStyle(color: AppStyles.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))]))),
              if (_suggestions.isNotEmpty && !_isTyping) _buildSuggestions(),
              const SizedBox(height: 12),
              _buildChatInput(),
            ],
          ),
          if (_isListening) Positioned.fill(child: _buildMagicVoiceOverlay()),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      height: 44, margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => _handleSend(_suggestions[index]), 
          child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: AppStyles.bgSurface, borderRadius: BorderRadius.circular(16), border: AppStyles.glassBorder), alignment: Alignment.center, child: Text(_suggestions[index], style: const TextStyle(color: AppStyles.primaryBlue, fontSize: 12, fontWeight: FontWeight.w600)))
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message msg) {
    final isBot = !msg.isUser;
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(18),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isBot ? AppStyles.bgSurface : AppStyles.primaryBlue, 
          borderRadius: BorderRadius.circular(24).copyWith(bottomLeft: isBot ? const Radius.circular(4) : null, bottomRight: isBot ? null : const Radius.circular(4)), 
          border: isBot ? AppStyles.glassBorder : null,
          boxShadow: isBot ? [] : [BoxShadow(color: AppStyles.primaryBlue.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Text(msg.text, style: TextStyle(color: isBot ? AppStyles.textMain : Colors.white, fontSize: 14, height: 1.5, fontWeight: isBot ? FontWeight.w500 : FontWeight.w600)),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      color: AppStyles.bgDark,
      child: Row(
        children: [
          GestureDetector(
            onTap: _isTyping ? null : _startVoiceInput,
            child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: (_isTyping ? AppStyles.textSecondary : AppStyles.primaryBlue).withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.mic_rounded, color: _isTyping ? AppStyles.textSecondary : AppStyles.primaryBlue, size: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 24), decoration: BoxDecoration(color: AppStyles.bgSurface, borderRadius: BorderRadius.circular(30), border: AppStyles.glassBorder), child: TextField(controller: _controller, enabled: !_isTyping, style: const TextStyle(color: AppStyles.textMain), decoration: const InputDecoration(hintText: "Talk to me...", hintStyle: TextStyle(color: AppStyles.textSecondary, fontSize: 13), border: InputBorder.none)))),
          const SizedBox(width: 12),
          GestureDetector(
             onTap: _isTyping ? null : () => _handleSend(), 
             child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _isTyping ? AppStyles.textSecondary.withOpacity(0.3) : AppStyles.primaryBlue, shape: BoxShape.circle), child: const Icon(Icons.send_rounded, color: Colors.white, size: 20))
          ),
        ],
      ),
    );
  }
}
