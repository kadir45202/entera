import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/theme/theme.dart';
import 'core/router/router.dart';
import 'data/database_seeder.dart';
import 'data/services/analytics_service.dart';
import 'data/services/sync_manager.dart';

// Global container for analytics access
late ProviderContainer _container;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Store config for reference
  AppConfig.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Open Hive boxes
  await Hive.openBox(AppConfig.authBoxName);
  await Hive.openBox(AppConfig.mealsBoxName);
  await Hive.openBox(AppConfig.logsBoxName);
  await Hive.openBox(AppConfig.allergensBoxName);
  await Hive.openBox(AppConfig.syncQueueBoxName);

  // Seed test data if database is empty
  await DatabaseSeeder.seedIfEmpty();

  // Create provider container
  _container = ProviderContainer();

  // Log app start
  _container.read(analyticsServiceProvider).logAppStart();

  // Initialize SyncManager
  _container.read(syncManagerProvider);

  // Handle Flutter errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _container.read(analyticsServiceProvider).logAppError(
          details.exceptionAsString(),
          stackTrace: details.stack?.toString(),
        );
  };

  runApp(
    UncontrolledProviderScope(
      container: _container,
      child: const EnteraApp(),
    ),
  );
}

class EnteraApp extends ConsumerWidget {
  const EnteraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: EnteraTheme.light,
      routerConfig: router,
    );
  }
}
