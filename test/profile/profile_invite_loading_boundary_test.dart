import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('opens the invite dialog before loading the referral link', () {
    final profileSource = File(
      'lib/profile/profile/profile_widget.dart',
    ).readAsStringSync();
    final dialogSource = File(
      'lib/profile/invite_friends_dialog/invite_friends_dialog_widget.dart',
    ).readAsStringSync();

    expect(profileSource, contains('InviteFriendsDialogWidget('));
    expect(profileSource, contains('linkLoader: () async'));
    expect(
        dialogSource, contains('final Future<String> Function()? linkLoader'));
    expect(dialogSource, contains('CircularProgressIndicator('));
    expect(dialogSource, contains('if (_isLoading)'));
    expect(dialogSource, contains('onPressed: _hasLink'));
  });
}
