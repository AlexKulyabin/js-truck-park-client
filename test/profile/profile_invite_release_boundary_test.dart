import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps the invite action mounted and gates only its callback', () {
    final source = File(
      'lib/profile/profile/profile_widget.dart',
    ).readAsStringSync();

    expect(source, contains('key: ProfileWidget.inviteActionKey'));
    expect(source, contains('.state.showInviteAction'));
    expect(
      source,
      isNot(contains('return const SizedBox.shrink();')),
    );
  });
}
