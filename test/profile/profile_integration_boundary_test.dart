import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps destructive profile actions outside integration builds', () {
    final source = File(
      'lib/profile/log_out_dialog_copy/log_out_dialog_copy_widget.dart',
    ).readAsStringSync();

    expect(source, contains("import '/core/config/app_config.dart';"));
    expect(
      source,
      contains('if (AppConfig.current.integrationReadOnly)'),
    );
    expect(
      source.indexOf('if (AppConfig.current.integrationReadOnly)'),
      lessThan(source.indexOf('DeleteUserAccountCall.call')),
    );
  });
}
