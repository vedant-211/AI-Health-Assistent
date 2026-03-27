import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/diagnosis_response.dart';
import '../services/firestore_service.dart';
import '../models/diagnosis_record.dart';

import 'local_storage_service.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService(ref);
});

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
    List<Map<String, String>>? history,
    List<String>? clinicalNotes,
    this.userName = "Vedant",
    required this.userId,
  })  : history = history ?? [],
        clinicalNotes = clinicalNotes ?? [];
}

class AIService {
  final FirestoreService firestoreService = FirestoreService();
  final Ref ref;

  final String _apiKey;
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _model = 'openrouter/free';

  AIService(this.ref) : _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  Future<String> _callOpenRouter(List<Map<String, String>> messages, {bool jsonMode = false}) async {
    if (_apiKey.isEmpty) throw StateError('GEMINI_API_KEY missing');

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://swasthmitra.ai', 
          'X-Title': 'SwasthMitra AI',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          if (jsonMode) 'response_format': {'type': 'json_object'},
          'temperature': 0.5,
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        debugPrint('OpenRouter API Error (${response.statusCode}): ${response.body}');
        return "";
      }

      final data = jsonDecode(response.body);
      if (data['choices'] != null && data['choices'].isNotEmpty) {
        return data['choices'][0]['message']['content'] ?? "";
      }
      return "";
    } catch (e) {
      debugPrint('OpenRouter/Network Error: $e');
      return "";
    }
  }

  static String _sanitizeText(String? input, {int maxLen = 6000}) {
    if (input == null) return '';
    var s = input.trim();
    s = s.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    if (s.length > maxLen) {
      s = s.substring(0, maxLen);
    }
    return s;
  }





  Future<void> _persistChatMessages(String userId, String userText, String botText) async {
    try {
      await firestoreService.saveChatMessage(userId, 'user', userText).timeout(const Duration(seconds: 4));
      await firestoreService.saveChatMessage(userId, 'bot', botText).timeout(const Duration(seconds: 4));
    } catch (e) {
      if (e is! TimeoutException) {
        debugPrint('Chat persistence (non-blocking): $e');
      }
    }
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
    String? familyMemberId,
    String? familyMemberName,
  }) async {
    try {
      if (_apiKey.isEmpty) return _getFallbackDiagnosis(userName);
      final historyRecords = await firestoreService.getUserDiagnoses(userId);
      final historySummary = historyRecords.take(3).map((r) => "- ${r.condition} (${r.severity}) on ${r.timestamp.toString().split(' ').first}").join('\n');
      final prompt = '''
You are "SwasthMitra", a professional health companion. Reply using ONLY valid JSON matching the provided schema.
TONE: Professional, calm, and caring.
CONTEXT:
- USER: ${_sanitizeText(userName, maxLen: 80)} (Age: $age, Gender: ${_sanitizeText(gender, maxLen: 40)})
- SYMPTOMS: ${_sanitizeText(symptoms.join(', '), maxLen: 2000)}
- PAST: ${_sanitizeText(historySummary, maxLen: 1500)}
''';
      final messages = [
        {'role': 'system', 'content': 'You are a professional health companion. Respond ONLY in valid JSON matching clinical standards.'},
        {'role': 'user', 'content': prompt},
      ];
      final res = await _callOpenRouter(messages, jsonMode: true);
      DiagnosisResponse diagnosis = res.isNotEmpty ? _parseResponse(res, userName) : _getFallbackDiagnosis(userName);
      await LocalStorageService().cacheLastDiagnosis(userId, diagnosis.toCacheMap());
      unawaited(firestoreService.saveDiagnosis(DiagnosisRecord(id: '', userId: userId, condition: diagnosis.condition, severity: diagnosis.severity, description: diagnosis.description, recommendations: diagnosis.recommendations, timestamp: DateTime.now(), symptoms: symptoms,)).timeout(const Duration(seconds: 10)).catchError((e) {
        if (e is! TimeoutException) debugPrint('Failed to save diagnosis: $e');
      }));
      return diagnosis;
    } catch (e) {
      debugPrint('AI Service Error (analyzeSymptoms): $e');
      final cached = LocalStorageService().getLastDiagnosis(userId);
      if (cached != null) {
        final restored = DiagnosisResponse.fromCacheMap(cached);
        if (restored != null) return restored;
      }
      return _getFallbackDiagnosis(userName);
    }
  }

  Future<String> chatWithBuddy({
    required String userQuery,
    required CompanionSession session,
  }) async {
    final query = _sanitizeText(userQuery, maxLen: 3000);
    
    // STEP 3: Instant Local Response Layer (Zero Latency)
    final trivialLower = query.toLowerCase().trim();
    if (trivialLower == 'hi' || trivialLower == 'hello' || trivialLower == 'hey' || trivialLower == 'hi swasthmitra') {
      final reply = "Hi 😊 I'm here with you, ${session.userName}. How are you feeling today?";
      unawaited(_persistChatMessages(session.userId, query, reply));
      return reply;
    }

    if (query.isEmpty) {
      return "I'm right here. What's on your mind?";
    }

    if (_apiKey.isEmpty) {
      return "I'm here for you, but I'm having trouble connecting to my full intelligence right now. Let's try once more.";
    }



    const systemPrompt = '''
ROLE: SwasthMitra Companion AI. You are a highly professional, emotionally intelligent, and helpful health assistant.
TONE: Warm, professional, supportive.
GUIDELINES:
- Respond intelligently to ANY user input (greetings, casual talk, emotional support, general knowledge, or health queries).
- NEVER ignore a valid message.
- Be concise (under 100 words).
- If the user is stressed, provide comforting, therapeutic support.
- If medical, remain professional and encourage clinical care when appropriate.
''';

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...session.history.map((m) => {
        'role': m['role'] == 'bot' ? 'assistant' : 'user',
        'content': (m['message'] ?? '').toString(),
      }),
      {'role': 'user', 'content': query},
    ];

    try {
      final botResponse = await _callOpenRouter(messages);
      if (botResponse.isNotEmpty) {
        unawaited(_persistChatMessages(session.userId, query, botResponse));
        return botResponse;
      }
    } catch (e) {
      debugPrint('OpenRouter Buddy Chat Error: $e');
    }

    // Step 4/7: Global Fallback Response
    return "I'm here with you 💛 I'm having a small connection issue, but I'm listening. Please tell me more.";
  }

  Future<List<String>> getSmartFollowUps({required CompanionSession session}) async {
    if (_apiKey.isEmpty) {
      return const ['How are you feeling now?', 'Want help with next steps?', 'Anything else on your mind?'];
    }
    final prompt =
        'Generate exactly 3 short follow-up questions for ${_sanitizeText(session.userName, maxLen: 80)} about "${_sanitizeText(session.diagnosis, maxLen: 200)}". '
        'Format: question1|question2|question3. No numbering.';
    
    final messages = [
      {'role': 'system', 'content': 'You are a helpful assistant. Reply only with the questions formatted as requested.'},
      {'role': 'user', 'content': prompt},
    ];

    try {
      final text = await _callOpenRouter(messages);
      return text
          .split('|')
          .map((e) => _sanitizeText(e, maxLen: 200))
          .where((e) => e.isNotEmpty)
          .take(3)
          .toList();
    } catch (e) {
      debugPrint('getSmartFollowUps: $e');
      return const ['How can I help further?', 'Any other concerns?', 'Tell me more.'];
    }
  }

  DiagnosisResponse _getFallbackDiagnosis(String userName) {
    final n = _sanitizeText(userName, maxLen: 80);
    return DiagnosisResponse(
      condition: 'Wellness check',
      severity: 'mild',
      description:
          "I'm carefully reviewing what you shared, ${n.isEmpty ? 'friend' : n}. In the meantime, rest, hydrate, and monitor how your symptoms change. If anything worsens quickly, please seek urgent in-person care.",
      recommendations: const [
        'Rest and hydrate',
        'Monitor symptoms closely',
        'Consult a clinician if symptoms persist or worsen',
      ],
      urgency: 'low',
      shouldConsultDoctor: true,
      isEmergency: false,
      clinical_notes: const [],
    );
  }

  String _extractJsonObject(String text) {
    try {
      var cleanText = text.trim();
      cleanText = cleanText.replaceAll(RegExp(r'```json\s*'), '').replaceAll(RegExp(r'```\s*'), '');
      
      try {
        final bytes = utf8.encode(cleanText);
        cleanText = utf8.decode(bytes, allowMalformed: true);
      } catch (_) {}

      final start = cleanText.indexOf('{');
      final end = cleanText.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) return '';
      return cleanText.substring(start, end + 1).trim();
    } catch (e) {
      return '';
    }
  }

  DiagnosisResponse _parseResponse(String jsonString, String userName) {
    try {
      final slice = _extractJsonObject(jsonString);
      if (slice.isEmpty) {
        return _getFallbackDiagnosis(userName);
      }
      final decoded = jsonDecode(slice);
      if (decoded is! Map) {
        return _getFallbackDiagnosis(userName);
      }
      final data = Map<String, dynamic>.from(decoded);
      return DiagnosisResponse.fromValidatedMap(data, userName);
    } catch (e) {
      debugPrint('JSON Parse Error: $e');
      return _getFallbackDiagnosis(userName);
    }
  }
}
