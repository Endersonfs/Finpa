class AppConstants {
  AppConstants._();

  static const String appName = 'Finpa';
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://api.finpa.com/v1',
  );

  // Local storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
