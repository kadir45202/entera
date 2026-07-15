import 'package:flutter_test/flutter_test.dart';
import 'package:entera/data/services/health_data_collection_service.dart';
import 'package:entera/data/repositories/meal_repository.dart';
import 'package:entera/data/repositories/log_repository.dart';
import 'package:entera/data/repositories/allergen_repository.dart';
import 'package:entera/data/repositories/user_profile_repository.dart';
import 'dart:math';

void main() {
  group('HealthDataCollectionService Time Window Filtering', () {
    // Feature: health-insights-analysis, Property 1: Time Window Filtering Consistency
    test('Property 1: For any collection of meals with various timestamps, filtering by 3-day window returns only records within last 72 hours', () {
      final random = Random(42);
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        // Generate random meals with timestamps ranging from 10 days ago to now
        final now = DateTime.now();
        final meals = <MealAnalysis>[];
        
        final mealCount = random.nextInt(20) + 1; // 1-20 meals
        for (int j = 0; j < mealCount; j++) {
          final daysAgo = random.nextInt(10); // 0-9 days ago
          final hoursAgo = random.nextInt(24); // 0-23 hours
          final minutesAgo = random.nextInt(60); // 0-59 minutes
          
          final timestamp = now.subtract(Duration(
            days: daysAgo,
            hours: hoursAgo,
            minutes: minutesAgo,
          ));
          
          meals.add(MealAnalysis(
            detectedIngredients: [],
            detectedAllergens: [],
            riskLevel: 'none',
            createdAt: timestamp,
          ));
        }

        // Filter by time window
        final filtered = HealthDataCollectionService.filterMealsByTimeWindow(meals);

        // Verify all filtered results are within last 72 hours
        final cutoff = now.subtract(const Duration(days: 3));
        for (final meal in filtered) {
          expect(
            meal.createdAt.isAfter(cutoff),
            isTrue,
            reason: 'Meal timestamp ${meal.createdAt} should be after cutoff $cutoff',
          );
        }

        // Verify no meals within window were excluded
        final expectedCount = meals.where((m) => m.createdAt.isAfter(cutoff)).length;
        expect(filtered.length, equals(expectedCount),
            reason: 'Should include all meals within 3-day window');
      }
    });

    // Feature: health-insights-analysis, Property 1: Time Window Filtering Consistency
    test('Property 1: For any collection of logs with various timestamps, filtering by 3-day window returns only records within last 72 hours', () {
      final random = Random(42);
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        // Generate random logs with timestamps ranging from 10 days ago to now
        final now = DateTime.now();
        final logs = <HealthLog>[];
        
        final logCount = random.nextInt(30) + 1; // 1-30 logs
        for (int j = 0; j < logCount; j++) {
          final daysAgo = random.nextInt(10); // 0-9 days ago
          final hoursAgo = random.nextInt(24); // 0-23 hours
          final minutesAgo = random.nextInt(60); // 0-59 minutes
          
          final timestamp = now.subtract(Duration(
            days: daysAgo,
            hours: hoursAgo,
            minutes: minutesAgo,
          ));
          
          final logType = random.nextBool() ? LogType.stool : LogType.symptom;
          final value = logType == LogType.stool 
              ? random.nextInt(7) + 1  // Bristol scale 1-7
              : random.nextInt(10) + 1; // Severity 1-10
          
          logs.add(HealthLog(
            type: logType,
            value: value,
            createdAt: timestamp,
          ));
        }

        // Filter by time window
        final filtered = HealthDataCollectionService.filterLogsByTimeWindow(logs);

        // Verify all filtered results are within last 72 hours
        final cutoff = now.subtract(const Duration(days: 3));
        for (final log in filtered) {
          expect(
            log.createdAt.isAfter(cutoff),
            isTrue,
            reason: 'Log timestamp ${log.createdAt} should be after cutoff $cutoff',
          );
        }

        // Verify no logs within window were excluded
        final expectedCount = logs.where((l) => l.createdAt.isAfter(cutoff)).length;
        expect(filtered.length, equals(expectedCount),
            reason: 'Should include all logs within 3-day window');
      }
    });
  });

  group('HealthDataCollectionService Data Collection', () {
    late MockMealRepository mockMealRepo;
    late MockLogRepository mockLogRepo;
    late MockAllergenRepository mockAllergenRepo;
    late MockUserProfileRepository mockProfileRepo;
    late HealthDataCollectionService service;

    setUp(() {
      mockMealRepo = MockMealRepository();
      mockLogRepo = MockLogRepository();
      mockAllergenRepo = MockAllergenRepository();
      mockProfileRepo = MockUserProfileRepository();
      
      service = HealthDataCollectionService(
        mealRepo: mockMealRepo,
        logRepo: mockLogRepo,
        allergenRepo: mockAllergenRepo,
        profileRepo: mockProfileRepo,
      );
    });

    // Requirements: 1.1, 1.2, 1.3, 1.4
    test('collectData handles empty data', () async {
      // Setup: All repositories return empty data
      mockMealRepo.meals = [];
      mockLogRepo.logs = [];
      mockAllergenRepo.selectedIds = [];
      mockAllergenRepo.allergens = [];
      mockProfileRepo.profile = null;

      // Execute
      final data = await service.collectData();

      // Verify
      expect(data.meals, isEmpty);
      expect(data.stoolLogs, isEmpty);
      expect(data.symptomLogs, isEmpty);
      expect(data.profile, isNull);
      expect(data.allergens, isEmpty);
      expect(data.hasData, isFalse);
    });

    test('collectData handles single meal record', () async {
      // Setup: One meal from 1 day ago
      final now = DateTime.now();
      final meal = MealAnalysis(
        detectedIngredients: [{'name': 'Ekmek'}],
        detectedAllergens: [],
        riskLevel: 'none',
        summary: 'Test meal',
        createdAt: now.subtract(const Duration(days: 1)),
      );
      
      mockMealRepo.meals = [meal];
      mockLogRepo.logs = [];
      mockAllergenRepo.selectedIds = [];
      mockAllergenRepo.allergens = [];
      mockProfileRepo.profile = null;

      // Execute
      final data = await service.collectData();

      // Verify
      expect(data.meals, hasLength(1));
      expect(data.meals.first.summary, equals('Test meal'));
      expect(data.stoolLogs, isEmpty);
      expect(data.symptomLogs, isEmpty);
      expect(data.hasData, isTrue);
    });

    test('collectData handles multiple records of different types', () async {
      // Setup: Multiple meals, stool logs, and symptom logs
      final now = DateTime.now();
      
      final meals = [
        MealAnalysis(
          detectedIngredients: [],
          detectedAllergens: [],
          riskLevel: 'none',
          createdAt: now.subtract(const Duration(hours: 12)),
        ),
        MealAnalysis(
          detectedIngredients: [],
          detectedAllergens: [],
          riskLevel: 'none',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        MealAnalysis(
          detectedIngredients: [],
          detectedAllergens: [],
          riskLevel: 'none',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ];
      
      final logs = [
        HealthLog(
          type: LogType.stool,
          value: 4,
          createdAt: now.subtract(const Duration(hours: 6)),
        ),
        HealthLog(
          type: LogType.stool,
          value: 3,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        HealthLog(
          type: LogType.symptom,
          value: 5,
          tags: ['Bloating'],
          createdAt: now.subtract(const Duration(hours: 18)),
        ),
        HealthLog(
          type: LogType.symptom,
          value: 7,
          tags: ['Abdominal Pain'],
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ];

      final allergens = [
        Allergen(id: 1, name: 'Glüten'),
        Allergen(id: 2, name: 'Laktoz'),
      ];

      final profile = UserProfile(
        userId: 'test-user',
        displayName: 'Test User',
        age: 30,
        gender: 'male',
        allergens: ['Glüten', 'Laktoz'],
        createdAt: DateTime.now(),
      );

      mockMealRepo.meals = meals;
      mockLogRepo.logs = logs;
      mockAllergenRepo.selectedIds = [1, 2];
      mockAllergenRepo.allergens = allergens;
      mockProfileRepo.profile = profile;

      // Execute
      final data = await service.collectData();

      // Verify
      expect(data.meals, hasLength(3));
      expect(data.stoolLogs, hasLength(2));
      expect(data.symptomLogs, hasLength(2));
      expect(data.profile, isNotNull);
      expect(data.profile!.displayName, equals('Test User'));
      expect(data.allergens, hasLength(2));
      expect(data.allergens, contains('Glüten'));
      expect(data.allergens, contains('Laktoz'));
      expect(data.hasData, isTrue);
    });

    test('collectData filters out records older than 3 days', () async {
      // Setup: Mix of recent and old records
      final now = DateTime.now();
      
      final meals = [
        MealAnalysis(
          detectedIngredients: [],
          detectedAllergens: [],
          riskLevel: 'none',
          createdAt: now.subtract(const Duration(hours: 12)), // Within window
        ),
        MealAnalysis(
          detectedIngredients: [],
          detectedAllergens: [],
          riskLevel: 'none',
          createdAt: now.subtract(const Duration(days: 2)), // Within window
        ),
        MealAnalysis(
          detectedIngredients: [],
          detectedAllergens: [],
          riskLevel: 'none',
          createdAt: now.subtract(const Duration(days: 4)), // Outside window
        ),
        MealAnalysis(
          detectedIngredients: [],
          detectedAllergens: [],
          riskLevel: 'none',
          createdAt: now.subtract(const Duration(days: 10)), // Outside window
        ),
      ];
      
      final logs = [
        HealthLog(
          type: LogType.stool,
          value: 4,
          createdAt: now.subtract(const Duration(days: 1)), // Within window
        ),
        HealthLog(
          type: LogType.symptom,
          value: 5,
          tags: ['Bloating'],
          createdAt: now.subtract(const Duration(days: 5)), // Outside window
        ),
      ];

      mockMealRepo.meals = meals;
      mockLogRepo.logs = logs;
      mockAllergenRepo.selectedIds = [];
      mockAllergenRepo.allergens = [];
      mockProfileRepo.profile = null;

      // Execute
      final data = await service.collectData();

      // Verify: Only records within 3-day window are included
      expect(data.meals, hasLength(2), reason: 'Should only include meals from last 3 days');
      expect(data.stoolLogs, hasLength(1), reason: 'Should only include stool logs from last 3 days');
      expect(data.symptomLogs, isEmpty, reason: 'Symptom log is older than 3 days');
    });

    test('collectData separates stool and symptom logs correctly', () async {
      // Setup: Mix of stool and symptom logs
      final now = DateTime.now();
      
      final logs = [
        HealthLog(
          type: LogType.stool,
          value: 4,
          createdAt: now.subtract(const Duration(hours: 6)),
        ),
        HealthLog(
          type: LogType.symptom,
          value: 5,
          tags: ['Bloating'],
          createdAt: now.subtract(const Duration(hours: 12)),
        ),
        HealthLog(
          type: LogType.stool,
          value: 3,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        HealthLog(
          type: LogType.symptom,
          value: 7,
          tags: ['Pain'],
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ];

      mockMealRepo.meals = [];
      mockLogRepo.logs = logs;
      mockAllergenRepo.selectedIds = [];
      mockAllergenRepo.allergens = [];
      mockProfileRepo.profile = null;

      // Execute
      final data = await service.collectData();

      // Verify
      expect(data.stoolLogs, hasLength(2));
      expect(data.symptomLogs, hasLength(2));
      
      // Verify all stool logs are actually stool type
      for (final log in data.stoolLogs) {
        expect(log.type, equals(LogType.stool));
      }
      
      // Verify all symptom logs are actually symptom type
      for (final log in data.symptomLogs) {
        expect(log.type, equals(LogType.symptom));
      }
    });
  });
}

/// Mock implementations for testing
class MockMealRepository extends MealRepository {
  List<MealAnalysis> meals = [];

  MockMealRepository() : super(null as dynamic, null as dynamic, null as dynamic, null as dynamic);

  @override
  List<MealAnalysis> getLocalMeals() => meals;
}

class MockLogRepository extends LogRepository {
  List<HealthLog> logs = [];

  MockLogRepository() : super(null as dynamic);

  @override
  List<HealthLog> getLocalLogs({LogType? type}) {
    if (type == null) return logs;
    return logs.where((log) => log.type == type).toList();
  }
}

class MockAllergenRepository extends AllergenRepository {
  List<int> selectedIds = [];
  List<Allergen> allergens = [];

  MockAllergenRepository() : super(null as dynamic);

  @override
  List<int> getSelectedAllergenIds() => selectedIds;

  @override
  Future<List<Allergen>> getAllAllergens() async => allergens;
}

class MockUserProfileRepository extends UserProfileRepository {
  UserProfile? profile;

  MockUserProfileRepository() : super(null as dynamic);

  @override
  UserProfile? getLocalProfile() => profile;
}
