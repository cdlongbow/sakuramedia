import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sakuramedia/app/appearance_store.dart';
import 'package:sakuramedia/app/providers/app_shell_providers.dart';
import 'package:sakuramedia/app/providers/appearance_providers.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/shell/desktop/sidebar_appearance_menu.dart';

void main() {
  testWidgets('侧栏模式图标按系统 → 浅色 → 深色循环', (WidgetTester tester) async {
    final container = await _pumpMenu(tester);

    expect(container.read(appearanceProvider).themeMode, ThemeMode.system);
    expect(find.byIcon(Icons.contrast_rounded), findsOneWidget);

    await tester.tap(find.byKey(const Key('sidebar-appearance-mode-toggle')));
    await tester.pumpAndSettle();
    expect(container.read(appearanceProvider).themeMode, ThemeMode.light);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);

    await tester.tap(find.byKey(const Key('sidebar-appearance-mode-toggle')));
    await tester.pumpAndSettle();
    expect(container.read(appearanceProvider).themeMode, ThemeMode.dark);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);

    await tester.tap(find.byKey(const Key('sidebar-appearance-mode-toggle')));
    await tester.pumpAndSettle();
    expect(container.read(appearanceProvider).themeMode, ThemeMode.system);
    expect(find.byIcon(Icons.contrast_rounded), findsOneWidget);
  });

  testWidgets('侧栏主题色浮窗悬停不抛异常，选色后自动收起', (WidgetTester tester) async {
    final container = await _pumpMenu(tester);

    await tester.tap(find.byKey(const Key('sidebar-theme-color-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('sidebar-theme-color-popover')),
      findsOneWidget,
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(
      tester.getCenter(find.byKey(const Key('sidebar-theme-color-klein-blue'))),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('sidebar-theme-color-klein-blue')));
    await tester.pumpAndSettle();

    expect(
      container.read(appearanceProvider).themeColor.id,
      AppThemeColor.kleinBlueId,
    );
    expect(find.byKey(const Key('sidebar-theme-color-popover')), findsNothing);
  });

  testWidgets('侧栏主题色浮窗支持点外部、Esc 与收起侧栏关闭', (WidgetTester tester) async {
    final container = await _pumpMenu(tester);

    Future<void> open() async {
      await tester.tap(find.byKey(const Key('sidebar-theme-color-button')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('sidebar-theme-color-popover')),
        findsOneWidget,
      );
    }

    await open();
    await tester.tapAt(const Offset(700, 200));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sidebar-theme-color-popover')), findsNothing);

    await open();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sidebar-theme-color-popover')), findsNothing);

    await open();
    container.read(appShellSidebarCollapsedProvider.notifier).toggle();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sidebar-theme-color-popover')), findsNothing);
  });
}

Future<ProviderContainer> _pumpMenu(WidgetTester tester) async {
  final store = InMemoryAppearanceStore();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [appearanceStoreProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildSakuraDesktopThemeData(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomLeft,
            child: SizedBox(
              width: AppSidebarTokens.defaults().expandedWidth,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: SidebarAppearanceMenu(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return container;
}
