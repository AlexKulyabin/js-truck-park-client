import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/auth/registration/referral_invite_card.dart';
import 'package:j_s_truck_park/flutter_flow/internationalization.dart';

Widget _buildSubject(
  ReferralInviteStatus status, {
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
}) =>
    MaterialApp(
      localizationsDelegates: const [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ru')],
      locale: locale,
      theme: ThemeData(useMaterial3: false),
      darkTheme: ThemeData.dark(useMaterial3: false),
      themeMode: themeMode,
      home: Scaffold(
        body: ReferralInviteCard(
          status: status,
          onPressed: () {},
        ),
      ),
    );

void main() {
  testWidgets('explains the benefit before a link is captured', (tester) async {
    await tester.pumpWidget(_buildSubject(ReferralInviteStatus.empty));
    await tester.pump();

    expect(find.text('Have an invite link?'), findsOneWidget);
    expect(
      find.text('Paste it to receive a subscription discount.'),
      findsOneWidget,
    );
    expect(find.text('Paste invite link'), findsOneWidget);
    expect(find.byIcon(Icons.card_giftcard_rounded), findsOneWidget);
  });

  testWidgets('distinguishes automatic detection from a manual link',
      (tester) async {
    await tester.pumpWidget(
      _buildSubject(ReferralInviteStatus.detectedAutomatically),
    );
    await tester.pump();

    expect(find.text('Invite link found'), findsOneWidget);
    expect(
      find.text('It will be verified when you finish registration.'),
      findsOneWidget,
    );
    expect(find.text('Change link'), findsOneWidget);

    await tester.pumpWidget(
      _buildSubject(ReferralInviteStatus.addedManually),
    );
    await tester.pump();

    expect(find.text('Invite link added'), findsOneWidget);
    expect(
      find.text('Your discount will be verified after registration.'),
      findsOneWidget,
    );
  });

  testWidgets('fits Russian copy on a narrow dark screen', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildSubject(
        ReferralInviteStatus.empty,
        locale: const Locale('ru'),
        themeMode: ThemeMode.dark,
      ),
    );
    await tester.pump();

    expect(find.text('Есть пригласительная ссылка?'), findsOneWidget);
    expect(find.text('Вставить пригласительную ссылку'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
