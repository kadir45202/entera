/// Session mode for dual session architecture
enum SessionMode {
  guest, // Using app as guest
  user, // Logged in user
  pending, // Logged out, needs to choose
}

/// App configuration constants
class AppConfig {
  AppConfig._();

  /// Supabase configuration
  /// These will be loaded from .env file
  static String supabaseUrl = const String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static String supabaseAnonKey = const String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// App name
  static const String appName = 'Entera';

  /// Local storage keys - General
  static const String authBoxName = 'auth';
  static const String mealsBoxName = 'meals';
  static const String logsBoxName = 'logs';
  static const String allergensBoxName = 'allergens';
  static const String syncQueueBoxName = 'sync_queue';

  /// Auth box keys
  static const String sessionKey = 'supabase_session';
  static const String userKey = 'user_data';
  static const String guestIdKey = 'guest_id'; // Permanent guest ID
  static const String activeModeKey = 'active_mode'; // GUEST, USER, PENDING
  static const String userTokenKey = 'user_token'; // User access token

  /// Partitioned storage keys (for dual session)
  static const String guestLogsKey = 'guest_logs';
  static const String userLogsKey = 'user_logs';
  static const String guestMealsKey = 'guest_meals';
  static const String userMealsKey = 'user_meals';

  /// Correlation window (hours)
  static const int correlationWindowHours = 4;

  /// Initialize from environment
  static void initialize({
    required String url,
    required String anonKey,
  }) {
    supabaseUrl = url;
    supabaseAnonKey = anonKey;
  }
}
