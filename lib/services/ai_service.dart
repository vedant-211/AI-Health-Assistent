import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/diagnosis_response.dart';
import '../services/firestore_service.dart';
import '../models/diagnosis_record.dart';

class CompanionSession {
  final List<String> symptoms;
  final String diagnosis;
  final List<Map<String, String>> history; 
  final List<String> clinicalNotes; 
  String userName;
  final String userId;

  CompanionSession({
    required this.symptoms,
    required this.diagnosis,
    this.history = const [],
    this.clinicalNotes = const [],
    this.userName = "Vedant",
    required this.userId,
  });
}

class AIService {
  late GenerativeModel model;
  final FirestoreService firestoreService = FirestoreService();

  AIService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in environment variables. Please check your .env file.');
    }
    model = GenerativeModel(
      model: 'gemini-2.0-flash', 
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1, 
        topP: 0.95,
        topK: 40,
      ),
    );
  }

  Future<GenerateContentResponse> _retryWithBackoff(Future<GenerateContentResponse> Function() action, {int maxRetries = 2}) async {
    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        return await action();
      } catch (e) {
        retryCount++;
        debugPrint('🔄 Retrying AI action (Attempt $retryCount/$maxRetries)... $e');
        if (retryCount >= maxRetries) rethrow;
        await Future.delayed(Duration(seconds: 2 * retryCount));
      }
    }
    return action();
  }

  Future<DiagnosisResponse> analyzeSymptoms({
    required List<String> symptoms,
    required Map<String, String> severity,
    required int age,
    required String gender,
    required String userId,
    String? additionalInfo,
    String? imageUrl,
    String userName = "Vedant",
  }) async {
    try {
      final historyRecords = await firestoreService.getUserDiagnoses(userId);
      final historySummary = historyRecords.take(3).map((r) {
        return "- ${r.condition} (${r.severity}) on ${r.timestamp.toString().split(' ').first}";
      }).join("\n");
      
      final symptomList = symptoms.join(', ');
      
      final prompt = '''
      SYSTEM: You are "SwasthMitra", your personal health companion. You act as a compassionate, expert healthcare partner who speaks like a warm therapist.
      
      TONE & STYLE:
      - Use simple, everyday language. Avoid medical jargon entirely.
      - Speak with deep compassion and empathy (e.g., "I hear you," "I understand this might feel stressful").
      - Be reassuring but clinically honest.
      - Act as a supportive therapeutic guide who explains things in human terms.
      
      ADAPTIVE VOICES:
      - "Steadfast Guardian": Calm and focused for urgent needs.
      - "Compassionate Peer": Gentle and relatable for mild concerns.
      - "Supportive Mentor": Educational and encouraging.

      CONTEXT:
      - USER: $userName (Age: $age, Gender: $gender)
      - SYMPTOMS: $symptomList
      - ADDITIONAL CONTEXT: ${additionalInfo ?? "None provided"}
      - PAST HISTORY: $historySummary

      STRICT JSON SCHEMA:
      {
        "condition": "Simple, non-scary name for the condition",
        "severity": "mild" | "moderate" | "severe",
        "emotional_analysis": "How the user seems to be feeling (Short)",
        "persona_reflection": "Why you chose this specific tone for $userName",
        "description": "3 sentences maximum. Use extreme compassion, simple terms, and a therapist-like warmth.",
        "recommendations": ["Simple action 1", "Simple action 2", "Simple action 3"],
        "urgency": "low" | "moderate" | "high" | "emergency",
        "suggested_specialty": "Medical specialty",
        "shouldConsultDoctor": boolean,
        "isEmergency": boolean,
        "clinical_notes": ["1 key summary for historical context"]
      }
      ''';

      final response = await _retryWithBackoff(() => model.generateContent([Content.text(prompt)]));
      final jsonString = _extractJson(response.text ?? '');
      
      if (jsonString.isEmpty) return _getFallbackDiagnosis(userName);
      
      final diagnosis = _parseResponse(jsonString, userName);
      
      await firestoreService.saveDiagnosis(DiagnosisRecord(
        id: "",
        userId: userId,
        condition: diagnosis.condition,
        severity: diagnosis.severity,
        description: diagnosis.description,
        recommendations: diagnosis.recommendations,
        timestamp: DateTime.now(),
        symptoms: symptoms,
        imageUrl: imageUrl,
      )).timeout(const Duration(seconds: 10)).catchError((e) {
        debugPrint('Failed to save diagnosis record (non-blocking): $e');
      });

      try {
        final profile = await firestoreService.getUserProfile(userId).timeout(const Duration(seconds: 5));
        if (profile != null) {
          int decrement = (diagnosis.urgency.toLowerCase() == 'low') ? 2 :
                          (diagnosis.urgency.toLowerCase() == 'moderate') ? 5 :
                          (diagnosis.urgency.toLowerCase() == 'high') ? 10 :
                          (diagnosis.urgency.toLowerCase() == 'emergency') ? 20 : 3;
          int newScore = ((profile.healthScore - decrement).clamp(0, 100) as int);
          if (newScore != profile.healthScore) {
            await firestoreService.updateUserProfile(userId, {'healthScore': newScore}).timeout(const Duration(seconds: 5));
          }
        }
      } catch (e) { debugPrint('Health score update failed/timed out: $e'); }

      return diagnosis;
    } catch (e) {
      debugPrint('AI Service Error (analyzeSymptoms): $e');
      return _getFallbackDiagnosis(userName);
    }
  }

  Future<String> chatWithBuddy({
    required String userQuery,
    required CompanionSession session,
  }) async {
    try {
      final historyContext = session.history.take(10).map((m) => "${m['role']}: ${m['message']}").join("\n");

      final prompt = '''
      ROLE: You are the "SwasthMitra Companion"—a warm, professional Clinical Companion.
      PERSONALITY: Embody a supportive medical guide. You are patient, knowledgeable, and respectful.
      CLINICAL MEMORY:
      - Current Assessment: ${session.diagnosis}
      - Key Clinical Notes: ${session.clinicalNotes.join('; ')}

      GUIDELINES:
      - Prioritize clinical safety.
      - Maintain a professional yet warm tone. Avoid informal address like "beta".
      - Use ${session.userName}'s name with respect.
      
      USER QUERY: "$userQuery"
      ''';

      final response = await _retryWithBackoff(() => model.generateContent([Content.text(prompt)]));
      final botResponse = response.text?.trim() ?? "I'm right here with you, ${session.userName}. I'm listening.";
      
      await firestoreService.saveChatMessage(session.userId, "user", userQuery);
      await firestoreService.saveChatMessage(session.userId, "bot", botResponse);

      return botResponse;
    } catch (e) {
      debugPrint('AI Service Error (chatWithBuddy): $e');
      return "I'm having a little trouble connecting right now, but I'm still here for you. Could you repeat that?";
    }
  }

  Future<List<String>> getSmartFollowUps({required CompanionSession session}) async {
    try {
      final prompt = "As a family doctor companion, generate 3 warm, short follow-up questions for ${session.userName} regarding their '${session.diagnosis}'. Format: question1|question2|question3. No numbers.";
      final response = await _retryWithBackoff(() => model.generateContent([Content.text(prompt)]));
      return (response.text ?? "How are you feeling now?|Need help with the steps?|Anything else on your mind?").split('|').map((e) => e.trim()).toList();
    } catch (e) {
      return ["How can I help further?", "Any other concerns?", "Tell me more."];
    }
  }

  DiagnosisResponse _getFallbackDiagnosis(String userName) {
    return DiagnosisResponse(
      condition: "Wellness Check Needed",
      severity: "mild",
      description: "I'm carefully reviewing your symptoms, $userName. It seems like a little extra care and rest might be what you need right now.",
      recommendations: ["Rest and hydrate", "Monitor symptoms closely", "Consult a professional if symptoms persist"],
      urgency: "low",
      shouldConsultDoctor: true,
      isEmergency: false,
      clinical_notes: []
    );
  }

  String _extractJson(String text) {
    try {
      final startIndex = text.indexOf('{');
      final endIndex = text.lastIndexOf('}');
      if (startIndex == -1 || endIndex == -1) return '';
      return text.substring(startIndex, endIndex + 1);
    } catch (e) { return ''; }
  }

  DiagnosisResponse _parseResponse(String jsonString, String userName) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      return DiagnosisResponse(
        condition: data['condition'] ?? 'General Concern',
        severity: data['severity'] ?? 'mild',
        description: data['description'] ?? "I'm here to support you through this, $userName.",
        recommendations: List<String>.from(data['recommendations'] ?? ["Rest and monitor", "Stay hydrated"]),
        urgency: data['urgency'] ?? 'low',
        shouldConsultDoctor: data['shouldConsultDoctor'] ?? true,
        isEmergency: data['isEmergency'] ?? false,
        clinical_notes: List<String>.from(data['clinical_notes'] ?? []),
        emotionalAnalysis: data['emotional_analysis'],
        suggestedSpecialty: data['suggested_specialty'],
      );
    } catch (e) { 
      debugPrint('JSON Parse Error: $e');
      return _getFallbackDiagnosis(userName); 
    }
  }
}
