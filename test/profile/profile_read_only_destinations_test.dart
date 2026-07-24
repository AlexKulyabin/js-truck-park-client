import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('subscription actions stop before RevenueCat in integration mode', () {
    final source = File(
      'lib/subscription/pay_wall/pay_wall_widget.dart',
    ).readAsStringSync();

    expect(
      RegExp(r'if \(AppConfig\.current\.integrationReadOnly\)')
          .allMatches(source)
          .length,
      greaterThanOrEqualTo(3),
    );
    expect(
      source.indexOf('if (AppConfig.current.integrationReadOnly)'),
      lessThan(source.indexOf('actions.getSmartSubscriptionPrices()')),
    );
    expect(
      source,
      matches(
        RegExp(
          r'onPressed: \(\) async \{\s*'
          r'if \(AppConfig\.current\.integrationReadOnly\).*?'
          r'revenue_cat\.restorePurchases\(\)',
          dotAll: true,
        ),
      ),
    );
    expect(
      source,
      matches(
        RegExp(
          r'onPressed: \(\) async \{\s*'
          r'if \(AppConfig\.current\.integrationReadOnly\).*?'
          r'actions\.purchaseSmartPackage\(',
          dotAll: true,
        ),
      ),
    );
  });

  test('favorite navigation may open read-only target details on Home', () {
    final source = File(
      'lib/map/home_page/home_page_widget.dart',
    ).readAsStringSync();
    final targetDetails = source.indexOf('widget.targetParkingId != null');
    final integrationReturn = source.indexOf(
      'if (AppConfig.current.integrationReadOnly)',
      targetDetails,
    );

    expect(targetDetails, greaterThanOrEqualTo(0));
    expect(integrationReturn, greaterThan(targetDetails));
  });

  test('review and complaint reads remain owner-filtered', () {
    final widgetSource = File(
      'lib/reviews/reviews_and_complaints/'
      'reviews_and_complaints_widget.dart',
    ).readAsStringSync();
    final repositorySource = File(
      'lib/features/reviews/data/supabase_user_reviews_repository.dart',
    ).readAsStringSync();

    expect(widgetSource, contains('userId: widget.userId ?? currentUserUid'));
    expect(repositorySource, contains("query.eq('user_id', userId)"));
    expect(repositorySource, contains("query.eq('reporter_id', userId)"));
  });
}
