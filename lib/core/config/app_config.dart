import 'package:flutter/foundation.dart';

enum AppEnvironment { integration, production }

enum AppWriteOperation {
  favoriteToggle,
  reportCreate,
  reviewCreate,
}

class AppConfig {
  const AppConfig._({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  static const _environmentOverride = String.fromEnvironment('APP_ENV');
  static const _supabaseUrlOverride = String.fromEnvironment('SUPABASE_URL');
  static const _supabasePublishableKeyOverride =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static const _defaultSupabaseUrl = 'https://jckksrcdmhtafwbimzov.supabase.co';
  static const _defaultSupabasePublishableKey =
      'sb_publishable__gyAUoNllJyqH-Tt9LthBA_FPlvIogS';

  static final AppConfig current = AppConfig.resolve(
    isReleaseMode: kReleaseMode,
    environmentOverride: _environmentOverride,
    supabaseUrlOverride: _supabaseUrlOverride,
    supabasePublishableKeyOverride: _supabasePublishableKeyOverride,
  );

  factory AppConfig.resolve({
    required bool isReleaseMode,
    String environmentOverride = '',
    String supabaseUrlOverride = '',
    String supabasePublishableKeyOverride = '',
  }) {
    final environment = switch (environmentOverride.trim().toLowerCase()) {
      '' =>
        isReleaseMode ? AppEnvironment.production : AppEnvironment.integration,
      'integration' => AppEnvironment.integration,
      'production' => AppEnvironment.production,
      final unsupported => throw ArgumentError.value(
          unsupported,
          'environmentOverride',
          'Supported values are integration and production.',
        ),
    };
    final expectedEnvironment =
        isReleaseMode ? AppEnvironment.production : AppEnvironment.integration;
    if (environment != expectedEnvironment) {
      throw StateError(
        '${isReleaseMode ? 'Release' : 'Debug/Profile'} builds must use '
        '${expectedEnvironment.name}.',
      );
    }

    final supabaseUrl = supabaseUrlOverride.trim().isEmpty
        ? _defaultSupabaseUrl
        : supabaseUrlOverride.trim();
    final publishableKey = supabasePublishableKeyOverride.trim().isEmpty
        ? _defaultSupabasePublishableKey
        : supabasePublishableKeyOverride.trim();

    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw ArgumentError.value(
        supabaseUrl,
        'supabaseUrlOverride',
        'Expected an absolute Supabase URL.',
      );
    }
    if (publishableKey.isEmpty) {
      throw ArgumentError(
        'SUPABASE_PUBLISHABLE_KEY must not be empty.',
      );
    }

    return AppConfig._(
      environment: environment,
      supabaseUrl: supabaseUrl,
      supabasePublishableKey: publishableKey,
    );
  }

  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabasePublishableKey;

  bool get isProduction => environment == AppEnvironment.production;
  bool get isIntegration => environment == AppEnvironment.integration;
  bool get integrationReadOnly => isIntegration;
  bool get enableRevenueCat => isProduction;
  bool get enableDeepLinks => isProduction;

  bool canPerformWrite(AppWriteOperation operation) {
    return switch (operation) {
      AppWriteOperation.favoriteToggle => true,
      AppWriteOperation.reportCreate => true,
      AppWriteOperation.reviewCreate => false,
    };
  }

  String get appDisplayName =>
      isProduction ? 'JS Truck Park' : 'JS Truck Park Dev';

  String supabaseRpcUrl(String functionName) =>
      '$supabaseUrl/rest/v1/rpc/$functionName';

  Map<String, String> get anonymousSupabaseHeaders => {
        'apikey': supabasePublishableKey,
        'Authorization': 'Bearer $supabasePublishableKey',
      };

  Map<String, String> authenticatedSupabaseHeaders(String accessToken) {
    final token = accessToken.trim();
    return {
      'apikey': supabasePublishableKey,
      'Authorization':
          'Bearer ${token.isEmpty ? supabasePublishableKey : token}',
    };
  }

  @override
  String toString() => 'AppConfig(environment: ${environment.name})';
}
