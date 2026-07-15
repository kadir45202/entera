import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../providers/supabase_provider.dart';

import '../../core/config/app_config.dart';
import '../providers/auth_provider.dart';

import '../services/gemini_service.dart';
import 'allergen_repository.dart';
import 'log_repository.dart';

/// Meal repository provider
final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(
    ref.read(supabaseProvider),
    ref.read(geminiServiceProvider),
    ref.read(allergenRepositoryProvider),
    ref.read(logRepositoryProvider),
  );
});

/// Meal analysis result model
class MealAnalysis {
  final String localId;
  final List<Map<String, dynamic>> detectedIngredients;
  final List<Map<String, dynamic>> detectedAllergens;
  final String riskLevel;
  final List<String> userWarnings;
  final String? summary;
  final String? healthPrediction;
  final DateTime createdAt;

  MealAnalysis({
    String? localId,
    required this.detectedIngredients,
    required this.detectedAllergens,
    required this.riskLevel,
    this.userWarnings = const [],
    this.summary,
    this.healthPrediction,
    DateTime? createdAt,
  })  : localId = localId ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory MealAnalysis.fromJson(Map<String, dynamic> json) {
    // Properly convert nested maps from LinkedHashMap
    List<Map<String, dynamic>> convertList(dynamic list) {
      if (list == null) return [];
      return (list as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    return MealAnalysis(
      localId: json['local_id'] ?? const Uuid().v4(),
      detectedIngredients: convertList(json['detected_ingredients']),
      detectedAllergens: convertList(json['detected_allergens']),
      riskLevel: json['risk_level'] ?? 'none',
      userWarnings: json['user_allergen_warnings'] != null
          ? List<String>.from(json['user_allergen_warnings'])
          : [],
      summary: json['summary'],
      healthPrediction: json['health_prediction'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'local_id': localId,
        'detected_ingredients': detectedIngredients,
        'detected_allergens': detectedAllergens,
        'risk_level': riskLevel,
        'user_allergen_warnings': userWarnings,
        'summary': summary,
        'health_prediction': healthPrediction,
        'created_at': createdAt.toIso8601String(),
      };

  bool get hasWarnings => userWarnings.isNotEmpty || riskLevel != 'none';
}

/// Meal repository - handles meal analysis with AI
class MealRepository {
  final SupabaseClient _supabase;
  final GeminiService _gemini;
  final AllergenRepository _allergenRepo;
  final LogRepository _logRepo;

  MealRepository(
      this._supabase, this._gemini, this._allergenRepo, this._logRepo);

  // Unified storage key for both guest and registered users
  String _getMealsKey() {
    return AppConfig.userMealsKey;
  }

  /// Analyze meal image with Gemini AI
  Future<MealAnalysis> analyzeMeal(Uint8List imageBytes) async {
    // Get user's allergens for personalized analysis
    final allergenIds = _allergenRepo.getSelectedAllergenIds();
    final allAllergens = await _allergenRepo.getAllAllergens();
    final userAllergens = allAllergens
        .where((a) => allergenIds.contains(a.id))
        .map((a) => a.name)
        .toList();

    // Get recent bowel data for health prediction
    final recentLogs = _logRepo.getStoolLogs().take(5).toList();
    final bowelData = recentLogs
        .map((log) => {
              'date': _formatDate(log.createdAt),
              'type': 'Tip ${log.value}',
              'description': BristolScale.shortDescriptions[log.value] ?? '',
            })
        .toList();

    // Analyze with AI
    final result = await _gemini.analyzeMealImage(
      imageBytes,
      userAllergens: userAllergens,
      recentBowelData: bowelData,
    );

    // Check for user-specific warnings
    final warnings = <String>[];

    // Check detected allergens against user allergens
    for (final allergen in result.detectedAllergens) {
      final allergenName = allergen['name']?.toString().toLowerCase() ?? '';
      for (final userAllergen in userAllergens) {
        if (allergenName.contains(userAllergen.toLowerCase()) ||
            userAllergen.toLowerCase().contains(allergenName)) {
          warnings.add(
              '⚠️ ${allergen['name']} tespit edildi! (${allergen['trigger_ingredient']})');
          break;
        }
      }
    }

    // Check detected ingredients for common allergen triggers
    for (final ingredient in result.detectedIngredients) {
      final ingredientName = ingredient['name']?.toString().toLowerCase() ?? '';
      for (final userAllergen in userAllergens) {
        final allergenLower = userAllergen.toLowerCase();
        if (_isAllergenIngredient(ingredientName, allergenLower)) {
          warnings.add(
              '⚠️ $userAllergen hassasiyeti: ${ingredient['name']} içeriyor olabilir');
          break;
        }
      }
    }

    // Determine risk level based on warnings
    String finalRiskLevel = result.riskLevel;
    if (warnings.isNotEmpty && finalRiskLevel == 'none') {
      finalRiskLevel = 'medium';
    }
    if (warnings.length >= 2) {
      finalRiskLevel = 'high';
    }

    final mealAnalysis = MealAnalysis(
      detectedIngredients: result.detectedIngredients,
      detectedAllergens: result.detectedAllergens,
      riskLevel: finalRiskLevel,
      userWarnings: warnings,
      summary: result.summary,
      healthPrediction: result.healthPrediction,
    );

    // Store locally
    await _saveLocalMeal(mealAnalysis);

    return mealAnalysis;
  }

  /// Check if ingredient contains allergen
  bool _isAllergenIngredient(String ingredient, String allergen) {
    final allergenMappings = {
      'gluten': [
        'ekmek',
        'makarna',
        'pasta',
        'un',
        'bulgur',
        'börek',
        'pizza',
        'krep',
        'kek',
        'bisküvi'
      ],
      'laktoz': [
        'süt',
        'peynir',
        'yoğurt',
        'tereyağı',
        'krema',
        'dondurma',
        'kaşar'
      ],
      'fıstık': ['fıstık', 'fındık', 'badem', 'ceviz'],
      'yumurta': ['yumurta', 'omlet', 'menemen'],
      'deniz ürünleri': [
        'balık',
        'karides',
        'midye',
        'kalamar',
        'somon',
        'levrek'
      ],
      'soya': ['soya', 'tofu', 'edamame'],
    };

    final triggers = allergenMappings[allergen] ?? [];
    return triggers.any((trigger) => ingredient.contains(trigger));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Bugün';
    if (diff.inDays == 1) return 'Dün';
    return '${diff.inDays} gün önce';
  }

  /// Save meal publicly (for manual confirmation) - saves locally AND syncs to Supabase
  Future<void> saveMeal(MealAnalysis meal) async {
    await _saveLocalMeal(meal);
    await _syncMealToSupabase(meal);
  }

  /// Get local meal history (partitioned by session mode)
  List<MealAnalysis> getLocalMeals() {
    final box = Hive.box(AppConfig.mealsBoxName);
    final storageKey = _getMealsKey();
    final meals = box.get(storageKey) ?? [];
    return (meals as List)
        .map((json) => MealAnalysis.fromJson(Map<String, dynamic>.from(json)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Save meal analysis locally (partitioned by session mode)
  Future<void> _saveLocalMeal(MealAnalysis meal) async {
    final box = Hive.box(AppConfig.mealsBoxName);
    final storageKey = _getMealsKey();
    // Deep convert to handle Hive's LinkedHashMap issue
    final rawMeals = box.get(storageKey) ?? [];
    final meals = <Map<String, dynamic>>[];
    for (final item in rawMeals) {
      meals.add(Map<String, dynamic>.from(item as Map));
    }
    meals.add(meal.toJson());

    // Keep only last 100 meals locally
    if (meals.length > 100) {
      meals.removeRange(0, meals.length - 100);
    }

    await box.put(storageKey, meals);
  }

  /// Immediately sync a meal to Supabase (works with or without auth)
  Future<void> _syncMealToSupabase(MealAnalysis meal) async {
    try {
      final user = _supabase.auth.currentUser;
      await _supabase.from('meals').insert({
        'user_id': user?.id, // null for guest mode
        'local_id': meal.localId,
        'detected_ingredients': meal.detectedIngredients,
        'detected_allergens': meal.detectedAllergens,
        'risk_level': meal.riskLevel,
        'summary': meal.summary,
        'health_prediction': meal.healthPrediction,
      });
      print('✅ Meal synced to Supabase: ${meal.summary}');
    } catch (e) {
      print('❌ Supabase meal sync error: $e');
    }
  }

  /// Sync local meals to Supabase (after auth)
  Future<void> syncToSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final box = Hive.box(AppConfig.mealsBoxName);
    // Deep convert to handle Hive's LinkedHashMap issue
    final rawQueue = box.get('sync_queue') ?? [];
    final syncQueue = <Map<String, dynamic>>[];
    for (final item in rawQueue) {
      syncQueue.add(Map<String, dynamic>.from(item as Map));
    }

    if (syncQueue.isEmpty) return;

    try {
      for (final mealJson in syncQueue) {
        await _supabase.from('meals').insert({
          'user_id': user.id,
          'local_id': mealJson['local_id'],
          'detected_ingredients': mealJson['detected_ingredients'],
          'detected_allergens': mealJson['detected_allergens'],
          'risk_level': mealJson['risk_level'],
        });
      }

      // Clear sync queue on success
      await box.delete('sync_queue');
    } catch (e) {
      // Keep queue for later retry
    }
  }

  /// Fetch meals from Supabase
  Future<List<MealAnalysis>> fetchFromSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return getLocalMeals();

    try {
      final response = await _supabase
          .from('meals')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((json) => MealAnalysis.fromJson(json))
          .toList();
    } catch (e) {
      return getLocalMeals();
    }
  }

  /// Save meals fetched from server to local storage
  Future<void> saveFetchedMeals(List<MealAnalysis> meals) async {
    final box = Hive.box(AppConfig.mealsBoxName);
    final storageKey = _getMealsKey();

    // Get existing meals
    final rawMeals = box.get(storageKey) ?? [];
    final existingMeals = (rawMeals as List).map((item) {
      if (item is MealAnalysis) return item;
      return MealAnalysis.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();

    // Create a map by localId
    final mealMap = {for (var meal in existingMeals) meal.localId: meal};

    // Merge fetched meals
    for (final fetchedMeal in meals) {
      mealMap[fetchedMeal.localId] = fetchedMeal;
    }

    // Convert back to list and sort
    final mergedMeals = mealMap.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Convert to JSON
    // Note: MealAnalysis.toJson() handles internal list conversions
    final mealsJson = mergedMeals.map((m) => m.toJson()).toList();

    // Save to Hive
    await box.put(storageKey, mealsJson);
  }
}

/// Meal history state notifier for reactive updates
class MealHistoryNotifier extends StateNotifier<List<MealAnalysis>> {
  StreamSubscription? _subscription;

  MealHistoryNotifier() : super([]) {
    _loadMeals();
    // Watch for local storage changes (e.g. after sync)
    _subscription = Hive.box(AppConfig.mealsBoxName)
        .watch(key: AppConfig.userMealsKey)
        .listen((_) => _loadMeals());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _loadMeals() {
    final box = Hive.box(AppConfig.mealsBoxName);
    const storageKey = AppConfig.userMealsKey;
    final meals = box.get(storageKey) ?? [];
    state = (meals as List)
        .map((json) => MealAnalysis.fromJson(Map<String, dynamic>.from(json)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void refresh() {
    _loadMeals();
  }
}

/// Meal history provider - reactive
final mealHistoryProvider =
    StateNotifierProvider<MealHistoryNotifier, List<MealAnalysis>>((ref) {
  // Watch auth state to reload meals on user change
  ref.watch(authStateProvider);
  return MealHistoryNotifier();
});
