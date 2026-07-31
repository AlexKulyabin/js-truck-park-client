import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

void main() {
  const iconDirectory = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

  test('iOS app icons use the generated branded assets', () {
    final contents = jsonDecode(
      File('$iconDirectory/Contents.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final entries = contents['images'] as List<dynamic>;

    for (final rawEntry in entries) {
      final entry = rawEntry as Map<String, dynamic>;
      final filename = entry['filename'] as String;
      final logicalSize = double.parse(
        (entry['size'] as String).split('x').first,
      );
      final scale =
          double.parse((entry['scale'] as String).replaceAll('x', ''));
      final expectedPixels = (logicalSize * scale).round();
      final path = '$iconDirectory/$filename';
      final decoded = image.decodePng(File(path).readAsBytesSync());

      expect(decoded, isNotNull, reason: path);
      expect(decoded!.width, expectedPixels, reason: path);
      expect(decoded.height, expectedPixels, reason: path);
    }

    final marketingIcon = File(
      '$iconDirectory/Icon-App-1024x1024@1x.png',
    ).readAsBytesSync();
    expect(
      marketingIcon.length,
      greaterThan(100000),
      reason: 'The App Store icon must not regress to the Flutter placeholder.',
    );
  });
}
