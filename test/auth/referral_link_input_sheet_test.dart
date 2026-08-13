import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/auth/registration/referral_link_input_sheet.dart';
import 'package:j_s_truck_park/flutter_flow/internationalization.dart';

Widget _buildSubject(Future<bool> Function(String) captureLink) => MaterialApp(
      localizationsDelegates: const [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ru')],
      locale: const Locale('en'),
      theme: ThemeData(useMaterial3: false),
      home: Scaffold(
        body: ReferralLinkInputSheet(captureLink: captureLink),
      ),
    );

void main() {
  testWidgets('renders a stable invite-link input surface', (tester) async {
    await tester.pumpWidget(_buildSubject((_) async => false));
    await tester.pump();

    expect(find.text('Invite link'), findsNWidgets(2));
    expect(
      find.text('Paste the full link sent to you by a friend.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.content_paste_rounded), findsOneWidget);
    expect(find.text('Paste from clipboard'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('validates the link through the injected capture boundary',
      (tester) async {
    String? submittedLink;
    await tester.pumpWidget(
      _buildSubject((link) async {
        submittedLink = link;
        return false;
      }),
    );
    await tester.enterText(
      find.byType(TextField),
      '  https://js-truck-park.chottu.link/test  ',
    );
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(submittedLink, 'https://js-truck-park.chottu.link/test');
    expect(find.text('The invite link is invalid'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
