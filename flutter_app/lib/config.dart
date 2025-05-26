import 'package:flutter/foundation.dart' show kIsWeb;

class Config {
  static String get apiKey => const String.fromEnvironment('FIREBASE_API_KEY');
  static String get appId => const String.fromEnvironment('FIREBASE_APP_ID');
  static String get messagingSenderId => const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static String get projectId => const String.fromEnvironment('FIREBASE_PROJECT_ID');
  static String get authDomain => const String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static String get storageBucket => const String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static String get databaseUrl => const String.fromEnvironment('FIREBASE_DATABASE_URL');
  static String get adminEmail => const String.fromEnvironment('ADMIN_EMAIL');
  static String get adminPassword => const String.fromEnvironment('ADMIN_PASSWORD');

  static void validateConfig() {
    if (kIsWeb) {
      _validateWebConfig();
    } else {
      _validateMobileConfig();
    }
  }

  static void _validateWebConfig() {
    final missingVars = <String>[];
    
    if (apiKey.isEmpty) missingVars.add('FIREBASE_API_KEY');
    if (appId.isEmpty) missingVars.add('FIREBASE_APP_ID');
    if (messagingSenderId.isEmpty) missingVars.add('FIREBASE_MESSAGING_SENDER_ID');
    if (projectId.isEmpty) missingVars.add('FIREBASE_PROJECT_ID');
    if (authDomain.isEmpty) missingVars.add('FIREBASE_AUTH_DOMAIN');
    if (storageBucket.isEmpty) missingVars.add('FIREBASE_STORAGE_BUCKET');
    if (databaseUrl.isEmpty) missingVars.add('FIREBASE_DATABASE_URL');
    if (adminEmail.isEmpty) missingVars.add('ADMIN_EMAIL');
    if (adminPassword.isEmpty) missingVars.add('ADMIN_PASSWORD');

    if (missingVars.isNotEmpty) {
      throw Exception(
        'Missing environment variables for web build:\n${missingVars.join('\n')}\n\n'
        'Make sure to run the app using run_dev.ps1 or build_web.ps1 scripts.'
      );
    }
  }

  static void _validateMobileConfig() {
    final missingVars = <String>[];
    
    if (apiKey.isEmpty) missingVars.add('FIREBASE_API_KEY');
    if (appId.isEmpty) missingVars.add('FIREBASE_APP_ID');
    if (messagingSenderId.isEmpty) missingVars.add('FIREBASE_MESSAGING_SENDER_ID');
    if (projectId.isEmpty) missingVars.add('FIREBASE_PROJECT_ID');
    if (authDomain.isEmpty) missingVars.add('FIREBASE_AUTH_DOMAIN');
    if (storageBucket.isEmpty) missingVars.add('FIREBASE_STORAGE_BUCKET');
    if (databaseUrl.isEmpty) missingVars.add('FIREBASE_DATABASE_URL');
    if (adminEmail.isEmpty) missingVars.add('ADMIN_EMAIL');
    if (adminPassword.isEmpty) missingVars.add('ADMIN_PASSWORD');

    if (missingVars.isNotEmpty) {
      throw Exception(
        'Missing environment variables for mobile build:\n${missingVars.join('\n')}\n\n'
        'Make sure your .env file is properly configured.'
      );
    }
  }
} 