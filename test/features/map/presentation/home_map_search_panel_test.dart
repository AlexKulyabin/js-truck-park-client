import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/map/presentation/home_map_search_panel.dart';
import 'package:j_s_truck_park/features/map/presentation/map_search_result_item.dart';
import 'package:j_s_truck_park/flutter_flow/internationalization.dart';

Widget _buildSubject({
  required TextEditingController textController,
  required FocusNode focusNode,
  List<MapSearchResultItem> results = const [],
  bool isSearching = false,
  bool isFilterApplied = false,
  MapSearchQueryCallback? onQueryChanged,
  VoidCallback? onClear,
  MapSearchResultCallback? onResultSelected,
  MapSearchAsyncAction? onFilterSelected,
  VoidCallback? onProfileSelected,
}) =>
    MaterialApp(
      localizationsDelegates: const [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ru')],
      locale: const Locale('en'),
      theme: ThemeData(brightness: Brightness.light, useMaterial3: false),
      home: Scaffold(
        body: HomeMapSearchPanel(
          maxHeight: 640,
          textController: textController,
          focusNode: focusNode,
          isSearching: isSearching,
          results: results,
          isFilterApplied: isFilterApplied,
          onQueryChanged: onQueryChanged ?? (_) async {},
          onClear: onClear ?? () {},
          onResultSelected: onResultSelected ?? (_) async {},
          onFilterSelected: onFilterSelected ?? () async {},
          onProfileSelected: onProfileSelected ?? () {},
        ),
      ),
    );

void main() {
  late TextEditingController textController;
  late FocusNode focusNode;

  setUp(() {
    textController = TextEditingController();
    focusNode = FocusNode();
  });

  tearDown(() {
    EasyDebounce.cancel(HomeMapSearchPanel.debounceKey);
    textController.dispose();
    focusNode.dispose();
  });

  testWidgets('renders typed results and reports the selected item',
      (tester) async {
    const selected = MapSearchResultItem(
      id: 'parking-1',
      latitude: 52.1,
      longitude: 21.2,
      address: 'Test address',
    );
    const withoutAddress = MapSearchResultItem(
      id: 'parking-2',
      latitude: 52.2,
      longitude: 21.3,
    );
    MapSearchResultItem? reported;

    await tester.pumpWidget(
      _buildSubject(
        textController: textController,
        focusNode: focusNode,
        isSearching: true,
        results: const [selected, withoutAddress],
        onResultSelected: (result) async => reported = result,
      ),
    );

    expect(find.text('Test address'), findsOneWidget);
    expect(find.text('No address'), findsOneWidget);

    await tester.tap(find.text('Test address'));
    await tester.pump();

    expect(reported, selected);
  });

  testWidgets('keeps the existing 500 millisecond debounce', (tester) async {
    final queries = <String>[];
    await tester.pumpWidget(
      _buildSubject(
        textController: textController,
        focusNode: focusNode,
        onQueryChanged: (query) async => queries.add(query),
      ),
    );

    await tester.enterText(
      find.byKey(HomeMapSearchPanel.searchFieldKey),
      'warsaw',
    );
    await tester.pump(const Duration(milliseconds: 499));
    expect(queries, isEmpty);

    await tester.pump(const Duration(milliseconds: 1));
    expect(queries, ['warsaw']);
  });

  testWidgets('keeps clear, filter and profile actions outside the component',
      (tester) async {
    textController.text = 'query';
    var clearCalls = 0;
    var filterCalls = 0;
    var profileCalls = 0;
    await tester.pumpWidget(
      _buildSubject(
        textController: textController,
        focusNode: focusNode,
        isFilterApplied: true,
        onClear: () => clearCalls++,
        onFilterSelected: () async => filterCalls++,
        onProfileSelected: () => profileCalls++,
      ),
    );

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();
    expect(textController.text, isEmpty);
    expect(clearCalls, 1);

    await tester.tap(find.byKey(HomeMapSearchPanel.filterButtonKey));
    await tester.pump();
    expect(clearCalls, 2);
    expect(filterCalls, 1);

    await tester.tap(find.byKey(HomeMapSearchPanel.profileButtonKey));
    await tester.pump();
    expect(profileCalls, 1);
  });
}
