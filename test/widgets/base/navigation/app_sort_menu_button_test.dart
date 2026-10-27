import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/shared/data/sort_direction.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/navigation/app_list_header.dart';
import 'package:sakuramedia/widgets/base/navigation/app_sort_menu_button.dart';

enum _TestSortField { title, heat }

/// 测试树的本地化 delegate：ARB 文案 + material_ui 的 Material/Cupertino 文案。
const List<LocalizationsDelegate<dynamic>> _testLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ];

void main() {
  Widget buildButton({
    required _TestSortField? selectedField,
    required ValueChanged<_TestSortField?> onFieldChanged,
    required ValueChanged<SortDirection> onDirectionChanged,
    SortDirection selectedDirection = SortDirection.desc,
    bool useDrawer = false,
    bool allowDefaultOption = false,
    bool Function(_TestSortField?)? directionVisibleWhen,
    Key? triggerKey,
    Key? panelKey,
    Key? drawerKey,
  }) {
    return AppSortMenuButton<_TestSortField>(
      fields: _TestSortField.values,
      selectedField: selectedField,
      fieldLabelBuilder: (value) => switch (value) {
        _TestSortField.title => '标题',
        _TestSortField.heat => '热度',
      },
      onFieldChanged: onFieldChanged,
      selectedDirection: selectedDirection,
      onDirectionChanged: onDirectionChanged,
      useDrawer: useDrawer,
      allowDefaultOption: allowDefaultOption,
      defaultOptionLabel: '默认排序',
      directionVisibleWhen: directionVisibleWhen,
      triggerKey: triggerKey,
      panelKey: panelKey,
      drawerKey: drawerKey,
    );
  }

  testWidgets('桌面排序入口打开浮层，选中字段后应用并关闭', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    _TestSortField? selectedField = _TestSortField.title;
    var selectedDirection = SortDirection.desc;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: _testLocalizationsDelegates,
        supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
        theme: sakuraThemeData,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: SizedBox(
              height: 44,
              child: StatefulBuilder(
                builder: (context, setState) => buildButton(
                  selectedField: selectedField,
                  onFieldChanged: (value) =>
                      setState(() => selectedField = value),
                  onDirectionChanged: (value) =>
                      setState(() => selectedDirection = value),
                  selectedDirection: selectedDirection,
                  triggerKey: const Key('test-sort-trigger'),
                  panelKey: const Key('test-sort-panel'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('test-sort-trigger')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('test-sort-panel')), findsOneWidget);
    expect(find.text('排序方式'), findsOneWidget);
    expect(find.text('标题 ↓'), findsOneWidget);

    await tester.tap(find.text('热度'));
    await tester.pumpAndSettle();

    expect(selectedField, _TestSortField.heat);
    expect(find.byKey(const Key('test-sort-panel')), findsNothing);
    expect(find.text('热度 ↓'), findsOneWidget);
  });

  testWidgets('移动排序入口用底部抽屉承载，选中方向后应用并关闭', (tester) async {
    _TestSortField? selectedField = _TestSortField.title;
    var selectedDirection = SortDirection.desc;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: _testLocalizationsDelegates,
        supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
        theme: sakuraThemeData,
        home: Scaffold(
          body: SizedBox(
            height: 44,
            child: StatefulBuilder(
              builder: (context, setState) => buildButton(
                selectedField: selectedField,
                onFieldChanged: (value) =>
                    setState(() => selectedField = value),
                onDirectionChanged: (value) =>
                    setState(() => selectedDirection = value),
                selectedDirection: selectedDirection,
                useDrawer: true,
                triggerKey: const Key('test-sort-trigger'),
                drawerKey: const Key('test-sort-drawer'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('test-sort-trigger')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('test-sort-drawer')), findsOneWidget);

    await tester.tap(find.text('升序'));
    await tester.pumpAndSettle();

    expect(selectedDirection, SortDirection.asc);
    expect(find.byKey(const Key('test-sort-drawer')), findsNothing);
  });

  testWidgets('可空排序提供默认项，选中默认后隐藏方向分节', (tester) async {
    _TestSortField? selectedField = _TestSortField.heat;
    var selectedDirection = SortDirection.desc;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: _testLocalizationsDelegates,
        supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
        theme: sakuraThemeData,
        home: Scaffold(
          body: SizedBox(
            height: 44,
            child: StatefulBuilder(
              builder: (context, setState) => buildButton(
                selectedField: selectedField,
                onFieldChanged: (value) =>
                    setState(() => selectedField = value),
                onDirectionChanged: (value) =>
                    setState(() => selectedDirection = value),
                selectedDirection: selectedDirection,
                allowDefaultOption: true,
                directionVisibleWhen: (field) => field != null,
                triggerKey: const Key('test-sort-trigger'),
                panelKey: const Key('test-sort-panel'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('热度 ↓'), findsOneWidget);

    await tester.tap(find.byKey(const Key('test-sort-trigger')));
    await tester.pumpAndSettle();

    expect(find.text('升序'), findsOneWidget);
    expect(find.text('降序'), findsOneWidget);

    await tester.tap(find.text('默认排序'));
    await tester.pumpAndSettle();

    expect(selectedField, isNull);
    expect(find.text('默认排序'), findsOneWidget);
    expect(find.byKey(const Key('test-sort-panel')), findsNothing);
  });

  testWidgets('360 宽顶栏里筛选、总数与排序入口同屏可见', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: _testLocalizationsDelegates,
        supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
        theme: sakuraThemeData,
        home: Scaffold(
          body: AppListHeader(
            filterButtonKey: const Key('mobile-filter-trigger'),
            filterLabel: '2026 等 3 个年份',
            filterTooltip: '筛选',
            onFilterTap: () {},
            informationSlots: const [AppListHeaderInfo(label: '1,268 部')],
            actionSlots: [
              buildButton(
                selectedField: _TestSortField.title,
                onFieldChanged: (_) {},
                onDirectionChanged: (_) {},
                useDrawer: true,
                triggerKey: const Key('mobile-sort-trigger'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final sortRect = tester.getRect(
      find.byKey(const Key('mobile-sort-trigger')),
    );
    expect(sortRect.left, greaterThanOrEqualTo(0));
    expect(sortRect.right, lessThanOrEqualTo(360));
  });
}
