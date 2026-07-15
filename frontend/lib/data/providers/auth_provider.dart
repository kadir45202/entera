import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';

import 'supabase_provider.dart';
import '../services/new_user_seeder.dart';
import '../services/analytics_service.dart';
import '../services/data_sync_service.dart';
import '../repositories/allergen_repository.dart';

/// Auth state model
class AuthState {
  final bool isAuthenticated;
  final bool hasCompletedOnboarding;
  final String? userId;
  final String? email;
  final String? displayName;
  final SessionMode sessionMode;

  const AuthState({
    this.isAuthenticated = false,
    this.hasCompletedOnboarding = false,
    this.userId,
    this.email,
    this.displayName,
    this.sessionMode = SessionMode.pending,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? hasCompletedOnboarding,
    String? userId,
    String? email,
    String? displayName,
    SessionMode? sessionMode,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      sessionMode: sessionMode ?? this.sessionMode,
    );
  }

  /// Get display name or fallback to email prefix or 'Misafir'
  String get greeting {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (email != null && email!.isNotEmpty) return email!.split('@').first;
    return 'Misafir';
  }
}

/// Auth state provider
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<AuthState>>((ref) {
  return AuthStateNotifier(ref);
});

class AuthStateNotifier extends StateNotifier<AsyncValue<AuthState>> {
  final Ref _ref;

  AuthStateNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  SupabaseClient get _supabase => _ref.read(supabaseProvider);

  Future<void> _init() async {
    try {
      final authBox = Hive.box(AppConfig.authBoxName);
      final storedMode = authBox.get(AppConfig.activeModeKey);
      print('🔐 Auth Init: storedMode=$storedMode');

      // Check for existing session
      final session = _supabase.auth.currentSession;
      final user = _supabase.auth.currentUser;
      print('🔐 Auth Init: session=${session != null}, user=${user?.id}');

      if (session != null && user != null) {
        // User is authenticated
        await authBox.put(AppConfig.activeModeKey, 'user');
        final hasOnboarded = await _checkOnboardingStatus(user.id);

        state = AsyncValue.data(AuthState(
          isAuthenticated: true,
          hasCompletedOnboarding: hasOnboarded,
          userId: user.id,
          email: user.email,
          sessionMode: SessionMode.user,
        ));
      } else if (storedMode == 'guest') {
        // Was using as guest, restore guest mode
        state = const AsyncValue.data(AuthState(
          isAuthenticated: false,
          sessionMode: SessionMode.guest,
        ));
      } else {
        // No session, no stored mode = pending (needs to choose)
        state = const AsyncValue.data(AuthState(
          sessionMode: SessionMode.pending,
        ));
      }

      // Listen for auth changes
      _supabase.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        final user = session?.user;
        print(
            '🔐 Auth Change: event=${data.event}, session=${session != null}, user=${user?.id}');

        if (user != null) {
          authBox.put(AppConfig.activeModeKey, 'user');
          state = AsyncValue.data(AuthState(
            isAuthenticated: true,
            hasCompletedOnboarding:
                state.valueOrNull?.hasCompletedOnboarding ?? false,
            userId: user.id,
            email: user.email,
            sessionMode: SessionMode.user,
          ));
        } else {
          // Session ended but keep current mode if guest
          final currentMode = authBox.get(AppConfig.activeModeKey);
          print('🔐 Auth Change (Logged out): currentMode=$currentMode');
          if (currentMode == 'guest') {
            state = const AsyncValue.data(AuthState(
              sessionMode: SessionMode.guest,
            ));
          } else {
            state = const AsyncValue.data(AuthState(
              sessionMode: SessionMode.pending,
            ));
          }
        }
      });
    } catch (e, stack) {
      print('❌ Auth Init Error: $e');
      print(stack);
      state = const AsyncValue.data(AuthState());
    }
  }

  Future<bool> _checkOnboardingStatus(String userId) async {
    // 1. Check local storage first (Offline-First)
    try {
      final authBox = Hive.box(AppConfig.authBoxName);
      final userData = authBox.get(AppConfig.userKey);
      if (userData != null && userData['onboarded'] == true) {
        return true;
      }
    } catch (e) {
      // Ignore local read error
    }

    // 2. Check Supabase if local is false/missing
    try {
      final response = await _supabase
          .from('user_allergens')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      final isOnboarded = (response as List).isNotEmpty;

      // Sync back to local if found on server
      if (isOnboarded) {
        final authBox = Hive.box(AppConfig.authBoxName);
        final userData = authBox.get(AppConfig.userKey) ?? {};
        userData['onboarded'] = true;
        await authBox.put(AppConfig.userKey, userData);
      }

      return isOnboarded;
    } catch (e) {
      // If both fail, return false (will force onboarding)
      return false;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final hasOnboarded = await _checkOnboardingStatus(response.user!.id);

        // Get display name from user metadata or local storage
        final metadata = response.user!.userMetadata;
        String? displayName = metadata?['display_name'];

        // Try loading from local storage if not in metadata
        if (displayName == null) {
          final authBox = Hive.box(AppConfig.authBoxName);
          final userData = authBox.get(AppConfig.userKey);
          displayName = userData?['display_name'];
        }

        // Set active mode to USER (Login = FETCH, no upload)
        final authBox = Hive.box(AppConfig.authBoxName);
        await authBox.put(AppConfig.activeModeKey, 'user');
        await authBox.put(
            AppConfig.userTokenKey, response.session?.accessToken);

        // Clear user logs/meals/allergens cache (will be replaced by server data)
        final logsBox = Hive.box(AppConfig.logsBoxName);
        final mealsBox = Hive.box(AppConfig.mealsBoxName);
        final allergensBox = Hive.box(AppConfig.allergensBoxName);

        await logsBox.delete(AppConfig.userLogsKey);
        await mealsBox.delete(AppConfig.userMealsKey);
        await allergensBox.delete('selected_ids');

        // Invalidate allergen provider
        _ref.invalidate(selectedAllergenIdsProvider);

        // Log login event
        _ref.read(analyticsServiceProvider).logUserLogin(response.user!.id);

        // FETCH user data from Supabase (Login = FETCH only)
        await _ref.read(dataSyncServiceProvider).fetchUserData();

        state = AsyncValue.data(AuthState(
          isAuthenticated: true,
          hasCompletedOnboarding: hasOnboarded,
          userId: response.user!.id,
          email: response.user!.email,
          displayName: displayName ?? email.split('@').first,
          sessionMode: SessionMode.user,
        ));
      } else {
        state = AsyncValue.error('Giriş başarısız oldu', StackTrace.current);
      }
    } on AuthException catch (e) {
      state =
          AsyncValue.error(_translateAuthError(e.message), StackTrace.current);
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> register(String email, String password,
      {String? displayName, int? age, String? gender, String? guestId}) async {
    state = const AsyncValue.loading();
    try {
      print('🔐 Starting registration for: $email');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          if (displayName != null) 'display_name': displayName,
          if (age != null) 'age': age,
          if (gender != null) 'gender': gender,
        },
      );

      print('🔐 SignUp response received');
      print('🔐 User: ${response.user?.id}');
      print('🔐 Session: ${response.session != null ? "exists" : "null"}');
      print('🔐 User email confirmed: ${response.user?.emailConfirmedAt}');

      // Check if we got a user (email confirmation might be required)
      if (response.user != null) {
        final userId = response.user!.id;
        print('✅ User created with ID: $userId');

        // Store user data locally
        final authBox = Hive.box(AppConfig.authBoxName);
        await authBox.put(AppConfig.userKey, {
          'display_name': displayName ?? email.split('@').first,
          'email': email,
          'user_id': userId,
          'age': age,
        });

        // CRITICAL: Persist active mode and token immediately
        await authBox.put(AppConfig.activeModeKey, 'user');
        if (response.session?.accessToken != null) {
          await authBox.put(
              AppConfig.userTokenKey, response.session!.accessToken);
        }

        // Check if session exists (no email confirmation required)
        if (response.session != null) {
          print('✅ Session created, user can login immediately');

          // Update user profile in database (row already created by trigger)
          try {
            // Wait briefly for trigger to complete (usually instant, but safety first)
            await Future.delayed(const Duration(milliseconds: 500));

            await _supabase.from('users').update({
              'display_name': displayName ?? email.split('@').first,
              'age': age,
              'gender': gender,
            }).eq('id', userId);
            print('✅ User profile updated in public.users');
          } catch (e) {
            print('⚠️ User profile update failed: $e');
            // Continue anyway, user is registered
          }

          // Migrate guest data if guestId provided
          if (guestId != null && guestId.isNotEmpty) {
            try {
              final result = await _supabase.rpc('migrate_guest_data', params: {
                'p_guest_id': guestId,
                'p_new_user_id': userId,
              });
              print('✅ Guest data migrated: $result');

              // Clear local guest_id
              await authBox.delete('guest_id');
            } catch (e) {
              print('⚠️ Guest migration failed: $e');
            }
          }

          // Seed test data for new user (3 days of logs, meals, analytics)
          try {
            final seeder = NewUserDataSeeder(_supabase, userId);
            await seeder.seedAll();
            print('✅ Test data seeded');
          } catch (e) {
            print('⚠️ Seeding failed but registration successful: $e');
          }

          // Log registration event
          _ref.read(analyticsServiceProvider).logUserRegister(userId);

          state = AsyncValue.data(AuthState(
            isAuthenticated: true,
            hasCompletedOnboarding: false,
            userId: userId,
            email: response.user!.email,
            displayName: displayName ?? email.split('@').first,
            sessionMode: SessionMode.user,
          ));
        } else {
          // Email confirmation required
          print('⚠️ Email confirmation required - no session');
          state = AsyncValue.error(
            'Kayıt başarılı! Email adresinize gönderilen linke tıklayarak hesabınızı onaylayın.',
            StackTrace.current,
          );
        }
      } else {
        print('❌ No user returned from signUp');
        state = AsyncValue.error(
            'Kayıt başarısız oldu. Lütfen tekrar deneyin.', StackTrace.current);
      }
    } on AuthException catch (e) {
      print('❌ AuthException: ${e.message}');
      state =
          AsyncValue.error(_translateAuthError(e.message), StackTrace.current);
    } catch (e) {
      print('❌ Exception: $e');
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  /// Translate common auth errors to Turkish
  String _translateAuthError(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'E-posta veya şifre hatalı';
    }
    if (error.contains('User already registered')) {
      return 'Bu e-posta zaten kayıtlı';
    }
    if (error.contains('Password should be at least')) {
      return 'Şifre en az 6 karakter olmalı';
    }
    if (error.contains('Invalid email')) {
      return 'Geçersiz e-posta adresi';
    }
    return error;
  }

  Future<void> completeOnboarding() async {
    final current = state.valueOrNull;
    if (current != null) {
      // Update local storage
      final authBox = Hive.box(AppConfig.authBoxName);
      final userData = authBox.get(AppConfig.userKey) ?? {};
      userData['onboarded'] = true;
      await authBox.put(AppConfig.userKey, userData);

      print(
          '🏁 Completing onboarding. Current state: ${current.sessionMode}, Auth: ${current.isAuthenticated}');

      final newState = current.copyWith(
        hasCompletedOnboarding: true,
        // CRITICAL: Ensure we stay in User Mode (or Guest), never Pending
        sessionMode:
            current.isAuthenticated ? SessionMode.user : SessionMode.guest,
      );
      print(
          '🏁 New state: ${newState.sessionMode}, Auth: ${newState.isAuthenticated}, Onboarded: ${newState.hasCompletedOnboarding}');

      state = AsyncValue.data(newState);
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();

    final authBox = Hive.box(AppConfig.authBoxName);
    // Delete user token but keep guest_id
    await authBox.delete(AppConfig.userTokenKey);
    await authBox.delete(AppConfig.sessionKey);
    await authBox.delete(AppConfig.userKey);

    // Clear user logs/meals/allergens cache
    final logsBox = Hive.box(AppConfig.logsBoxName);
    final mealsBox = Hive.box(AppConfig.mealsBoxName);
    final allergensBox = Hive.box(AppConfig.allergensBoxName);

    await logsBox.delete(AppConfig.userLogsKey);
    await mealsBox.delete(AppConfig.userMealsKey);
    await allergensBox.delete('selected_ids');

    // Set mode to PENDING (user must choose login or guest)
    await authBox.put(AppConfig.activeModeKey, 'pending');

    // Invalidate allergen provider to force refresh from empty Hive box
    _ref.invalidate(selectedAllergenIdsProvider);

    state = const AsyncValue.data(AuthState(
      sessionMode: SessionMode.pending,
    ));
  }

  /// Guest login - creates anonymous user on server (Server-Guest Architecture)
  Future<void> guestLogin() async {
    state = const AsyncValue.loading();
    try {
      // Sign in anonymously with Supabase
      final response = await _supabase.auth.signInAnonymously();

      // Clear any previous session data internally to ensure clean slate
      final logsBox = Hive.box(AppConfig.logsBoxName);
      final mealsBox = Hive.box(AppConfig.mealsBoxName);
      final allergensBox = Hive.box(AppConfig.allergensBoxName);

      await logsBox.delete(AppConfig.userLogsKey);
      await mealsBox.delete(AppConfig.userMealsKey);
      await allergensBox.delete('selected_ids');

      // Invalidate allergen provider to force refresh from empty Hive box
      _ref.invalidate(selectedAllergenIdsProvider);

      if (response.user != null) {
        final userId = response.user!.id;
        print('✅ Anonymous user created: $userId');

        // Set active mode to GUEST
        final authBox = Hive.box(AppConfig.authBoxName);
        await authBox.put(AppConfig.activeModeKey, 'guest');
        await authBox.put(
            AppConfig.userTokenKey, response.session?.accessToken);

        // Ensure user row exists in public.users (Self-healing)
        try {
          await _supabase.from('users').upsert({
            'id': userId,
            'is_guest': true,
            'display_name': 'Misafir',
            'last_active_at': DateTime.now().toIso8601String(),
          });
          print('✅ User row verified/created in public.users');
        } catch (e) {
          print('⚠️ Failed to create user row in public.users: $e');
        }

        // Update last active (Fire and forget)
        try {
          // Verify user exists locally before calling RPC? No, just try.
          await _supabase.rpc('update_last_active');
        } catch (e) {
          print('⚠️ update_last_active failed (non-critical): $e');
        }

        state = AsyncValue.data(AuthState(
          isAuthenticated: true, // Anonymous users are still authenticated
          hasCompletedOnboarding: false,
          userId: userId,
          sessionMode: SessionMode.guest,
        ));
      } else {
        state =
            AsyncValue.error('Misafir girişi başarısız', StackTrace.current);
      }
    } on AuthException catch (e) {
      state =
          AsyncValue.error(_translateAuthError(e.message), StackTrace.current);
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  /// Promote guest account to registered user (keeps all data)
  Future<void> promoteAccount({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Update anonymous user with email/password
      final response = await _supabase.auth.updateUser(
        UserAttributes(
          email: email,
          password: password,
          data: {
            if (displayName != null) 'display_name': displayName,
          },
        ),
      );

      if (response.user != null) {
        // Call promote_account_metadata RPC to update profile
        try {
          await _supabase.rpc('promote_account_metadata', params: {
            'p_display_name': displayName ?? email.split('@').first,
            // age & gender preserved from guest data if not provided
          });
          print('✅ Account promoted successfully');
        } catch (e) {
          print('⚠️ promote_account_metadata RPC failed: $e');
        }

        // Update local storage
        final authBox = Hive.box(AppConfig.authBoxName);
        await authBox.put(AppConfig.activeModeKey, 'user');
        await authBox.put(AppConfig.userKey, {
          'display_name': displayName ?? email.split('@').first,
          'email': email,
          'user_id': response.user!.id,
        });

        // Log promotion event
        _ref.read(analyticsServiceProvider).logUserRegister(response.user!.id);

        state = AsyncValue.data(AuthState(
          isAuthenticated: true,
          hasCompletedOnboarding: true, // Keep onboarding status
          userId: response.user!.id,
          email: email,
          displayName: displayName ?? email.split('@').first,
          sessionMode: SessionMode.user,
        ));
      } else {
        state =
            AsyncValue.error('Hesap yükseltme başarısız', StackTrace.current);
      }
    } on AuthException catch (e) {
      state =
          AsyncValue.error(_translateAuthError(e.message), StackTrace.current);
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  /// Get current session mode from storage
  SessionMode getCurrentMode() {
    final authBox = Hive.box(AppConfig.authBoxName);
    final mode = authBox.get(AppConfig.activeModeKey);
    if (mode == 'user') return SessionMode.user;
    if (mode == 'guest') return SessionMode.guest;
    return SessionMode.pending;
  }

  /// Check if current user is a guest (anonymous)
  bool get isGuest => state.valueOrNull?.sessionMode == SessionMode.guest;
}
