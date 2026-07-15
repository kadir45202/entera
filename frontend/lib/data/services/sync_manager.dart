import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/meal_repository.dart';
import '../repositories/log_repository.dart';
import '../repositories/allergen_repository.dart';

/// SyncManager provider
final syncManagerProvider = Provider<SyncManager>((ref) {
  return SyncManager(
    ref.read(mealRepositoryProvider),
    ref.read(logRepositoryProvider),
    ref.read(allergenRepositoryProvider),
  );
});

/// Manages background data synchronization
class SyncManager with WidgetsBindingObserver {
  final MealRepository _mealRepo;
  final LogRepository _logRepo;
  final AllergenRepository _allergenRepo;

  Timer? _syncTimer;
  bool _isSyncing = false;

  SyncManager(this._mealRepo, this._logRepo, this._allergenRepo) {
    WidgetsBinding.instance.addObserver(this);
    _startPeriodicSync();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Trigger sync when app comes to foreground
      runSync();
    }
  }

  void _startPeriodicSync() {
    // Sync every 5 minutes while app is running
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      runSync();
    });
  }

  /// Run full synchronization
  Future<void> runSync() async {
    if (_isSyncing) return;

    // Check if user is logged in (including anonymous)
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _isSyncing = true;
    print('🔄 Starting background sync...');

    try {
      await Future.wait([
        _mealRepo.syncToSupabase(),
        _logRepo.syncToSupabase(),
        // AllergenRepo doesn't have a parameterless sync method exposed yet?
        // Ah, I added processSyncQueue to AllergenRepository in previous step.
        // Wait, I need to cast/check if method exists if I haven't updated the interface definition properly?
        // No, in Dart dynamic dispatch or updated file is fine.
        // But I need to be sure I updated the class definition.
        // Yes, Step 88.
        _allergenRepo.processSyncQueue(), // This method was added in Step 88
      ]);
      print('✅ Background sync completed');
    } catch (e) {
      print('⚠️ Background sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
