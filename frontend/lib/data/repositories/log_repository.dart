import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../providers/supabase_provider.dart';

import '../../core/config/app_config.dart';
import '../providers/auth_provider.dart';

/// Log repository provider
final logRepositoryProvider = Provider<LogRepository>((ref) {
  return LogRepository(ref.read(supabaseProvider));
});

/// Log types
enum LogType { stool, symptom }

/// Health log model
class HealthLog {
  final String localId;
  final LogType type;
  final int value;
  final List<String> tags;
  final String? notes;
  final DateTime createdAt;

  HealthLog({
    String? localId,
    required this.type,
    required this.value,
    this.tags = const [],
    this.notes,
    DateTime? createdAt,
  })  : localId = localId ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory HealthLog.fromJson(Map<String, dynamic> json) {
    return HealthLog(
      localId: json['local_id'] ?? const Uuid().v4(),
      type: json['type'] == 'stool' ? LogType.stool : LogType.symptom,
      value: json['value'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'local_id': localId,
        'type': type == LogType.stool ? 'stool' : 'symptom',
        'value': value,
        'tags': tags,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };
}

/// Bristol stool scale descriptions
class BristolScale {
  static const Map<int, String> descriptions = {
    1: 'Separate hard lumps (severe constipation)',
    2: 'Lumpy, sausage-shaped (mild constipation)',
    3: 'Sausage with cracks (normal)',
    4: 'Smooth, soft sausage (ideal)',
    5: 'Soft blobs with clear edges (lacking fiber)',
    6: 'Fluffy, mushy (mild diarrhea)',
    7: 'Watery, no solid pieces (severe diarrhea)',
  };

  static const Map<int, String> shortDescriptions = {
    1: 'Hard lumps',
    2: 'Lumpy',
    3: 'Normal',
    4: 'Ideal',
    5: 'Soft',
    6: 'Mushy',
    7: 'Watery',
  };

  static const Map<int, String> emojis = {
    1: '🪨',
    2: '🌰',
    3: '🌭',
    4: '✨',
    5: '☁️',
    6: '💨',
    7: '💧',
  };
}

/// Common symptom types
class SymptomTypes {
  static const List<String> common = [
    'Bloating',
    'Abdominal Pain',
    'Nausea',
    'Heartburn',
    'Gas',
    'Cramping',
    'Fatigue',
    'Headache',
  ];
}

/// Log repository - handles health logs with Supabase
class LogRepository {
  final SupabaseClient _supabase;

  LogRepository(this._supabase);

  // Unified storage key
  String _getLogsKey() {
    return AppConfig.userLogsKey;
  }

  /// Log stool entry - saves locally AND immediately syncs to Supabase
  Future<HealthLog> logStool({
    required int bristolType,
    List<String> tags = const [],
    String? notes,
  }) async {
    final log = HealthLog(
      type: LogType.stool,
      value: bristolType,
      tags: tags,
      notes: notes,
    );

    await _saveLocalLog(log);
    await _syncToSupabaseImmediately(log);

    return log;
  }

  /// Log symptom entry - saves locally AND immediately syncs to Supabase
  Future<HealthLog> logSymptom({
    required String symptomType,
    required int severity,
    String? notes,
  }) async {
    final log = HealthLog(
      type: LogType.symptom,
      value: severity,
      tags: [symptomType],
      notes: notes,
    );

    await _saveLocalLog(log);
    await _syncToSupabaseImmediately(log);

    return log;
  }

  /// Immediately sync a single log to Supabase (works with or without auth)
  Future<void> _syncToSupabaseImmediately(HealthLog log) async {
    try {
      final user = _supabase.auth.currentUser;
      await _supabase.from('logs').insert({
        'user_id': user?.id, // null for guest mode
        'local_id': log.localId,
        'type': log.type == LogType.stool ? 'stool' : 'symptom',
        'value': log.value,
        'tags': log.tags,
        'notes': log.notes,
      });
      print('✅ Log synced to Supabase: ${log.type}');
    } catch (e) {
      print('❌ Supabase sync error: $e');
      // Add to queue for later retry
      await _addToSyncQueue(log);
    }
  }

  /// Get local log history
  List<HealthLog> getLocalLogs({LogType? type}) {
    final box = Hive.box(AppConfig.logsBoxName);
    final storageKey = _getLogsKey();
    final logs = box.get(storageKey) ?? [];

    var result = (logs as List)
        .map((json) => HealthLog.fromJson(Map<String, dynamic>.from(json)))
        .toList();

    if (type != null) {
      result = result.where((log) => log.type == type).toList();
    }

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  /// Get stool logs only
  List<HealthLog> getStoolLogs() => getLocalLogs(type: LogType.stool);

  /// Get symptom logs only
  List<HealthLog> getSymptomLogs() => getLocalLogs(type: LogType.symptom);

  /// Save log locally
  Future<void> _saveLocalLog(HealthLog log) async {
    final box = Hive.box(AppConfig.logsBoxName);
    final storageKey = _getLogsKey();
    // Deep convert to handle Hive's LinkedHashMap issue
    final rawLogs = box.get(storageKey) ?? [];
    final logs = <Map<String, dynamic>>[];
    for (final item in rawLogs) {
      logs.add(Map<String, dynamic>.from(item as Map));
    }
    logs.add(log.toJson());

    // Keep only last 500 logs locally
    if (logs.length > 500) {
      logs.removeRange(0, logs.length - 500);
    }

    await box.put(storageKey, logs);
  }

  /// Add to sync queue
  Future<void> _addToSyncQueue(HealthLog log) async {
    final box = Hive.box(AppConfig.syncQueueBoxName);
    final rawQueue = box.get('logs') ?? [];
    final queue = <Map<String, dynamic>>[];
    for (final item in rawQueue) {
      queue.add(Map<String, dynamic>.from(item as Map));
    }
    queue.add(log.toJson());
    await box.put('logs', queue);
  }

  /// Sync local logs to Supabase (after auth)
  Future<void> syncToSupabase() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final box = Hive.box(AppConfig.syncQueueBoxName);
    final rawQueue = box.get('logs') ?? [];
    final syncQueue = <Map<String, dynamic>>[];
    for (final item in rawQueue) {
      syncQueue.add(Map<String, dynamic>.from(item as Map));
    }

    if (syncQueue.isEmpty) return;

    try {
      for (final logJson in syncQueue) {
        await _supabase.from('logs').insert({
          'user_id': user.id,
          'local_id': logJson['local_id'],
          'type': logJson['type'],
          'value': logJson['value'],
          'tags': logJson['tags'],
          'notes': logJson['notes'],
        });
      }

      // Clear sync queue on success
      await box.delete('logs');
    } catch (e) {
      // Keep queue for later retry
    }
  }

  /// Save logs fetched from server to local storage
  Future<void> saveFetchedLogs(List<HealthLog> logs) async {
    final box = Hive.box(AppConfig.logsBoxName);
    final storageKey = _getLogsKey();

    // Get existing logs
    final rawLogs = box.get(storageKey) ?? [];
    final existingLogs = (rawLogs as List).map((item) {
      if (item is HealthLog) return item;
      return HealthLog.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();

    // Create a map of existing logs by localId for quick lookup
    final logMap = {for (var log in existingLogs) log.localId: log};

    // Merge fetched logs (server is truth)
    for (final fetchedLog in logs) {
      logMap[fetchedLog.localId] = fetchedLog;
    }

    // Convert back to list and sort
    final mergedLogs = logMap.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Convert to JSON
    final logsJson = mergedLogs.map((l) => l.toJson()).toList();

    // Save to Hive
    await box.put(storageKey, logsJson);
  }
}

/// Log history state notifier for reactive updates
class LogHistoryNotifier extends StateNotifier<List<HealthLog>> {
  StreamSubscription? _subscription;

  LogHistoryNotifier() : super([]) {
    _loadLogs();
    // Watch for local storage changes (e.g. after sync)
    _subscription = Hive.box(AppConfig.logsBoxName)
        .watch(key: AppConfig.userLogsKey)
        .listen((_) => _loadLogs());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _loadLogs() {
    // Unified storage key
    const storageKey = AppConfig.userLogsKey;

    final box = Hive.box(AppConfig.logsBoxName);
    final rawLogs = box.get(storageKey) ?? [];
    final logs = <HealthLog>[];
    for (final item in rawLogs) {
      logs.add(HealthLog.fromJson(Map<String, dynamic>.from(item as Map)));
    }
    logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = logs;
  }

  void refresh() {
    _loadLogs();
  }
}

/// All logs provider - reactive
final allLogsProvider =
    StateNotifierProvider<LogHistoryNotifier, List<HealthLog>>((ref) {
  // Watch auth state to force reload on user change
  ref.watch(authStateProvider);
  return LogHistoryNotifier();
});

/// Stool logs provider - derived from allLogsProvider
final stoolLogsProvider = Provider<List<HealthLog>>((ref) {
  final logs = ref.watch(allLogsProvider);
  return logs.where((log) => log.type == LogType.stool).toList();
});

/// Symptom logs provider - derived from allLogsProvider
final symptomLogsProvider = Provider<List<HealthLog>>((ref) {
  final logs = ref.watch(allLogsProvider);
  return logs.where((log) => log.type == LogType.symptom).toList();
});
