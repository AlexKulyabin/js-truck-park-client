import 'package:flutter/foundation.dart';

enum AppEnvironment { integration, production }

enum AppWriteOperation {
  favoriteToggle,
  profileUpdate,
  reportCreate,
  reviewCreate,
  reviewUpdate,
  reviewDelete,
  reviewPhotoManage,
}

class AppConfig {
  const AppConfig._({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.testWritesEnabled,
  });

  static const _environmentOverride = String.fromEnvironment('APP_ENV');
  static const _supabaseUrlOverride = String.fromEnvironment('SUPABASE_URL');
  static const _supabasePublishableKeyOverride =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const _testWritesOverride =
      String.fromEnvironment('APP_ENABLE_TEST_WRITES');

  static const _defaultSupabaseUrl = 'https://jckksrcdmhtafwbimzov.supabase.co';
  static const _defaultSupabasePublishableKey =
      'sb_publishable__gyAUoNllJyqH-Tt9LthBA_FPlvIogS';

  static final AppConfig current = AppConfig.resolve(
    isReleaseMode: kReleaseMode,
    environmentOverride: _environmentOverride,
    supabaseUrlOverride: _supabaseUrlOverride,
    supabasePublishableKeyOverride: _supabasePublishableKeyOverride,
    testWritesOverride: _testWritesOverride,
  );

  factory AppConfig.resolve({
    required bool isReleaseMode,
    String environmentOverride = '',
    String supabaseUrlOverride = '',
    String supabasePublishableKeyOverride = '',
    String testWritesOverride = '',
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
    final testWritesEnabled = _parseBoolDefine(
      testWritesOverride,
      name: 'APP_ENABLE_TEST_WRITES',
    );
    if (testWritesEnabled) {
      if (isReleaseMode) {
        throw StateError(
          'Test writes can only be enabled for Debug/Profile builds.',
        );
      }
      if (_isProductionSupabaseUrl(supabaseUrl)) {
        throw StateError(
          'Test writes require a non-production Supabase URL.',
        );
      }
    }

    return AppConfig._(
      environment: environment,
      supabaseUrl: supabaseUrl,
      supabasePublishableKey: publishableKey,
      testWritesEnabled: testWritesEnabled,
    );
  }

  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabasePublishableKey;
  final bool testWritesEnabled;

  bool get isProduction => environment == AppEnvironment.production;
  bool get isIntegration => environment == AppEnvironment.integration;
  bool get integrationReadOnly => isIntegration;
  bool get enableRevenueCat => isProduction;
  bool get enableDeepLinks => isProduction;
  bool get enableReferrals => isProduction;

  bool canPerformWrite(AppWriteOperation operation) {
    return switch (operation) {
      AppWriteOperation.favoriteToggle => true,
      AppWriteOperation.profileUpdate => false,
      AppWriteOperation.reportCreate => true,
      AppWriteOperation.reviewCreate => testWritesEnabled,
      AppWriteOperation.reviewUpdate => testWritesEnabled,
      AppWriteOperation.reviewDelete => testWritesEnabled,
      AppWriteOperation.reviewPhotoManage => testWritesEnabled,
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

bool _parseBoolDefine(String value, {required String name}) {
  return switch (value.trim().toLowerCase()) {
    '' || 'false' || '0' => false,
    'true' || '1' => true,
    final unsupported => throw ArgumentError.value(
        unsupported,
        name,
        'Supported values are true/false or 1/0.',
      ),
  };
}

bool _isProductionSupabaseUrl(String supabaseUrl) {
  final configuredHost = Uri.parse(supabaseUrl).host;
  final productionHost = Uri.parse(AppConfig._defaultSupabaseUrl).host;
  return configuredHost == productionHost;
}
