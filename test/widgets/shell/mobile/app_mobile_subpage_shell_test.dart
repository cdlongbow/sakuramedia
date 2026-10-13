import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/shell/mobile/app_mobile_subpage_shell.dart';

void main() {
  testWidgets('mobile subpage shell renders app bar title and no bottom nav', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: const AppMobileSubpageShell(
          title: '播放列表详情',
          defaultLocation: '/mobile/overview',
          child: SizedBox.shrink(),
        ),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final rootSurface = tester.widget<ColoredBox>(
      find.byKey(const Key('mobile-subpage-root-surface')),
    );
    final overlayStyle =
        tester
            .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
              find.byKey(const Key('mobile-subpage-system-overlay')),
            )
            .value;

    expect(find.byKey(const Key('mobile-subpage-safe-area')), findsOneWidget);
    expect(find.byKey(const Key('mobile-subpage-topbar')), findsOneWidget);
    expect(find.text('播放列表详情'), findsOneWidget);
    final titleText = tester.widget<Text>(find.text('播放列表详情'));
    expect(titleText.style?.fontSize, sakuraThemeData.appTextScale.s14);
    expect(rootSurface.color, sakuraThemeData.appColors.surfaceCard);
    expect(scaffold.backgroundColor, sakuraThemeData.appColors.surfaceCard);
    expect(appBar.backgroundColor, sakuraThemeData.appColors.surfaceCard);
    expect(overlayStyle.statusBarColor, sakuraThemeData.appColors.surfaceCard);
    expect(overlayStyle.statusBarIconBrightness, Brightness.dark);
    expect(overlayStyle.statusBarBrightness, Brightness.light);
    expect(
      overlayStyle.systemNavigationBarColor,
      sakuraThemeData.appColors.surfaceCard,
    );
    expect(overlayStyle.systemNavigationBarIconBrightness, Brightness.dark);
    expect(
      overlayStyle.systemNavigationBarDividerColor,
      sakuraThemeData.appColors.divider,
    );
    expect(find.byKey(const Key('mobile-bottom-navigation')), findsNothing);
  });

  testWidgets('mobile subpage shell back pops when route stack exists', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder:
              (context, state) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => context.push('/sub'),
                    child: const Text('open-sub'),
                  ),
                ),
              ),
        ),
        ShellRoute(
          builder:
              (context, state, child) => AppMobileSubpageShell(
                title: '子页面',
                defaultLocation: '/home',
                child: child,
              ),
          routes: [
            GoRoute(
              path: '/sub',
              builder:
                  (_, __) => const Scaffold(
                    body: Text('sub-page', textDirection: TextDirection.ltr),
                  ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: sakuraThemeData, routerConfig: router),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open-sub'));
    await tester.pumpAndSettle();
    expect(find.text('sub-page'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mobile-subpage-back-button')));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/home');
  });

  testWidgets('mobile subpage shell system back pops when route stack exists', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder:
              (context, state) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => context.push('/sub'),
                    child: const Text('open-sub'),
                  ),
                ),
              ),
        ),
        ShellRoute(
          builder:
              (context, state, child) => AppMobileSubpageShell(
                title: '子页面',
                defaultLocation: '/home',
                child: child,
              ),
          routes: [
            GoRoute(
              path: '/sub',
              builder:
                  (_, __) => const Scaffold(
                    body: Text('sub-page', textDirection: TextDirection.ltr),
                  ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: sakuraThemeData, routerConfig: router),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open-sub'));
    await tester.pumpAndSettle();
    expect(find.text('sub-page'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/home');
  });

  testWidgets('mobile subpage shell back uses fallback on deep link', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/sub',
      routes: [
        GoRoute(
          path: '/home',
          builder:
              (_, __) => const Scaffold(
                body: Text('home-page', textDirection: TextDirection.ltr),
              ),
        ),
        ShellRoute(
          builder:
              (context, state, child) => AppMobileSubpageShell(
                title: '子页面',
                defaultLocation: '/home',
                child: child,
              ),
          routes: [
            GoRoute(
              path: '/sub',
              builder:
                  (_, __) => const Scaffold(
                    body: Text('sub-page', textDirection: TextDirection.ltr),
                  ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: sakuraThemeData, routerConfig: router),
    );
    await tester.pumpAndSettle();

    expect(find.text('sub-page'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mobile-subpage-back-button')));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/home');
    expect(find.text('home-page'), findsOneWidget);
  });

  testWidgets('mobile subpage shell system back uses fallback on deep link', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/sub',
      routes: [
        GoRoute(
          path: '/home',
          builder:
              (_, __) => const Scaffold(
                body: Text('home-page', textDirection: TextDirection.ltr),
              ),
        ),
        ShellRoute(
          builder:
              (context, state, child) => AppMobileSubpageShell(
                title: '子页面',
                defaultLocation: '/home',
                child: child,
              ),
          routes: [
            GoRoute(
              path: '/sub',
              builder:
                  (_, __) => const Scaffold(
                    body: Text('sub-page', textDirection: TextDirection.ltr),
                  ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: sakuraThemeData, routerConfig: router),
    );
    await tester.pumpAndSettle();

    expect(find.text('sub-page'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/home');
    expect(find.text('home-page'), findsOneWidget);
  });

  testWidgets('mobile subpage shell applies custom body padding', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: AppMobileSubpageShell(
          title: '子页面',
          defaultLocation: '/home',
          bodyPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Container(key: const Key('subpage-body-child')),
        ),
      ),
    );

    final bodyPadding = tester.widget<Padding>(
      find.byKey(const Key('mobile-subpage-body-padding')),
    );

    expect(
      bodyPadding.padding,
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  });

  testWidgets('mobile subpage shell keeps title and bleeds to the bottom edge', (
    tester,
  ) async {
    // 底部安全区不再由外壳留：内容铺到屏幕物理底边，由滚动层/贴底条自己补留白。
    // 修前这里 body 底边停在「屏幕高 - 34」，底部会露出未绘制的黑带。
    await _pumpShellWithBottomInset(
      tester,
      const AppMobileSubpageShell(
        title: '播放列表详情',
        defaultLocation: '/mobile/overview',
        child: SizedBox.shrink(),
      ),
    );

    expect(find.text('播放列表详情'), findsOneWidget);
    expect(
      tester.getRect(find.byType(Scaffold)).bottom,
      moreOrLessEquals(_kTestScreenHeight),
    );
  });

  testWidgets('immersive mobile subpage shell drops the title bar text', (
    tester,
  ) async {
    await _pumpShellWithBottomInset(
      tester,
      const AppMobileSubpageShell(
        title: '影片详情',
        defaultLocation: '/mobile/overview',
        immersive: true,
        child: SizedBox.shrink(),
      ),
    );

    // 沉浸详情不占标题位：只留返回键和顶栏渐变。
    expect(find.byKey(const Key('mobile-subpage-title')), findsNothing);
    expect(
      find.byKey(const Key('mobile-subpage-back-button')),
      findsOneWidget,
    );
    expect(
      tester.getRect(find.byType(Scaffold)).bottom,
      moreOrLessEquals(_kTestScreenHeight),
    );
  });

  testWidgets('裸 ListView 子页靠 Flutter 自动补齐底部安全区', (
    tester,
  ) async {
    // `ListView` / `GridView`（BoxScrollView）在没显式传 padding 时会把
    // MediaQuery 的垂直 padding 当 SliverPadding 用——外观设置、外部播放器
    // 这类页面因此不用逐个改。这里锁住这条依赖，显式传了 padding 就会破。
    await _pumpShellWithBottomInset(
      tester,
      AppMobileSubpageShell(
        title: '子页面',
        defaultLocation: '/mobile/overview',
        child: ListView.builder(
          key: const Key('subpage-plain-list'),
          itemCount: 60,
          itemBuilder: (_, index) => SizedBox(height: 40, child: Text('$index')),
        ),
      ),
    );

    final position = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(const Key('subpage-plain-list')),
            matching: find.byType(Scrollable),
          ),
        )
        .position;

    // 滚动范围比纯内容高多出一个安全区高度：多出来的就是自动补在末尾的留白。
    expect(
      position.maxScrollExtent - (60 * 40 - position.viewportDimension),
      moreOrLessEquals(34),
    );
  });
}

const double _kTestScreenHeight = 844;

Future<void> _pumpShellWithBottomInset(
  WidgetTester tester,
  Widget shell,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, _kTestScreenHeight);
  tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
  tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.view.resetPadding();
    tester.view.resetViewPadding();
  });

  await tester.pumpWidget(
    MaterialApp(theme: sakuraThemeData, home: shell),
  );
  await tester.pumpAndSettle();
}
