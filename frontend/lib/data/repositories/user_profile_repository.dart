import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';
import '../providers/supabase_provider.dart';

/// User profile model (Unified)
class UserProfile {
  final String userId;
  final String? email;
  final String displayName;
  final int age;
  final String gender;
  final List<String> allergens;
  final bool isGuest;
  final DateTime createdAt;

  const UserProfile({
    required this.userId,
    this.email,
    required this.displayName,
    required this.age,
    required this.gender,
    this.allergens = const [],
    this.isGuest = true,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['id'] ?? '',
      email: json['email'],
      displayName: json['display_name'] ?? 'Misafir',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      allergens:
          json['allergens'] != null ? List<String>.from(json['allergens']) : [],
      isGuest: json['is_guest'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': userId,
        'email': email,
        'display_name': displayName,
        'age': age,
        'gender': gender,
        'allergens': allergens,
        'is_guest': isGuest,
        'created_at': createdAt.toIso8601String(),
      };
}

/// User profile repository provider
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(ref.read(supabaseProvider));
});

/// Current user profile provider
final currentUserProfileProvider = StateProvider<UserProfile?>((ref) {
  final repo = ref.read(userProfileRepositoryProvider);
  return repo.getLocalProfile();
});

/// Has completed welcome provider (for routing)
final hasCompletedWelcomeProvider = StateProvider<bool>((ref) {
  final box = Hive.box(AppConfig.authBoxName);
  return box.get('welcome_completed') ?? false;
});

/// User profile repository
class UserProfileRepository {
  final SupabaseClient _supabase;

  UserProfileRepository(this._supabase);

  /// Fetch profile from Supabase and cache locally
  Future<UserProfile?> fetchProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        final profile = UserProfile.fromJson(response);
        await _saveLocalProfile(profile);
        return profile;
      }
    } catch (e) {
      print('⚠️ Failed to fetch profile: $e');
    }
    return getLocalProfile();
  }

  /// Update profile (Unified)
  Future<void> updateProfile({
    int? age,
    String? gender,
    List<String>? allergens,
    String? displayName,
  }) async {
    final user = _supabase.auth.currentUser;
    // We allow updating even if user is null locally first? No, we need auth for "guestLogin" first.
    // In WelcomeScreen, we will login first.

    if (user == null) {
      // If no user, we can't save to DB.
      // For Welcome Screen "Guest" flow, we MUST have called guestLogin first.
      throw Exception('User must be logged in (or guest) to update profile');
    }

    // Get current local profile to merge
    final current = getLocalProfile();

    final updates = {
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (allergens != null) 'allergens': allergens,
      if (displayName != null) 'display_name': displayName,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Optimistic local update
    if (current != null) {
      final updatedProfile = UserProfile(
        userId: current.userId,
        email: current.email,
        displayName: displayName ?? current.displayName,
        age: age ?? current.age,
        gender: gender ?? current.gender,
        allergens: allergens ?? current.allergens,
        isGuest: current.isGuest,
        createdAt: current.createdAt,
      );
      await _saveLocalProfile(updatedProfile);
    }

    // Sync to Supabase
    try {
      await _supabase.from('users').update(updates).eq('id', user.id);
      print('✅ Profile updated on Supabase');
    } catch (e) {
      print('❌ Failed to update profile on Supabase: $e');
      // Queue for sync? (Will be handled by SyncManager later)
    }
  }

  /// Save profile locally
  Future<void> _saveLocalProfile(UserProfile profile) async {
    final box = Hive.box(AppConfig.authBoxName);
    await box.put('user_profile', profile.toJson());
  }

  /// Get local profile
  UserProfile? getLocalProfile() {
    final box = Hive.box(AppConfig.authBoxName);
    final json = box.get('user_profile');
    if (json == null) return null;
    return UserProfile.fromJson(Map<String, dynamic>.from(json));
  }

  Future<void> setWelcomeCompleted() async {
    final box = Hive.box(AppConfig.authBoxName);
    await box.put('welcome_completed', true);
  }

  /// Clear profile (for testing/logout)
  Future<void> clearProfile() async {
    final box = Hive.box(AppConfig.authBoxName);
    await box.delete('user_profile');
    await box.delete('welcome_completed');
  }
}
