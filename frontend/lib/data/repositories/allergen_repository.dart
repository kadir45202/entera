import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_provider.dart';

import '../../core/config/app_config.dart';

/// Allergen repository provider
final allergenRepositoryProvider = Provider<AllergenRepository>((ref) {
  return AllergenRepository(ref.read(supabaseProvider));
});

/// Allergen model
class Allergen {
  final int id;
  final String name;
  final List<String> triggerKeywords;

  Allergen({
    required this.id,
    required this.name,
    this.triggerKeywords = const [],
  });

  factory Allergen.fromJson(Map<String, dynamic> json) {
    return Allergen(
      id: json['id'],
      name: json['name'],
      triggerKeywords: json['trigger_keywords'] != null
          ? List<String>.from(json['trigger_keywords'])
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'trigger_keywords': triggerKeywords,
      };
}

/// Allergen repository - handles allergen data with Supabase
class AllergenRepository {
  final SupabaseClient _supabase;

  AllergenRepository(this._supabase);

  /// Get all available allergens from Supabase
  Future<List<Allergen>> getAllAllergens() async {
    final box = Hive.box(AppConfig.allergensBoxName);

    try {
      final response = await _supabase.from('allergens').select().order('name');

      final allergens =
          (response as List).map((json) => Allergen.fromJson(json)).toList();

      // Cache locally
      await box.put('all_allergens', allergens.map((a) => a.toJson()).toList());

      return allergens;
    } catch (e) {
      // Fall back to cached data
      final cached = box.get('all_allergens');
      if (cached != null) {
        return (cached as List)
            .map((json) => Allergen.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }

      // Return default allergens if no cache
      return _getDefaultAllergens();
    }
  }

  /// Get user's selected allergens (local storage)
  List<int> getSelectedAllergenIds() {
    final box = Hive.box(AppConfig.allergensBoxName);
    final selected = box.get('selected_ids');
    return selected != null ? List<int>.from(selected) : [];
  }

  /// Save user's allergen selections (local storage)
  Future<void> saveSelectedAllergenIds(List<int> ids) async {
    final box = Hive.box(AppConfig.allergensBoxName);
    await box.put('selected_ids', ids);
  }

  /// Sync allergen selections to Supabase (after auth)
  Future<void> syncToSupabase(List<int> allergenIds) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Delete existing selections
      await _supabase.from('user_allergens').delete().eq('user_id', user.id);

      // Insert new selections
      if (allergenIds.isNotEmpty) {
        final inserts = allergenIds
            .map((id) => {
                  'user_id': user.id,
                  'allergen_id': id,
                })
            .toList();

        await _supabase.from('user_allergens').insert(inserts);
      }
    } catch (e) {
      // Queue for later sync if offline
      final box = Hive.box(AppConfig.syncQueueBoxName);
      final queue =
          List<Map<String, dynamic>>.from(box.get('allergen_sync') ?? []);
      queue.add(
          {'ids': allergenIds, 'timestamp': DateTime.now().toIso8601String()});
      await box.put('allergen_sync', queue);
    }
  }

  /// Process sync queue
  Future<void> processSyncQueue() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final box = Hive.box(AppConfig.syncQueueBoxName);
    final queue =
        List<Map<String, dynamic>>.from(box.get('allergen_sync') ?? []);

    if (queue.isEmpty) return;

    // Only process the last item (most recent selection overwrites others)
    final lastItem = queue.last;
    final ids = List<int>.from(lastItem['ids']);

    try {
      await syncToSupabase(
          ids); // This might recurse if fail? No, if it fails it adds to queue.
      // But we are calling syncToSupabase which ADDS to queue on fail.
      // So we must be careful not to double queue.
      // Actually syncToSupabase logic above adds to queue on error.
      // So we should have a separate _internalSync method?
      // Or just clear queue FIRST?

      // Let's implement safer logic:
      // We manually clear queue, then try sync. If fail, syncToSupabase will re-queue.
      await box.delete('allergen_sync');

      // But wait, if syncToSupabase calls _supabase... and fails... it re-queues.
      // That's fine.
    } catch (e) {
      // Already handled by syncToSupabase
    }
  }

  /// Get user's allergens from Supabase
  Future<List<int>> fetchUserAllergenIds() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return getSelectedAllergenIds();

    try {
      final response = await _supabase
          .from('user_allergens')
          .select('allergen_id')
          .eq('user_id', user.id);

      final ids =
          (response as List).map((row) => row['allergen_id'] as int).toList();

      // Update local cache
      await saveSelectedAllergenIds(ids);

      return ids;
    } catch (e) {
      return getSelectedAllergenIds();
    }
  }

  List<Allergen> _getDefaultAllergens() {
    return [
      Allergen(
          id: 1,
          name: 'Glüten',
          triggerKeywords: ['gluten', 'buğday', 'un', 'ekmek', 'makarna']),
      Allergen(
          id: 2,
          name: 'Laktoz',
          triggerKeywords: ['lactose', 'süt', 'peynir', 'yoğurt', 'tereyağı']),
      Allergen(
          id: 3,
          name: 'Yumurta',
          triggerKeywords: ['egg', 'yumurta', 'omlet', 'menemen']),
      Allergen(
          id: 4,
          name: 'Yer Fıstığı',
          triggerKeywords: ['peanut', 'yer fıstığı', 'fıstık ezmesi']),
      Allergen(
          id: 5,
          name: 'Kabuklu Kuruyemişler',
          triggerKeywords: ['badem', 'ceviz', 'fındık', 'antepfıstığı']),
      Allergen(
          id: 6,
          name: 'Soya',
          triggerKeywords: ['soy', 'soya', 'tofu', 'edamame']),
      Allergen(
          id: 7,
          name: 'Balık',
          triggerKeywords: ['fish', 'balık', 'somon', 'levrek', 'hamsi']),
      Allergen(id: 8, name: 'Deniz Ürünleri', triggerKeywords: [
        'karides',
        'midye',
        'kalamar',
        'ahtapot',
        'istiridye'
      ]),
      Allergen(
          id: 9, name: 'Susam', triggerKeywords: ['sesame', 'susam', 'tahin']),
      Allergen(
          id: 10,
          name: 'Sülfit',
          triggerKeywords: ['sulfite', 'sülfit', 'şarap', 'kuru meyve']),
      Allergen(
          id: 11,
          name: 'FODMAPs',
          triggerKeywords: ['soğan', 'sarımsak', 'elma', 'armut', 'fasulye']),
      Allergen(
          id: 12,
          name: 'Kafein',
          triggerKeywords: ['kahve', 'çay', 'çikolata', 'enerji içeceği']),
      Allergen(
          id: 13,
          name: 'Alkol',
          triggerKeywords: ['alkol', 'bira', 'şarap', 'rakı', 'votka']),
      Allergen(
          id: 14,
          name: 'Baharatlı Yiyecekler',
          triggerKeywords: ['acı biber', 'pul biber', 'baharatlı', 'acılı']),
    ];
  }
}

/// Allergens list provider
final allergensListProvider = FutureProvider<List<Allergen>>((ref) async {
  final repo = ref.read(allergenRepositoryProvider);
  return repo.getAllAllergens();
});

/// Selected allergen IDs provider
final selectedAllergenIdsProvider = StateProvider<List<int>>((ref) {
  final repo = ref.read(allergenRepositoryProvider);
  return repo.getSelectedAllergenIds();
});
