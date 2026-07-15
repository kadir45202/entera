import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Seeds test data for new users - 3 days of random health data
class NewUserDataSeeder {
  final SupabaseClient _supabase;
  final String _userId;
  final Random _random = Random();

  NewUserDataSeeder(this._supabase, this._userId);

  /// Seed all test data for new user
  Future<void> seedAll() async {
    await _seedLogs();
    await _seedMeals();
    await _seedAnalytics();
    print('✅ Test data seeded for new user');
  }

  /// Seed 3 days of stool and symptom logs
  Future<void> _seedLogs() async {
    final logs = <Map<String, dynamic>>[];

    for (int day = 0; day < 3; day++) {
      final date = DateTime.now().subtract(Duration(days: day));

      // 1-2 stool logs per day
      final stoolCount = _random.nextInt(2) + 1;
      for (int i = 0; i < stoolCount; i++) {
        logs.add({
          'user_id': _userId,
          'local_id': 'seed_stool_${day}_$i',
          'type': 'stool',
          'value': _random.nextInt(7) + 1, // Bristol 1-7
          'tags': _getRandomTags(['morning', 'after_meal', 'normal', 'urgent']),
          'notes': _getRandomNote(
              ['İyi hissettim', 'Karın ağrısı vardı', 'Normal', null]),
          'created_at': date
              .subtract(Duration(hours: _random.nextInt(12)))
              .toIso8601String(),
        });
      }

      // 0-2 symptom logs per day
      final symptomCount = _random.nextInt(3);
      for (int i = 0; i < symptomCount; i++) {
        logs.add({
          'user_id': _userId,
          'local_id': 'seed_symptom_${day}_$i',
          'type': 'symptom',
          'value': _random.nextInt(8) + 1, // Severity 1-8
          'tags': [_getRandomSymptom()],
          'notes': null,
          'created_at': date
              .subtract(Duration(hours: _random.nextInt(12)))
              .toIso8601String(),
        });
      }
    }

    try {
      for (final log in logs) {
        await _supabase.from('logs').insert(log);
      }
    } catch (e) {
      print('❌ Log seeding error: $e');
    }
  }

  /// Seed 3-5 meal analyses
  Future<void> _seedMeals() async {
    final meals = [
      {
        'summary': 'Mercimek Çorbası',
        'risk_level': 'none',
        'health_prediction':
            'Bağırsak sağlığı için faydalı, lif açısından zengin',
        'detected_ingredients': [
          {'name': 'Mercimek', 'confidence': 0.95},
          {'name': 'Havuç', 'confidence': 0.88},
          {'name': 'Soğan', 'confidence': 0.85},
        ],
        'detected_allergens': [],
      },
      {
        'summary': 'Tavuk Döner',
        'risk_level': 'low',
        'health_prediction': 'Yüksek protein, yağ içeriği orta seviyede',
        'detected_ingredients': [
          {'name': 'Tavuk', 'confidence': 0.92},
          {'name': 'Lavaş', 'confidence': 0.88},
          {'name': 'Domates', 'confidence': 0.85},
        ],
        'detected_allergens': [
          {'name': 'Gluten', 'trigger_ingredient': 'Lavaş'},
        ],
      },
      {
        'summary': 'Kahvaltı Tabağı',
        'risk_level': 'medium',
        'health_prediction': 'Dengeli kahvaltı, süt ürünleri içeriyor',
        'detected_ingredients': [
          {'name': 'Yumurta', 'confidence': 0.95},
          {'name': 'Peynir', 'confidence': 0.90},
          {'name': 'Domates', 'confidence': 0.88},
          {'name': 'Zeytin', 'confidence': 0.85},
        ],
        'detected_allergens': [
          {'name': 'Süt', 'trigger_ingredient': 'Peynir'},
          {'name': 'Yumurta', 'trigger_ingredient': 'Yumurta'},
        ],
      },
      {
        'summary': 'Lahmacun',
        'risk_level': 'low',
        'health_prediction': 'Protein ve karbonhidrat açısından dengeli',
        'detected_ingredients': [
          {'name': 'Kıyma', 'confidence': 0.93},
          {'name': 'Hamur', 'confidence': 0.90},
          {'name': 'Maydanoz', 'confidence': 0.85},
        ],
        'detected_allergens': [
          {'name': 'Gluten', 'trigger_ingredient': 'Hamur'},
        ],
      },
    ];

    try {
      for (int i = 0; i < meals.length; i++) {
        final meal = meals[i];
        await _supabase.from('meals').insert({
          'user_id': _userId,
          'local_id': 'seed_meal_$i',
          'summary': meal['summary'],
          'risk_level': meal['risk_level'],
          'health_prediction': meal['health_prediction'],
          'detected_ingredients': meal['detected_ingredients'],
          'detected_allergens': meal['detected_allergens'],
          'created_at': DateTime.now()
              .subtract(Duration(days: i, hours: _random.nextInt(8)))
              .toIso8601String(),
        });
      }
    } catch (e) {
      print('❌ Meal seeding error: $e');
    }
  }

  /// Seed initial analytics events
  Future<void> _seedAnalytics() async {
    try {
      await _supabase.from('analytics').insert({
        'user_id': _userId,
        'session_id': 'seed_session',
        'event_type': 'userRegister',
        'event_data': {'seeded': true, 'test_data_days': 3},
      });
    } catch (e) {
      print('❌ Analytics seeding error: $e');
    }
  }

  List<String> _getRandomTags(List<String> options) {
    final count = _random.nextInt(2) + 1;
    final shuffled = List<String>.from(options)..shuffle(_random);
    return shuffled.take(count).toList();
  }

  String? _getRandomNote(List<String?> options) {
    return options[_random.nextInt(options.length)];
  }

  String _getRandomSymptom() {
    const symptoms = [
      'Şişkinlik',
      'Karın Ağrısı',
      'Mide Bulantısı',
      'Gaz',
      'Kramp',
      'Yorgunluk'
    ];
    return symptoms[_random.nextInt(symptoms.length)];
  }
}
