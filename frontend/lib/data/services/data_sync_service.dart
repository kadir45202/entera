import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/meal_repository.dart';
import '../repositories/log_repository.dart';
import '../repositories/allergen_repository.dart';

/// DataSyncService - handles fetching user data from Supabase on app startup
class DataSyncService {
  final SupabaseClient _supabase;
  final MealRepository _mealRepo;
  final LogRepository _logRepo;
  final AllergenRepository _allergenRepo;

  DataSyncService(
      this._supabase, this._mealRepo, this._logRepo, this._allergenRepo);

  /// Fetch all user data from Supabase (last 7 days)
  /// Call this after login/register or on app startup
  Future<void> fetchUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('📥 No user logged in, skipping data sync');
      return;
    }

    print('📥 Fetching user data from Supabase...');

    try {
      // Fetch meals, logs in parallel
      await Future.wait([
        _fetchMeals(user.id),
        _fetchLogs(user.id),
        _fetchAllergens(user.id),
      ]);

      print('✅ User data synced successfully');
    } catch (e) {
      print('❌ Data sync error: $e');
    }
  }

  /// Fetch meals from last 7 days
  Future<void> _fetchMeals(String userId) async {
    try {
      // Use meal repository's fetch method
      final meals = await _mealRepo.fetchFromSupabase();

      // Save fetched meals to local storage to make them visible to user
      await _mealRepo.saveFetchedMeals(meals);

      print('📥 Fetched & saved ${meals.length} meals from Supabase');
    } catch (e) {
      print('⚠️ Meal fetch error: $e');
    }
  }

  /// Fetch logs (stool & symptom) from last 7 days
  Future<void> _fetchLogs(String userId) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final response = await _supabase
          .from('logs')
          .select()
          .eq('user_id', userId)
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .order('created_at', ascending: false);

      print('📥 Fetched ${(response as List).length} logs from Supabase');

      // Parse logs correctly without creating new IDs/timestamps
      final logs =
          (response as List).map((json) => HealthLog.fromJson(json)).toList();

      // Save to local storage
      await _logRepo.saveFetchedLogs(logs);

      print('✅ Logs saved to local storage');
    } catch (e) {
      print('⚠️ Log fetch error: $e');
    }
  }

  /// Fetch user allergens
  Future<void> _fetchAllergens(String userId) async {
    try {
      final ids = await _allergenRepo.fetchUserAllergenIds();
      print('📥 Fetched ${ids.length} allergens from Supabase');
    } catch (e) {
      print('⚠️ Allergen fetch error: $e');
    }
  }
}

/// Provider for DataSyncService
final dataSyncServiceProvider = Provider<DataSyncService>((ref) {
  final supabase = Supabase.instance.client;
  final mealRepo = ref.watch(mealRepositoryProvider);
  final logRepo = ref.watch(logRepositoryProvider);
  final allergenRepo = ref.watch(allergenRepositoryProvider);
  return DataSyncService(supabase, mealRepo, logRepo, allergenRepo);
});
