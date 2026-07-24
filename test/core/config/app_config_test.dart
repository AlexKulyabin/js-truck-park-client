import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('defaults non-release builds to read-only integration mode', () {
      final config = AppConfig.resolve(isReleaseMode: false);

      expect(config.environment, AppEnvironment.integration);
      expect(config.integrationReadOnly, isTrue);
      expect(config.enableRevenueCat, isFalse);
      expect(config.enableDeepLinks, isFalse);
      expect(
        config.canPerformWrite(AppWriteOperation.favoriteToggle),
        isTrue,
      );
      expect(
        config.canPerformWrite(AppWriteOperation.reportCreate),
        isTrue,
      );
      expect(config.appDisplayName, 'JS Truck Park Dev');
    });

    test('defaults release builds to production behavior', () {
      final config = AppConfig.resolve(isReleaseMode: true);

      expect(config.environment, AppEnvironment.production);
      expect(config.integrationReadOnly, isFalse);
      expect(config.enableRevenueCat, isTrue);
      expect(config.enableDeepLinks, isTrue);
      expect(
        config.canPerformWrite(AppWriteOperation.favoriteToggle),
        isTrue,
      );
      expect(
        config.canPerformWrite(AppWriteOperation.reportCreate),
        isTrue,
      );
      expect(config.appDisplayName, 'JS Truck Park');
    });

    test('supports explicit integration and endpoint overrides', () {
      final config = AppConfig.resolve(
        isReleaseMode: false,
        environmentOverride: 'integration',
        supabaseUrlOverride: 'https://example.supabase.co',
        supabasePublishableKeyOverride: 'sb_publishable_test',
      );

      expect(config.isIntegration, isTrue);
      expect(
        config.supabaseRpcUrl('read_something'),
        'https://example.supabase.co/rest/v1/rpc/read_something',
      );
      expect(config.anonymousSupabaseHeaders['apikey'], 'sb_publishable_test');
    });

    test('builds authenticated Supabase headers with a user token', () {
      final config = AppConfig.resolve(
        isReleaseMode: false,
        supabasePublishableKeyOverride: 'sb_publishable_test',
      );

      expect(
        config.authenticatedSupabaseHeaders('user-jwt'),
        {
          'apikey': 'sb_publishable_test',
          'Authorization': 'Bearer user-jwt',
        },
      );
    });

    test('rejects an unknown environment', () {
      expect(
        () => AppConfig.resolve(
          isReleaseMode: false,
          environmentOverride: 'preview',
        ),
        throwsArgumentError,
      );
    });

    test('rejects integration mode for a release build', () {
      expect(
        () => AppConfig.resolve(
          isReleaseMode: true,
          environmentOverride: 'integration',
        ),
        throwsStateError,
      );
    });

    test('rejects production mode for a non-release build', () {
      expect(
        () => AppConfig.resolve(
          isReleaseMode: false,
          environmentOverride: 'production',
        ),
        throwsStateError,
      );
    });

    test('does not expose the publishable key from diagnostics', () {
      final config = AppConfig.resolve(
        isReleaseMode: false,
        supabasePublishableKeyOverride: 'sb_publishable_sensitive_value',
      );

      expect(config.toString(), isNot(contains('sensitive_value')));
    });
  });
}
