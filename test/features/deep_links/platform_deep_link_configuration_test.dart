import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android delegates link delivery to app_links and ChottuLink', () {
    final gradle = File('android/app/build.gradle').readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();
    final releaseManifest =
        File('android/app/src/release/AndroidManifest.xml').readAsStringSync();

    expect(gradle, contains('flutterDeepLinkingEnabled: "false"'));
    expect(gradle, contains('minSdkVersion 24'));
    expect(releaseManifest, contains('android:scheme="https"'));
    expect(
      releaseManifest,
      contains('android:host="js-truck-park.chottu.link"'),
    );
    expect(
      main.indexOf('initialAppLink = _readInitialAppLink(appLinks);'),
      lessThan(main.indexOf('await SupaFlow.initialize();')),
    );
    expect(main, contains('initialLink: widget.initialAppLink'));
  });

  test('Android does not restore transient identity or attribution state', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final legacyRules = File('android/app/src/main/res/xml/backup_rules.xml')
        .readAsStringSync();
    final modernRules = File(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    ).readAsStringSync();
    final activity = File(
      'android/app/src/main/kotlin/com/example/my_project/MainActivity.kt',
    ).readAsStringSync();

    expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
    for (final rules in [legacyRules, modernRules]) {
      expect(rules, contains('path="chottu_prefs.xml"'));
      expect(rules, contains('path="FlutterSharedPreferences.xml"'));
    }
    expect(activity, contains('File(noBackupFilesDir, INSTALL_STATE_MARKER)'));
    expect(activity, contains('CHOTTU_PREFERENCES'));
    expect(activity, contains('if (isFreshInstall())'));
    expect(activity, contains('FLUTTER_PREFERENCES'));
  });

  test('iOS release declares the Chottu universal-link association', () {
    final info = File('ios/Runner/Info.plist').readAsStringSync();
    final entitlements =
        File('ios/Runner/Runner.entitlements').readAsStringSync();
    final project =
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    const releaseConfigurationId = '97C147071CF9000F007C117D';
    final releaseStart = project.indexOf(
      '$releaseConfigurationId /* Release */ = {',
    );
    final releaseEnd = project.indexOf('\n\t\t};', releaseStart);

    expect(releaseStart, isNonNegative);
    expect(releaseEnd, greaterThan(releaseStart));
    final releaseConfiguration = project.substring(releaseStart, releaseEnd);

    expect(
      info,
      contains('<key>FlutterDeepLinkingEnabled</key>\n    <false/>'),
    );
    expect(
      entitlements,
      contains('applinks:js-truck-park.chottu.link'),
    );
    expect(
      releaseConfiguration,
      contains('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'),
    );
    expect(
      releaseConfiguration,
      contains('DEVELOPMENT_TEAM = 8XNBY3768H;'),
    );
  });
}
