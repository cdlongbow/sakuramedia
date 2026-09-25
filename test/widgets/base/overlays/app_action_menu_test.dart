import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/overlays/app_action_menu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('popup menu appears near pointer and returns the selection', (
    WidgetTester tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Scaffold(
          body: _SecondaryTapTrigger(
            items: const [
              AppMenuItem(value: 'edit', label: '编辑'),
              AppMenuItem(value: 'delete', label: '删除'),
            ],
            onResult: (value) => selected = value,
          ),
        ),
      ),
    );

    final trigger = find.byKey(const Key('menu-test-trigger'));
    final pointer = tester.getCenter(trigger);
    await tester.tapAt(pointer, buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();

    final menuTopLeft = tester.getTopLeft(find.text('编辑'));
    expect((menuTopLeft - pointer).distance, lessThan(48));

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(selected, 'delete');
  });

  testWidgets('popup menu positions against the root overlay inside a nested '
      'navigator', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: _OffsetNavigatorHost(
          child: const _SecondaryTapTrigger(
            items: [AppMenuItem(value: 'edit', label: '编辑')],
          ),
        ),
      ),
    );

    final trigger = find.byKey(const Key('menu-test-trigger'));
    final pointer = tester.getCenter(trigger);
    await tester.tapAt(pointer, buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();

    final menuTopLeft = tester.getTopLeft(find.text('编辑'));
    expect((menuTopLeft - pointer).distance, lessThan(48));
  });

  testWidgets('invisible items are dropped and an empty menu never opens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Scaffold(
          body: _SecondaryTapTrigger(
            items: const [
              AppMenuItem(value: 'edit', label: '编辑'),
              AppMenuItem(value: 'delete', label: '删除', visible: false),
            ],
          ),
        ),
      ),
    );

    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('menu-test-trigger'))),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(find.text('编辑'), findsOneWidget);
    expect(find.text('删除'), findsNothing);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
  });

  testWidgets('disabled items stay visible but cannot be selected', (
    WidgetTester tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Scaffold(
          body: _SecondaryTapTrigger(
            items: const [
              AppMenuItem(value: 'blocked', label: '屏蔽影片', enabled: false),
            ],
            onResult: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('menu-test-trigger'))),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('屏蔽影片'));
    await tester.pumpAndSettle();

    expect(selected, isNull);
  });

  testWidgets('menu items keep a 4px gap between highlights and no dividers', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Scaffold(
          body: _AutoTrigger(
            items: const [
              AppMenuItem(
                key: Key('menu-row-one'),
                value: 'enter',
                label: '选择',
              ),
              AppMenuItem(
                key: Key('menu-row-two'),
                value: 'blacklist',
                label: '屏蔽影片',
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    Finder highlightOf(String key) => find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(InkWell),
    );
    final first = tester.getRect(highlightOf('menu-row-one'));
    final second = tester.getRect(highlightOf('menu-row-two'));

    expect(first.height, 36);
    expect(second.top - first.bottom, 4);
    expect(find.byType(PopupMenuDivider), findsNothing);
  });

  testWidgets('danger tone renders with the error palette color', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Scaffold(
          body: _SecondaryTapTrigger(
            items: const [
              AppMenuItem(
                value: 'delete',
                label: '删除',
                tone: AppTextTone.error,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('menu-test-trigger'))),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(find.text('删除'));
    expect(text.style?.color, sakuraThemeData.appTextPalette.error);
  });

  testWidgets('default presentation stays a popup on a mobile platform scope', (
    WidgetTester tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      AppPlatformScope(
        platform: AppPlatform.mobile,
        child: MaterialApp(
          theme: sakuraMobileThemeData,
          home: Scaffold(
            body: _AutoTrigger(
              items: const [
                AppMenuItem(value: 'edit', label: '编辑'),
                AppMenuItem(value: 'delete', label: '删除'),
                AppMenuItem(value: 'rename', label: '重命名'),
              ],
              onResult: (value) => selected = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('app-action-menu-drawer')), findsNothing);
    expect(find.text('取消'), findsNothing);

    await tester.tap(find.text('重命名'));
    await tester.pumpAndSettle();

    expect(selected, 'rename');
  });

  testWidgets('popup width follows the widest item within 112..320', (
    WidgetTester tester,
  ) async {
    Future<double> captureWidth(List<AppMenuItem<String>> items) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: sakuraThemeData,
          home: Scaffold(body: _AutoTrigger(items: items)),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final width = tester
          .getSize(
            find
                .ancestor(
                  of: find.text(items.first.label),
                  matching: find.byType(Material),
                )
                .first,
          )
          .width;
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      return width;
    }

    final shortWidth = await captureWidth(const [
      AppMenuItem(value: 'edit', label: '编辑'),
    ]);
    expect(shortWidth, greaterThanOrEqualTo(112));
    expect(shortWidth, lessThan(176));

    final longWidth = await captureWidth(const [
      AppMenuItem(
        value: 'rename',
        label: '这是一个非常非常长的菜单项文案用来验证宽度上限是否生效',
      ),
    ]);
    expect(longWidth, lessThanOrEqualTo(320));
  });

  testWidgets('popup row hover highlight uses the concentric rounded corners', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Scaffold(
          body: _AutoTrigger(
            items: const [
              AppMenuItem(
                key: Key('menu-row-probe'),
                value: 'edit',
                label: '编辑',
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final inkWell = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const Key('menu-row-probe')),
        matching: find.byType(InkWell),
      ),
    );
    expect(inkWell.borderRadius, const AppRadius.defaults().smBorder);
  });

  testWidgets('drawer cancel row dismisses without a selection', (
    WidgetTester tester,
  ) async {
    String? selected = 'untouched';
    await tester.pumpWidget(
      AppPlatformScope(
        platform: AppPlatform.mobile,
        child: MaterialApp(
          theme: sakuraMobileThemeData,
          home: Scaffold(
            body: _AutoTrigger(
              presentation: AppMenuPresentation.bottomDrawer,
              items: const [AppMenuItem(value: 'edit', label: '编辑')],
              onResult: (value) => selected = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(selected, isNull);
    expect(find.byKey(const Key('app-action-menu-drawer')), findsNothing);
  });

  testWidgets('drawer honours item keys, subtitles and titles', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      AppPlatformScope(
        platform: AppPlatform.mobile,
        child: MaterialApp(
          theme: sakuraMobileThemeData,
          home: Scaffold(
            body: _AutoTrigger(
              presentation: AppMenuPresentation.bottomDrawer,
              title: '选集操作',
              items: const [
                AppMenuItem(
                  key: Key('video-episode-action-delete'),
                  value: 'delete',
                  label: '删除选集',
                  subtitle: '删除视频及全部关联媒体',
                  icon: Icons.delete_outline_rounded,
                  tone: AppTextTone.error,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('选集操作'), findsOneWidget);
    expect(find.text('删除视频及全部关联媒体'), findsOneWidget);
    expect(
      find.byKey(const Key('video-episode-action-delete')),
      findsOneWidget,
    );

    final text = tester.widget<Text>(find.text('删除选集'));
    expect(text.style?.color, sakuraMobileThemeData.appTextPalette.error);
  });
}

class _SecondaryTapTrigger extends StatelessWidget {
  const _SecondaryTapTrigger({required this.items, this.onResult});

  final List<AppMenuItem<String>> items;
  final ValueChanged<String?>? onResult;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onSecondaryTapDown: (details) async {
          final result = await showAppActionMenu<String>(
            context: context,
            globalPosition: details.globalPosition,
            presentation: AppMenuPresentation.popup,
            items: items,
          );
          onResult?.call(result);
        },
        child: Container(
          key: const Key('menu-test-trigger'),
          width: 120,
          height: 120,
          color: Colors.blueGrey,
        ),
      ),
    );
  }
}

class _AutoTrigger extends StatelessWidget {
  const _AutoTrigger({
    required this.items,
    this.presentation = AppMenuPresentation.popup,
    this.title,
    this.onResult,
  });

  final List<AppMenuItem<String>> items;
  final AppMenuPresentation presentation;
  final String? title;
  final ValueChanged<String?>? onResult;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Builder(
        builder:
            (context) => TextButton(
              onPressed: () async {
                final result = await showAppActionMenu<String>(
                  context: context,
                  globalPosition: offsetOf(context),
                  presentation: presentation,
                  drawerKey: const Key('app-action-menu-drawer'),
                  title: title,
                  items: items,
                );
                onResult?.call(result);
              },
              child: const Text('open'),
            ),
      ),
    );
  }

  static Offset offsetOf(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return const Offset(200, 200);
    }
    return box.localToGlobal(box.size.center(Offset.zero));
  }
}

class _OffsetNavigatorHost extends StatelessWidget {
  const _OffsetNavigatorHost({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 180, top: 120),
          child: SizedBox(
            width: 420,
            height: 320,
            child: Navigator(
              onGenerateRoute:
                  (_) => MaterialPageRoute<void>(builder: (context) => child),
            ),
          ),
        ),
      ),
    );
  }
}
