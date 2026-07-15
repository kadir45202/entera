import 'package:hive_flutter/hive_flutter.dart';

import '../core/config/app_config.dart';

/// Database seeder - şu anda devre dışı
/// Tüm veriler gerçek AI analizlerinden gelecek
class DatabaseSeeder {
  /// Artık test verisi eklemiyor
  /// Kullanıcı kendi verilerini oluşturacak
  static Future<void> seedIfEmpty() async {
    // Test verileri kaldırıldı
    // Tüm yemek verileri AI analizinden gelecek
    // Dışkı ve semptom kayıtları kullanıcı tarafından girilecek
  }

  /// Tüm verileri temizle
  static Future<void> clearAllData() async {
    final logsBox = Hive.box(AppConfig.logsBoxName);
    final mealsBox = Hive.box(AppConfig.mealsBoxName);

    await logsBox.delete('history');
    await mealsBox.delete('history');
  }
}
