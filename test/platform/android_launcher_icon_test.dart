import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

void main() {
  const launcherIcons = <String, int>{
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
  };

  test('Android launcher icons use the generated branded assets', () {
    for (final entry in launcherIcons.entries) {
      final bytes = File(entry.key).readAsBytesSync();
      final decoded = image.decodePng(bytes);

      expect(decoded, isNotNull, reason: entry.key);
      expect(decoded!.width, entry.value, reason: entry.key);
      expect(decoded.height, entry.value, reason: entry.key);
      expect(
        bytes.length,
        greaterThan(entry.value * 50),
        reason: '${entry.key} must not regress to the default Flutter icon',
      );
    }
  });
}
