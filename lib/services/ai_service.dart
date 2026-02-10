import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/symptom.dart';

class AIService {
  static const String apiKey = 'AIzaSyC6Wi65Lca7IE2raGjft14iX2DtMIFoAVE';
  late GenerativeModel model;

  AIService() {
    model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
    );
  }

  Future<DiagnosisResponse> analyzeSymptoms({
    required List<String> symptoms,
    required Map<String, String> severity,
    required int age,
    required String gender,
    String? additionalInfo,
  }) async {
    try {
      final symptomList = symptoms.join(', ');
      final prompt = '''
You are a medical AI assistant for the SwasthMitra app. Analyze the following symptoms and provide guidance.

Patient Details:
- Age: $age
- Gender: $gender
- Symptoms: $symptomList
- Severity: ${severity.entries.map((e) => '${e.key}: ${e.value}').join(', ')}
${additionalInfo != null ? '- Additional Info: $additionalInfo' : ''}

Please provide a response in the following JSON format only (no markdown or additional text):
{
  "condition": "Most likely condition(s)",
  "severity": "mild/moderate/severe",
  "description": "Detailed explanation of the condition",
  "recommendations": ["Recommendation 1", "Recommendation 2", "Recommendation 3"],
  "urgency": "low/moderate/high/emergency",
  "shouldConsultDoctor": true/false
}

IMPORTANT: 
1. Always recommend consulting a doctor for serious symptoms
2. Never provide definitive medical diagnosis
3. Suggest visiting emergency for severe symptoms
4. Keep language simple and understandable
5. Return ONLY valid JSON, no other text
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      // Parse the response
      final responseText = response.text ?? '';
      
      // Extract JSON from response
      final jsonString = _extractJson(responseText);
      
      if (jsonString.isEmpty) {
        throw Exception('Invalid response format from AI');
      }

      // Parse JSON response
      return _parseResponse(jsonString);
    } catch (e) {
      // Fallback response when API fails (e.g., quota exceeded)
      if (e.toString().contains('quota') || e.toString().contains('rate limit')) {
        return _getFallbackDiagnosis(symptoms, severity);
      }
      throw Exception('Error analyzing symptoms: $e');
    }
  }

  DiagnosisResponse _getFallbackDiagnosis(List<String> symptoms, Map<String, String> severity) {
    // Basic fallback diagnosis based on symptoms
    final symptomLower = symptoms.map((s) => s.toLowerCase()).toList();
    
    String condition = 'General Illness';
    String severityLevel = 'mild';
    String description = 'We are currently experiencing high traffic. Please try again in a moment.';
    List<String> recommendations = [
      'Rest and hydration',
      'Monitor your symptoms',
      'Contact a healthcare provider if symptoms persist'
    ];
    String urgency = 'low';
    bool shouldConsult = true;

    // Simple symptom matching for fallback
    if (symptomLower.any((s) => s.contains('fever') && s.contains('headache'))) {
      condition = 'Possible Flu or Viral Infection';
      description = 'You may be experiencing a viral infection. Rest, stay hydrated, and monitor your temperature.';
      recommendations = [
        'Get plenty of rest',
        'Stay well hydrated',
        'Use fever reducers if needed',
        'Consult a doctor if symptoms worsen'
      ];
    } else if (symptomLower.any((s) => s.contains('cough'))) {
      condition = 'Respiratory Concerns';
      description = 'You may have a respiratory issue. Monitor for any additional symptoms.';
      recommendations = [
        'Rest your voice',
        'Stay hydrated',
        'Use throat lozenges',
        'See a doctor if cough persists for more than 2 weeks'
      ];
    } else if (symptomLower.any((s) => s.contains('chest'))) {
      condition = 'Chest Discomfort';
      urgency = 'high';
      shouldConsult = true;
      description = 'Chest discomfort should be evaluated by a healthcare professional urgently.';
      recommendations = [
        'Seek immediate medical attention',
        'Do not delay treatment',
        'Call emergency services if pain is severe'
      ];
    }

    return DiagnosisResponse(
      condition: condition,
      severity: severityLevel,
      description: description,
      recommendations: recommendations,
      urgency: urgency,
      shouldConsultDoctor: shouldConsult,
    );
  }

  String _extractJson(String text) {
    try {
      final startIndex = text.indexOf('{');
      final endIndex = text.lastIndexOf('}');
      
      if (startIndex == -1 || endIndex == -1 || startIndex >= endIndex) {
        return '';
      }
      
      return text.substring(startIndex, endIndex + 1);
    } catch (e) {
      return '';
    }
  }

  DiagnosisResponse _parseResponse(String jsonString) {
    // Simple JSON parsing (you might want to use dart:convert for production)
    try {
      // Use simple string parsing since google_generative_ai doesn't include jsonDecode
      final condition = _extractJsonValue(jsonString, 'condition');
      final severity = _extractJsonValue(jsonString, 'severity');
      final description = _extractJsonValue(jsonString, 'description');
      final urgency = _extractJsonValue(jsonString, 'urgency');
      final shouldConsultDoctor = _extractJsonBool(jsonString, 'shouldConsultDoctor');
      final recommendationsStr = _extractJsonArray(jsonString, 'recommendations');

      return DiagnosisResponse(
        condition: condition,
        severity: severity,
        description: description,
        recommendations: recommendationsStr,
        urgency: urgency,
        shouldConsultDoctor: shouldConsultDoctor,
      );
    } catch (e) {
      throw Exception('Error parsing AI response: $e');
    }
  }

  String _extractJsonValue(String json, String key) {
    try {
      final pattern = RegExp('"$key"\\s*:\\s*"([^"]*)"');
      final match = pattern.firstMatch(json);
      return match?.group(1) ?? '';
    } catch (e) {
      return '';
    }
  }

  bool _extractJsonBool(String json, String key) {
    try {
      final pattern = RegExp('"$key"\\s*:\\s*(true|false)');
      final match = pattern.firstMatch(json);
      return match?.group(1) == 'true';
    } catch (e) {
      return false;
    }
  }

  List<String> _extractJsonArray(String json, String key) {
    try {
      final pattern = RegExp('"$key"\\s*:\\s*\\[([^\\]]*)\\]');
      final match = pattern.firstMatch(json);
      if (match == null) return [];
      
      final arrayContent = match.group(1) ?? '';
      final items = arrayContent.split(',');
      
      return items
          .map((item) => item.trim().replaceAll('"', '').replaceAll('\\/', '/'))
          .where((item) => item.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }
}
