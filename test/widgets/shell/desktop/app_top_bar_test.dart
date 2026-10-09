import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/routes/desktop_top_bar_config.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/shell/desktop/app_top_bar.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  testWidgets('app top bar back button uses xs icon token', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: sakuraThemeData,
          home: const Scaffold(
            body: AppTopBar(
              currentPath: '/desktop/library/movies/ABC-001',
              config: DesktopTopBarConfig(
                title: '影片详情',
                fallbackPath: '/desktop/library/movies',
                isBackEnabled: true,
              ),
            ),
          ),
        ),
      ),
    );

    final backIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('topbar-back-button')),
        matching: find.byIcon(Icons.arrow_back_ios_new_rounded),
      ),
    );
    expect(backIcon.size, AppComponentTokens.defaults().iconSizeXs);
    final tooltip = tester.widget<Tooltip>(
      find.ancestor(
        of: find.byKey(const Key('topbar-back-button')),
        matching: find.byType(Tooltip),
      ),
    );
    expect(tooltip.message, '返回');
  });

  testWidgets('app top bar search and refresh use sm icon token', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: sakuraThemeData,
          home: Scaffold(
            body: AppTopBar(
              currentPath: '/desktop/library/movies',
              config: const DesktopTopBarConfig(
                title: '影片',
                fallbackPath: null,
                isBackEnabled: false,
              ),
              onRefresh: () {},
            ),
          ),
        ),
      ),
    );

    final searchIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('topbar-search-button')),
        matching: find.byIcon(Icons.search_rounded),
      ),
    );
    expect(searchIcon.size, AppComponentTokens.defaults().iconSizeSm);

    final refreshIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('topbar-refresh-button')),
        matching: find.byIcon(Icons.refresh_rounded),
      ),
    );
    expect(refreshIcon.size, AppComponentTokens.defaults().iconSizeSm);
  });

  testWidgets('app top bar hides refresh button when onRefresh is null', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: sakuraThemeData,
          home: const Scaffold(
            body: AppTopBar(
              currentPath: '/desktop/library/movies',
              config: DesktopTopBarConfig(
                title: '影片',
                fallbackPath: null,
                isBackEnabled: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('topbar-refresh-button')), findsNothing);
    expect(
      find.byKey(const Key('topbar-refresh-button-loading')),
      findsNothing,
    );
  });

  testWidgets('app top bar shows refresh button when onRefresh is provided', (
    WidgetTester tester,
  ) async {
    var callCount = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: sakuraThemeData,
          home: Scaffold(
            body: AppTopBar(
              currentPath: '/desktop/library/movies',
              config: const DesktopTopBarConfig(
                title: '影片',
                fallbackPath: null,
                isBackEnabled: false,
              ),
              onRefresh: () => callCount++,
            ),
          ),
        ),
      ),
    );

    final button = find.byKey(const Key('topbar-refresh-button'));
    expect(button, findsOneWidget);
    expect(
      find.descendant(of: button, matching: find.byIcon(Icons.refresh_rounded)),
      findsOneWidget,
    );

    await tester.tap(button);
    await tester.pump();
    expect(callCount, 1);
  });

  testWidgets(
    'app top bar renders spinner when controlled isRefreshing is true',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: sakuraThemeData,
            home: Scaffold(
              body: AppTopBar(
                currentPath: '/desktop/library/movies',
                config: const DesktopTopBarConfig(
                  title: '影片',
                  fallbackPath: null,
                  isBackEnabled: false,
                ),
                onRefresh: () {},
                isRefreshing: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('topbar-refresh-button')), findsNothing);
      expect(
        find.byKey(const Key('topbar-refresh-button-loading')),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  testWidgets(
    'app top bar hides search and refresh when hideActions is true',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: sakuraThemeData,
            home: Scaffold(
              body: AppTopBar(
                currentPath: '/desktop/library/movies/ABC-001',
                config: const DesktopTopBarConfig(
                  title: '影片详情',
                  fallbackPath: '/desktop/library/movies',
                  isBackEnabled: true,
                ),
                onRefresh: () {},
                overlay: true,
                hideActions: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('topbar-search-button')), findsNothing);
      expect(find.byKey(const Key('topbar-refresh-button')), findsNothing);
      // 返回与标题保留。
      expect(find.byKey(const Key('topbar-back-button')), findsOneWidget);
      expect(find.text('影片详情'), findsOneWidget);
    },
  );

  testWidgets(
    'app top bar windows caption follows the overlay backdrop',
    (WidgetTester tester) async {
      const channel = MethodChannel('window_manager');
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        return switch (call.method) {
          'isMaximized' => false,
          _ => null,
        };
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      Future<void> pumpCaption({required bool overlay}) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: sakuraThemeData,
              home: Scaffold(
                body: AppTopBar(
                  currentPath: '/desktop/library/movies/ABC-001',
                  config: const DesktopTopBarConfig(
                    title: '影片详情',
                    fallbackPath: '/desktop/library/movies',
                    isBackEnabled: true,
                  ),
                  overlay: overlay,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      // 沉浸式顶栏只有一层半透明渐变底色（恒为深色），标题栏必须透出它，
      // 并按深色底衬取白色图标——否则浅色主题下黑色图标压在封面上看不见。
      await pumpCaption(overlay: true);
      final overlayCaption = tester.widget<WindowCaption>(
        find.byType(WindowCaption),
      );
      expect(overlayCaption.backgroundColor, Colors.transparent);
      expect(overlayCaption.brightness, Brightness.dark);

      // 常规顶栏有实心底，标题栏保持与顶栏同色，不留透明缺口。
      await pumpCaption(overlay: false);
      final context = tester.element(find.byType(AppTopBar));
      final solidCaption = tester.widget<WindowCaption>(
        find.byType(WindowCaption),
      );
      expect(solidCaption.backgroundColor, context.appColors.surfaceElevated);
      expect(solidCaption.brightness, Theme.of(context).brightness);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}
