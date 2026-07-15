import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/meal_repository.dart';
import '../repositories/log_repository.dart';
import '../repositories/allergen_repository.dart';
import '../repositories/user_profile_repository.dart';

/// Data collection result for health analysis
class AnalysisData {
  final List<MealAnalysis> meals;
  final List<HealthLog> stoolLogs;
  final List<HealthLog> symptomLogs;
  final UserProfile? profile;
  final List<String> allergens;

  AnalysisData({
    required this.meals,
    required this.stoolLogs,
    required this.symptomLogs,
    this.profile,
    required this.allergens,
  });

  bool get hasData => meals.isNotEmpty || stoolLogs.isNotEmpty || symptomLogs.isNotEmpty;
}

/// Health data collection service for insights analysis
class HealthDataCollectionService {
  final MealRepository _mealRepo;
  final LogRepository _logRepo;
  final AllergenRepository _allergenRepo;
  final UserProfileRepository _profileRepo;

  HealthDataCollectionService({
    required MealRepository mealRepo,
    required LogRepository logRepo,
    required AllergenRepository allergenRepo,
    required UserProfileRepository profileRepo,
  })  : _mealRepo = mealRepo,
        _logRepo = logRepo,
        _allergenRepo = allergenRepo,
        _profileRepo = profileRepo;

  /// Collect and filter data from repositories for analysis
  Future<AnalysisData> collectData() async {
    // Fetch all data from repositories
    final allMeals = _mealRepo.getLocalMeals();
    final allLogs = _logRepo.getLocalLogs();
    final profile = _profileRepo.getLocalProfile();
    final allergenIds = _allergenRepo.getSelectedAllergenIds();
    final allAllergens = await _allergenRepo.getAllAllergens();

    // Filter by time window (last 3 days)
    final filteredMeals = filterMealsByTimeWindow(allMeals);
    final filteredLogs = filterLogsByTimeWindow(allLogs);

    // Separate stool and symptom logs
    final stoolLogs = filteredLogs.where((log) => log.type == LogType.stool).toList();
    final symptomLogs = filteredLogs.where((log) => log.type == LogType.symptom).toList();

    // Get allergen names from IDs
    final allergenNames = allAllergens
        .where((a) => allergenIds.contains(a.id))
        .map((a) => a.name)
        .toList();

    return AnalysisData(
      meals: filteredMeals,
      stoolLogs: stoolLogs,
      symptomLogs: symptomLogs,
      profile: profile,
      allergens: allergenNames,
    );
  }

  /// Filter meals by time window (last 3 days)
  static List<MealAnalysis> filterMealsByTimeWindow(List<MealAnalysis> meals) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 3));
    return meals.where((meal) => meal.createdAt.isAfter(cutoff)).toList();
  }

  /// Filter logs by time window (last 3 days)
  static List<HealthLog> filterLogsByTimeWindow(List<HealthLog> logs) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 3));
    return logs.where((log) => log.createdAt.isAfter(cutoff)).toList();
  }
}

/// Health data collection service provider
final healthDataCollectionServiceProvider = Provider<HealthDataCollectionService>((ref) {
  return HealthDataCollectionService(
    mealRepo: ref.read(mealRepositoryProvider),
    logRepo: ref.read(logRepositoryProvider),
    allergenRepo: ref.read(allergenRepositoryProvider),
    profileRepo: ref.read(userProfileRepositoryProvider),
  );
});
