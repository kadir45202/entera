import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';
import '../../data/providers/auth_provider.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/welcome/welcome_screen.dart';
import '../../presentation/screens/onboarding/allergen_selection_screen.dart';
import '../../presentation/screens/meal/meal_capture_screen.dart';
import '../../presentation/screens/meal/meal_result_screen.dart';
import '../../presentation/screens/log/stool_log_screen.dart';
import '../../presentation/screens/log/symptom_log_screen.dart';
import '../../presentation/screens/chat/chat_screen.dart';
import '../../presentation/screens/insights/insights_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      // 1. Loading state - don't redirect yet
      if (authState.isLoading || authState.hasError) return null;

      final hasCompletedOnboarding =
          authState.valueOrNull?.hasCompletedOnboarding ?? false;
      final sessionMode =
          authState.valueOrNull?.sessionMode ?? SessionMode.pending;

      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isOnboardingRoute = state.matchedLocation == '/onboarding';

      // 4. Pending session (Logged out) -> Login
      // Allow auth routes and welcome route
      // 2. Not Authenticated -> Login
      // Allow auth routes (Login/Register)
      if (sessionMode == SessionMode.pending) {
        if (isAuthRoute) return null; // Stay on Login/Register
        return '/login'; // Redirect everything else to Login
      }

      // 5. Authenticated (User/Guest)

      // Explicitly redirect to Home if trying to access Login/Register while logged in
      if (isAuthRoute) {
        return '/home';
      }

      // Check onboarding
      // Priority 1: If onboarding is complete, go to Home (unless explicitly navigating to onboarding)
      if (hasCompletedOnboarding) {
        if (isOnboardingRoute) return '/home'; // Avoid re-onboarding if done
        return null; // Stay where you are (likely Home)
      }

      // Priority 2: If onboarding is NOT complete, force Onboarding (unless already there)
      if (!hasCompletedOnboarding && !isOnboardingRoute) {
        return '/onboarding';
      }

      return null;
    },
    routes: [
      // Welcome screen (first launch)
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const AllergenSelectionScreen(),
      ),

      // Main app
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Meal logging
      GoRoute(
        path: '/meal/capture',
        name: 'mealCapture',
        builder: (context, state) => const MealCaptureScreen(),
      ),
      GoRoute(
        path: '/meal/result',
        name: 'mealResult',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MealResultScreen(analysisResult: extra);
        },
      ),

      // Health logging
      GoRoute(
        path: '/log/stool',
        name: 'stoolLog',
        builder: (context, state) => const StoolLogScreen(),
      ),
      GoRoute(
        path: '/log/symptom',
        name: 'symptomLog',
        builder: (context, state) => const SymptomLogScreen(),
      ),

      // AI Features
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/insights',
        name: 'insights',
        builder: (context, state) => const InsightsScreen(),
      ),

      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
