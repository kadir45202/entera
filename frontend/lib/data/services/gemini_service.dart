import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Gemini AI Service Provider
final geminiServiceProvider = Provider<GeminiService>((ref) {
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  return GeminiService(apiKey);
});

/// Chat message model
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Content toGeminiContent() {
    return Content(role, [TextPart(content)]);
  }
}

/// Meal analysis result
class MealAnalysisResult {
  final List<Map<String, dynamic>> detectedIngredients;
  final List<Map<String, dynamic>> detectedAllergens;
  final String riskLevel;
  final String? summary;
  final String? healthPrediction;
  final String? mealCategory;
  final int? estimatedCalories;
  final bool isError;
  final String? errorMessage;

  MealAnalysisResult({
    required this.detectedIngredients,
    required this.detectedAllergens,
    required this.riskLevel,
    this.summary,
    this.healthPrediction,
    this.mealCategory,
    this.estimatedCalories,
    this.isError = false,
    this.errorMessage,
  });

  factory MealAnalysisResult.fromJson(Map<String, dynamic> json) {
    return MealAnalysisResult(
      detectedIngredients: json['detected_ingredients'] != null
          ? List<Map<String, dynamic>>.from(json['detected_ingredients'])
          : [],
      detectedAllergens: json['detected_allergens'] != null
          ? List<Map<String, dynamic>>.from(json['detected_allergens'])
          : [],
      riskLevel: json['risk_level'] ?? 'none',
      summary: json['summary'],
      healthPrediction: json['health_prediction'],
      mealCategory: json['meal_category'],
      estimatedCalories: json['estimated_calories'],
    );
  }

  factory MealAnalysisResult.error(String message) {
    return MealAnalysisResult(
      detectedIngredients: [],
      detectedAllergens: [],
      riskLevel: 'none',
      isError: true,
      errorMessage: message,
    );
  }
}

/// Correlation insight result
class CorrelationInsight {
  final String summary;
  final List<String> triggers;
  final List<String> recommendations;

  CorrelationInsight({
    required this.summary,
    required this.triggers,
    required this.recommendations,
  });
}

/// Gemini AI Service
class GeminiService {
  final String _apiKey;
  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;

  GeminiService(this._apiKey) {
    if (_apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.3,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048,
        ),
      );
      _visionModel = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.1,
          maxOutputTokens: 1024,
        ),
      );
    }
  }

  bool get isConfigured => _apiKey.isNotEmpty;

  // ==========================================
  // 1. MEAL IMAGE ANALYSIS
  // ==========================================

  Future<MealAnalysisResult> analyzeMealImage(
    Uint8List imageBytes, {
    List<String> userAllergens = const [],
    List<Map<String, dynamic>> recentBowelData = const [],
  }) async {
    // API anahtarı yoksa hata döndür
    if (!isConfigured) {
      return MealAnalysisResult.error(
          'API anahtarı yapılandırılmamış. .env dosyasını kontrol edin.');
    }

    try {
      // Build bowel health context
      String bowelContext = '';
      if (recentBowelData.isNotEmpty) {
        bowelContext = '''

🔹 KULLANICININ SON 3 GÜNLÜK BAĞIRSAK DURUMU:
${recentBowelData.map((log) => '- ${log['date']}: Bristol Tip ${log['type']} (${log['description']})').join('\n')}
''';
      }

      final prompt = '''
🍽️ YEMEK TANIMA GÖREVİ

Bu fotoğraftaki yemeği analiz et ve ne olduğunu tespit et.

📋 ANALİZ ADIMLARI:

1️⃣ ANA YEMEĞİ TESPİT ET
   - Fotoğrafta gördüğün asıl yemek nedir?
   - Türk mutfağı mı, dünya mutfağı mı?
   - Pişirme yöntemi: ızgara, kızartma, haşlama, fırın?

2️⃣ TÜM MALZEMELERİ LİSTELE
   - Sadece GÖRDÜĞÜN malzemeleri yaz
   - Tahmin etme, görsel olarak net olanları ekle
   - Her malzeme için güven skoru (0.0-1.0) ver

3️⃣ ALERJEN KONTROLÜ
   Kullanıcının hassasiyetleri: ${userAllergens.isEmpty ? 'Belirtilmemiş' : userAllergens.join(', ')}
   
   Kontrol edilecek alerjenler:
   - GLUTEN: ekmek, makarna, börek, simit, un ürünleri
   - LAKTOZ: süt, peynir, yoğurt, tereyağı
   - YUMURTA: omlet, menemen, pasta
   - FINDIK/FISTIK: kuruyemişler
   - DENİZ ÜRÜNLERİ: balık, karides
$bowelContext

⚠️ KURALLAR:
- Yemeğin GERÇEK ADINI Türkçe yaz
- Sadece gördüklerini analiz et, tahmin yapma
- Emin değilsen düşük confidence ver (0.5-0.7)

📤 SADECE JSON DÖNDÜR:
{
  "summary": "Yemeğin Türkçe adı",
  "meal_category": "breakfast|lunch|dinner|snack",
  "estimated_calories": 400,
  "detected_ingredients": [
    {"name": "Malzeme adı", "confidence": 0.9}
  ],
  "detected_allergens": [
    {"name": "Alerjen adı", "trigger_ingredient": "Hangi malzemeden", "confidence": 0.9}
  ],
  "risk_level": "none|low|medium|high",
  "health_prediction": "Bu yemeğin sindirim sistemine olası etkileri"
}
''';

      final content = Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ]);

      final response = await _visionModel.generateContent([content]);
      final text = response.text;

      if (text == null || text.isEmpty) {
        return MealAnalysisResult.error(
            'AI yanıt vermedi. Lütfen tekrar deneyin.');
      }

      // Extract JSON from response
      final jsonStr = _extractJson(text);

      if (jsonStr == '{}' || jsonStr.isEmpty) {
        return MealAnalysisResult.error(
            'AI yanıtı işlenemedi. Lütfen daha net bir fotoğraf çekin.');
      }

      final json = jsonDecode(jsonStr);

      // Validate that we have actual data
      if (json['summary'] == null && json['detected_ingredients'] == null) {
        return MealAnalysisResult.error(
            'Yemek tanınamadı. Lütfen farklı açıdan fotoğraf çekin.');
      }

      return MealAnalysisResult.fromJson(json);
    } catch (e) {
      print('Gemini meal analysis error: $e');
      return MealAnalysisResult.error(
          'Analiz hatası: ${e.toString().substring(0, 100)}');
    }
  }

  // ==========================================
  // 2. HEALTH CHATBOT
  // ==========================================

  Future<String> chat(
    String message, {
    List<ChatMessage> history = const [],
    String? userContext,
  }) async {
    if (!isConfigured) {
      return 'API anahtarı yapılandırılmamış. .env dosyasını kontrol edin.';
    }

    try {
      final systemPrompt = '''
Sen Entera uygulamasının sağlık asistanısın. Kullanıcılara bağırsak sağlığı, 
beslenme ve sindirim konularında yardımcı oluyorsun.

Kurallar:
- Türkçe yanıt ver
- Kısa ve öz ol
- Tıbbi teşhis koyma
- Ciddi semptomlar için doktora yönlendir

${userContext != null ? 'Kullanıcı bağlamı: $userContext' : ''}
''';

      final chat = _model.startChat(
        history: [
          Content.text(systemPrompt),
          ...history.map((m) => m.toGeminiContent()),
        ],
      );

      final response = await chat.sendMessage(Content.text(message));
      return response.text ?? 'Yanıt alınamadı.';
    } catch (e) {
      print('Gemini chat error: $e');
      return 'Hata: $e';
    }
  }

  // ==========================================
  // 3. CORRELATION ANALYSIS
  // ==========================================

  Future<CorrelationInsight> analyzeCorrelations({
    required List<Map<String, dynamic>> meals,
    required List<Map<String, dynamic>> symptoms,
    List<String> userAllergens = const [],
  }) async {
    if (!isConfigured) {
      return CorrelationInsight(
        summary: 'API anahtarı yapılandırılmamış.',
        triggers: [],
        recommendations: ['.env dosyasını kontrol edin.'],
      );
    }

    if (meals.isEmpty && symptoms.isEmpty) {
      return CorrelationInsight(
        summary: 'Henüz yeterli veri yok.',
        triggers: [],
        recommendations: [
          'Yemek fotoğrafı çekerek ve semptom kaydı ekleyerek başlayın.'
        ],
      );
    }

    try {
      final prompt = '''
Kullanıcının yemek ve semptom verilerini analiz et.

Yemekler (son 3 gün):
${jsonEncode(meals)}

Semptomlar (son 3 gün):
${jsonEncode(symptoms)}

Kullanıcının hassasiyetleri: ${userAllergens.isEmpty ? 'Yok' : userAllergens.join(', ')}

Türkçe analiz yap ve JSON döndür:
{
  "summary": "Genel özet",
  "triggers": ["tetikleyici1", "tetikleyici2"],
  "recommendations": ["öneri1", "öneri2"]
}
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';

      final jsonStr = _extractJson(text);
      final json = jsonDecode(jsonStr);

      return CorrelationInsight(
        summary: json['summary'] ?? 'Analiz tamamlandı.',
        triggers:
            json['triggers'] != null ? List<String>.from(json['triggers']) : [],
        recommendations: json['recommendations'] != null
            ? List<String>.from(json['recommendations'])
            : [],
      );
    } catch (e) {
      print('Gemini correlation error: $e');
      return CorrelationInsight(
        summary: 'Analiz hatası: $e',
        triggers: [],
        recommendations: [],
      );
    }
  }

  // ==========================================
  // HELPERS
  // ==========================================

  String _extractJson(String text) {
    var cleaned = text.replaceAll(RegExp(r'```json\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'```\s*'), '');
    cleaned = cleaned.trim();

    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');

    if (start != -1 && end != -1 && end > start) {
      return cleaned.substring(start, end + 1);
    }

    return '{}';
  }
}
