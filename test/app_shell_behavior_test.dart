import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oktoast/oktoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/actors/data/api/actors_api.dart';
import 'package:sakuramedia/features/image_search/presentation/image_search_file_picker.dart';
import 'package:sakuramedia/features/movies/data/api/movies_api.dart';
import 'package:sakuramedia/features/status/data/status_api.dart';
import 'package:sakuramedia/routes/app_router.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_badge.dart';

import 'support/test_api_bundle.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'SakuraMedia',
      packageName: 'sakuramedia',
      version: '0.2.3',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('desktop sidebar collapses to the token width', (
    WidgetTester tester,
  ) async {
    final sessionStore = await _buildLoggedInSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    _enqueueOverviewResponses(bundle);
    await _pumpDesktopApp(
      tester,
      bundle: bundle,
      sessionStore: sessionStore,
      statusApi: bundle.statusApi,
      moviesApi: bundle.moviesApi,
    );
    await tester.pumpAndSettle();

    final expandedWidth =
        tester.getSize(find.byKey(const Key('desktop-shell-sidebar'))).width;
    expect(expandedWidth, AppSidebarTokens.defaults().expandedWidth);
    expect(find.byKey(const Key('sidebar-toggle-button')), findsOneWidget);
    expect(find.byKey(const Key('mac-traffic-lights')), findsNothing);
    expect(find.text('SakuraMedia'), findsNothing);
    expect(find.text('SA'), findsNothing);
    expect(find.byKey(const Key('sidebar-version-info')), findsOneWidget);
    // 版本区收敛为单行页脚：双版本号常驻一行，完整信息收进弹窗。
    expect(find.text('0.2.3 · v0.2.0'), findsOneWidget);
    expect(
      find.byTooltip('客户端 0.2.3 · 服务端 v0.2.0'),
      findsOneWidget,
    );
    expect(find.text('系统版本'), findsNothing);
    expect(find.byKey(const Key('sidebar-version-dialog')), findsNothing);

    await tester.tap(find.byKey(const Key('sidebar-toggle-button')));
    await tester.pumpAndSettle();

    final collapsedWidth =
        tester.getSize(find.byKey(const Key('desktop-shell-sidebar'))).width;
    expect(collapsedWidth, AppSidebarTokens.defaults().collapsedWidth);
    // 收起 = 完全隐藏：导航内容与版本卡整体卸载；按钮固定在壳层，仍在。
    expect(find.byKey(const Key('sidebar-toggle-button')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('desktop-shell-sidebar')),
        matching: find.text('概览'),
      ),
      findsNothing,
    );
    expect(find.byKey(const Key('sidebar-version-info')), findsNothing);
    expect(find.byTooltip('概览'), findsNothing);
  });

  testWidgets('desktop sidebar highlights available backend and plugin updates', (
    WidgetTester tester,
  ) async {
    final sessionStore = await _buildLoggedInSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    _enqueueOverviewResponses(bundle);
    const frontendReleaseUrl =
        'https://api.github.com/repos/tinypinglite/sakuramedia/releases/latest';
    const backendReleaseUrl =
        'https://api.github.com/repos/tinypinglite/sakuramediabe/releases/latest';
    const pluginReleaseUrl =
        'https://api.github.com/repos/example/demo_plugin/releases/latest';
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: '/system/plugins',
      body: <Map<String, dynamic>>[
        <String, dynamic>{
          'plugin_id': 'demo_plugin',
          'display_name': '演示插件',
          'version': '1.0.0',
          'host_api_version': 1,
          'enabled': true,
          'load_status': 'ok',
          'release_api_url': pluginReleaseUrl,
        },
      ],
    );
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: frontendReleaseUrl,
      body: <String, dynamic>{'tag_name': 'v0.3.0'},
    );
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: backendReleaseUrl,
      body: <String, dynamic>{'tag_name': 'v0.3.0'},
    );
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: pluginReleaseUrl,
      body: <String, dynamic>{
        'tag_name': 'v1.1.0',
        'assets': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'demo_plugin-1.1.0.zip',
            'browser_download_url':
                'https://github.com/example/demo_plugin/releases/download/v1.1.0/demo_plugin-1.1.0.zip',
          },
        ],
      },
    );

    await _pumpDesktopApp(
      tester,
      bundle: bundle,
      sessionStore: sessionStore,
      statusApi: bundle.statusApi,
      moviesApi: bundle.moviesApi,
    );
    await tester.pumpAndSettle();

    // 常态：页脚单行 + 有更新 badge，详情收进弹窗、点行才展开。
    expect(find.byKey(const Key('sidebar-version-info')), findsOneWidget);
    expect(
      find.byKey(const Key('sidebar-version-update-badge')),
      findsOneWidget,
    );
    expect(find.text('有更新'), findsOneWidget);
    expect(find.byKey(const Key('sidebar-update-notice')), findsNothing);

    await tester.tap(find.byKey(const Key('sidebar-version-info')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sidebar-version-dialog')), findsOneWidget);
    expect(find.text('系统版本'), findsOneWidget);
    expect(find.byKey(const Key('sidebar-update-notice')), findsOneWidget);
    expect(find.text('发现可用更新'), findsOneWidget);
    expect(find.text('客户端 v0.3.0 · 服务端 v0.3.0 · 1 个插件'), findsOneWidget);
    final colors = sakuraThemeData.extension<AppColors>()!;
    final updateNotice = tester.widget<Container>(
      find.byKey(const Key('sidebar-update-notice')),
    );
    final updateNoticeDecoration = updateNotice.decoration! as BoxDecoration;
    expect(updateNoticeDecoration.color, colors.selectionSurface);
    final updateBadge = find.descendant(
      of: find.byKey(const Key('sidebar-version-dialog')),
      matching: find.byType(AppBadge),
    );
    expect(tester.widget<AppBadge>(updateBadge.first).tone, AppBadgeTone.primary);

    // 弹窗里的插件更新入口存在（跳转逻辑与系统诊断「去修复」同构；
    // 实际跳转的目标页渲染不在本测试覆盖范围，这里不点击跳转）。
    expect(
      find.byKey(const Key('sidebar-version-dialog-go-plugins')),
      findsOneWidget,
    );
  });

  testWidgets('desktop sidebar groups nav items into 浏览/管理 sections', (
    WidgetTester tester,
  ) async {
    final sessionStore = await _buildLoggedInSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    _enqueueOverviewResponses(bundle);
    await _pumpDesktopApp(
      tester,
      bundle: bundle,
      sessionStore: sessionStore,
      statusApi: bundle.statusApi,
      moviesApi: bundle.moviesApi,
    );
    await tester.pumpAndSettle();

    // 展开态：两个分区标题各渲染一次，概览置顶不带标题。
    expect(find.byKey(const Key('sidebar-section-浏览')), findsOneWidget);
    expect(find.byKey(const Key('sidebar-section-管理')), findsOneWidget);
    expect(find.text('浏览'), findsOneWidget);
    expect(find.text('管理'), findsOneWidget);

    // 顺序：概览 → 浏览标题 → … → 管理标题 → 系统设置。
    final overviewTop =
        tester.getTopLeft(find.byKey(const Key('nav-group-overview'))).dy;
    final browseHeaderTop =
        tester.getTopLeft(find.byKey(const Key('sidebar-section-浏览'))).dy;
    final manageHeaderTop =
        tester.getTopLeft(find.byKey(const Key('sidebar-section-管理'))).dy;
    final configurationTop =
        tester.getTopLeft(find.byKey(const Key('nav-group-configuration'))).dy;
    expect(overviewTop, lessThan(browseHeaderTop));
    expect(browseHeaderTop, lessThan(manageHeaderTop));
    expect(manageHeaderTop, lessThan(configurationTop));

    // 收起态：侧栏内容整体卸载。
    await tester.tap(find.byKey(const Key('sidebar-toggle-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sidebar-section-浏览')), findsNothing);
    expect(find.byKey(const Key('sidebar-section-管理')), findsNothing);
  });

  testWidgets('desktop sidebar shows bottom fade only while nav can scroll', (
    WidgetTester tester,
  ) async {
    final sessionStore = await _buildLoggedInSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    _enqueueOverviewResponses(bundle);
    await _pumpDesktopApp(
      tester,
      bundle: bundle,
      sessionStore: sessionStore,
      statusApi: bundle.statusApi,
      moviesApi: bundle.moviesApi,
    );
    await tester.pumpAndSettle();

    AnimatedOpacity fadeOpacity() => tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.byKey(const Key('sidebar-nav-scroll-fade')),
        matching: find.byType(AnimatedOpacity),
      ),
    );

    // 默认 800x600 视口下导航溢出，底部渐隐遮罩可见。
    expect(fadeOpacity().opacity, 1);

    // 视口足够高、导航不再溢出时，遮罩隐藏。
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    await tester.pumpAndSettle();
    expect(fadeOpacity().opacity, 0);
  });

  testWidgets('topbar header aligns with sidebar header', (
    WidgetTester tester,
  ) async {
    final sessionStore = await _buildLoggedInSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    _enqueueOverviewResponses(bundle);
    await _pumpDesktopApp(
      tester,
      bundle: bundle,
      sessionStore: sessionStore,
      statusApi: bundle.statusApi,
      moviesApi: bundle.moviesApi,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sidebar-header-divider')), findsNothing);
    expect(find.byKey(const Key('topbar-header-divider')), findsNothing);

    final sidebarHeader = tester.getRect(
      find.byKey(const Key('sidebar-header')),
    );
    final topbarHeader = tester.getRect(
      find.byKey(const Key('topbar-header')),
    );
    expect(sidebarHeader.top, topbarHeader.top);
    expect(sidebarHeader.height, topbarHeader.height);
  });

  testWidgets('desktop glass sidebar border stays subtle in dark mode', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final sessionStore = await _buildLoggedInSessionStore();
      final bundle = await createTestApiBundle(sessionStore);
      addTearDown(bundle.dispose);
      _enqueueOverviewResponses(bundle);
      await _pumpDesktopApp(
        tester,
        bundle: bundle,
        sessionStore: sessionStore,
        statusApi: bundle.statusApi,
        moviesApi: bundle.moviesApi,
        theme: buildSakuraDesktopThemeData(brightness: Brightness.dark),
      );
      await tester.pumpAndSettle();

      final sidebar = tester.widget<AnimatedContainer>(
        find.byKey(const Key('desktop-shell-sidebar')),
      );
      final borderColor =
          ((sidebar.decoration! as BoxDecoration).border! as Border)
              .right
              .color;
      expect(borderColor.toARGB32(), 0x15FFFFFF);

      expect(find.byKey(const Key('sidebar-header-divider')), findsNothing);
      expect(find.byKey(const Key('topbar-header-divider')), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('desktop sidebar does not overflow while expanding', (
    WidgetTester tester,
  ) async {
    final sessionStore = await _buildLoggedInSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    _enqueueOverviewResponses(bundle);
    await _pumpDesktopApp(
      tester,
      bundle: bundle,
      sessionStore: sessionStore,
      statusApi: bundle.statusApi,
      moviesApi: bundle.moviesApi,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sidebar-toggle-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sidebar-toggle-button')));
    await tester.pump(const Duration(milliseconds: 40));

    expect(tester.takeException(), isNull);
  });

  testWidgets('macOS desktop shell keeps top bar and sidebar toggle layout', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    final sessionStore = await _buildLoggedInSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    _enqueueOverviewResponses(bundle);
    await _pumpDesktopApp(
      tester,
      bundle: bundle,
      sessionStore: sessionStore,
      statusApi: bundle.statusApi,
      moviesApi: bundle.moviesApi,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('desktop-title-bar')), findsNothing);
    expect(find.text('概览'), findsWidgets);
    expect(find.byKey(const Key('topbar-header')), findsOneWidget);
    expect(find.byKey(const Key('sidebar-header')), findsOneWidget);
    expect(find.byKey(const Key('sidebar-header-divider')), findsNothing);
    expect(find.byKey(const Key('topbar-header-divider')), findsNothing);

    // 展开态：按钮固定在窗口左上角，红绿灯预留区（76pt）右侧 8pt，
    // 垂直居中于标题栏。
    final expandedToggle = tester.getRect(
      find.byKey(const Key('sidebar-toggle-button')),
    );
    final headerRect = tester.getRect(
      find.byKey(const Key('sidebar-header')),
    );
    expect(expandedToggle.left, 76 + 8);
    expect(expandedToggle.center.dy, headerRect.center.dy);

    // 红绿灯自绘：整组左缘 22pt、宽 54pt（close 中心 29pt 对齐菜单图标），
    // 与收起/展开按钮同线、间隔 8pt。
    final trafficLights = tester.getRect(
      find.byKey(const Key('mac-traffic-lights')),
    );
    expect(trafficLights.left, 22);
    expect(trafficLights.width, 54);
    expect(trafficLights.center.dy, headerRect.center.dy);
    expect(expandedToggle.left - trafficLights.right, 8);

    await tester.tap(find.byKey(const Key('sidebar-toggle-button')));
    await tester.pumpAndSettle();

    // 收起态：侧栏完全隐藏，按钮位置不变。
    expect(
      tester.getSize(find.byKey(const Key('desktop-shell-sidebar'))).width,
      AppSidebarTokens.defaults().collapsedWidth,
    );
    final collapsedToggle = tester.getRect(
      find.byKey(const Key('sidebar-toggle-button')),
    );
    expect(collapsedToggle.left, 76 + 8);
    expect(collapsedToggle.center.dy, expandedToggle.center.dy);
    expect(
      tester.getRect(find.byKey(const Key('mac-traffic-lights'))).left,
      22,
    );

    await tester.tap(find.byKey(const Key('sidebar-toggle-button')));
    await tester.pump(const Duration(milliseconds: 40));

    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('macOS desktop shell uses transparent root and opaque content', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    final sessionStore = await _buildLoggedInSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    _enqueueOverviewResponses(bundle);
    await _pumpDesktopApp(
      tester,
      bundle: bundle,
      sessionStore: sessionStore,
      statusApi: bundle.statusApi,
      moviesApi: bundle.moviesApi,
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    final contentContainer = tester.widget<Container>(
      find.byKey(const Key('desktop-shell-content-surface')),
    );

    expect(scaffold.backgroundColor, Colors.transparent);
    expect(
      contentContainer.color,
      sakuraThemeData.extension<AppColors>()!.surfaceElevated,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('desktop sidebar decoration adapts for macOS glass effect', (
    WidgetTester tester,
  ) async {
    final sessionStore = await _buildLoggedInSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    _enqueueOverviewResponses(bundle);

    await _pumpDesktopApp(
      tester,
      bundle: bundle,
      sessionStore: sessionStore,
      statusApi: bundle.statusApi,
      moviesApi: bundle.moviesApi,
    );
    await tester.pumpAndSettle();

    final defaultSidebar = tester.widget<AnimatedContainer>(
      find.byKey(const Key('desktop-shell-sidebar')),
    );
    final defaultDecoration = defaultSidebar.decoration! as BoxDecoration;
    final themeColors = sakuraThemeData.extension<AppColors>()!;

    expect(defaultDecoration.color, themeColors.sidebarBackground);
    expect(defaultDecoration.boxShadow, isNotEmpty);

    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    // 先卸载旧树，避免同一测试内二次挂载 router 触发 pageKey 冲突。
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await _pumpDesktopApp(
      tester,
      bundle: bundle,
      sessionStore: sessionStore,
      statusApi: bundle.statusApi,
      moviesApi: bundle.moviesApi,
    );
    await tester.pumpAndSettle();

    final macSidebar = tester.widget<AnimatedContainer>(
      find.byKey(const Key('desktop-shell-sidebar')),
    );
    final macDecoration = macSidebar.decoration! as BoxDecoration;

    expect(macDecoration.color, themeColors.desktopSidebarGlassTint);
    expect(macDecoration.boxShadow, isEmpty);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('desktop shell shows only the compact desktop navigation set', (
    WidgetTester tester,
  ) async {
    final sessionStore = await _buildLoggedInSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    _enqueueOverviewResponses(bundle);
    await _pumpDesktopApp(
      tester,
      bundle: bundle,
      sessionStore: sessionStore,
      statusApi: bundle.statusApi,
      moviesApi: bundle.moviesApi,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nav-group-overview')), findsOneWidget);
    expect(find.byKey(const Key('nav-group-movies')), findsOneWidget);
    expect(find.byKey(const Key('nav-group-actors')), findsOneWidget);
    expect(find.byKey(const Key('nav-group-moments')), findsOneWidget);
    expect(find.byKey(const Key('nav-group-configuration')), findsOneWidget);
    expect(find.byKey(const Key('nav-group-library')), findsNothing);
    expect(find.byKey(const Key('nav-group-resources')), findsNothing);
    expect(find.byKey(const Key('nav-group-system')), findsNothing);
  });

  testWidgets('desktop sidebar navigation items use compact height', (
    WidgetTester tester,
  ) async {
    final sessionStore = await _buildLoggedInSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    _enqueueOverviewResponses(bundle);
    await _pumpDesktopApp(
      tester,
      bundle: bundle,
      sessionStore: sessionStore,
      statusApi: bundle.statusApi,
      moviesApi: bundle.moviesApi,
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const Key('nav-group-overview'))).height,
      AppSidebarTokens.defaults().itemHeight + AppSpacing.defaults().xs,
    );
  });

  testWidgets('desktop top bar hosts search entry instead of sidebar', (
    WidgetTester tester,
  ) async {
    final sessionStore = await _buildLoggedInSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    _enqueueOverviewResponses(bundle);

    await _pumpDesktopApp(
      tester,
      bundle: bundle,
      sessionStore: sessionStore,
      statusApi: bundle.statusApi,
      moviesApi: bundle.moviesApi,
    );
    await tester.pumpAndSettle();

    // 侧边栏不再承载搜索入口。
    expect(find.byKey(const Key('sidebar-search-field')), findsNothing);
    expect(find.byKey(const Key('sidebar-search-button')), findsNothing);
    expect(find.byKey(const Key('sidebar-search-image')), findsNothing);
    expect(find.byKey(const Key('sidebar-search-text-image')), findsNothing);

    // 顶栏收起态只有图标；点击后展开输入框与两个图搜后缀，并自动聚焦。
    expect(find.byKey(const Key('topbar-search-button')), findsOneWidget);
    expect(find.byKey(const Key('topbar-search-field')), findsNothing);

    await tester.tap(find.byKey(const Key('topbar-search-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('topbar-search-field')), findsOneWidget);
    expect(find.byKey(const Key('topbar-search-image')), findsOneWidget);
    expect(find.byKey(const Key('topbar-search-text-image')), findsOneWidget);
    expect(_topBarSearchFieldHasFocus(tester), isTrue);
  });

  testWidgets('desktop top bar text image search opens unified search page', (
    WidgetTester tester,
  ) async {
    final sessionStore = await _buildLoggedInSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    _enqueueOverviewResponses(bundle);
    bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/image-search/text-sessions',
      body: <String, dynamic>{
        'session_id': 'text-session-1',
        'status': 'ready',
        'page_size': 20,
        'next_cursor': null,
        'expires_at': '2026-03-08T10:10:00Z',
        'items': const <Map<String, dynamic>>[],
      },
    );

    final router = await _pumpDesktopAppWithRouter(
      tester,
      bundle: bundle,
      sessionStore: sessionStore,
      statusApi: bundle.statusApi,
      moviesApi: bundle.moviesApi,
      actorsApi: bundle.actorsApi,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('topbar-search-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('topbar-search-text-image')));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      desktopImageSearchPath,
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['mode'],
      'text',
    );
    expect(find.byKey(const Key('image-search-mode-text')), findsOneWidget);
    expect(
      find.byKey(const Key('image-search-text-source-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('image-search-text-source-search-button')),
      findsOneWidget,
    );
    expect(bundle.adapter.hitCount('POST', '/image-search/text-sessions'), 0);

    await tester.enterText(
      find.byKey(const Key('image-search-text-source-field')),
      '白色连衣裙 海边',
    );
    await tester.tap(
      find.byKey(const Key('image-search-text-source-search-button')),
    );
    await tester.pumpAndSettle();

    expect(bundle.adapter.hitCount('POST', '/image-search/text-sessions'), 1);
  });

  testWidgets('desktop top bar image search button opens image search page', (
    WidgetTester tester,
  ) async {
    final sessionStore = await _buildLoggedInSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    addTearDown(() => debugImageSearchFilePicker = null);
    _enqueueOverviewResponses(bundle);
    bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/image-search/sessions',
      body: <String, dynamic>{
        'session_id': 'session-1',
        'status': 'ready',
        'page_size': 20,
        'next_cursor': null,
        'expires_at': '2026-03-08T10:10:00Z',
        'items': const <Map<String, dynamic>>[],
      },
    );
    bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/image-search/sessions',
      body: <String, dynamic>{
        'session_id': 'session-2',
        'status': 'ready',
        'page_size': 20,
        'next_cursor': null,
        'expires_at': '2026-03-08T10:10:00Z',
        'items': const <Map<String, dynamic>>[],
      },
    );
    debugImageSearchFilePicker =
        () async => ImageSearchPickedFile(
          bytes: Uint8List.fromList(const <int>[1, 2, 3, 4]),
          fileName: 'picked.png',
          mimeType: 'image/png',
        );

    final router = await _pumpDesktopAppWithRouter(
      tester,
      bundle: bundle,
      sessionStore: sessionStore,
      statusApi: bundle.statusApi,
      moviesApi: bundle.moviesApi,
      actorsApi: bundle.actorsApi,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('topbar-search-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('topbar-search-image')));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      '/desktop/search/image',
    );
    expect(bundle.adapter.hitCount('POST', '/image-search/sessions'), 1);

    await tester.tap(
      find.byKey(const Key('desktop-image-search-toggle-filter')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('desktop-image-search-filter-panel')),
      findsOneWidget,
    );
    await tester.tap(find.text('剧情图'));
    await tester.pump();
    expect(bundle.adapter.hitCount('POST', '/image-search/sessions'), 1);

    await tester.tap(find.byKey(const Key('image-search-filter-apply')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('desktop-image-search-filter-panel')),
      findsNothing,
    );
    expect(bundle.adapter.hitCount('POST', '/image-search/sessions'), 2);
  });

  testWidgets(
    'desktop top bar search submits query and collapses from collapsed sidebar',
    (WidgetTester tester) async {
      final sessionStore = await _buildLoggedInSessionStore();
      final bundle = await createTestApiBundle(sessionStore);
      addTearDown(bundle.dispose);
      _enqueueOverviewResponses(bundle);
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/movies',
        body: <String, dynamic>{
          'items': const <Map<String, dynamic>>[],
          'page': 1,
          'page_size': 50,
          'total': 0,
        },
      );
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/actors',
        body: <String, dynamic>{
          'items': const <Map<String, dynamic>>[],
          'page': 1,
          'page_size': 50,
          'total': 0,
        },
      );

      final router = await _pumpDesktopAppWithRouter(
        tester,
        bundle: bundle,
        sessionStore: sessionStore,
        statusApi: bundle.statusApi,
        moviesApi: bundle.moviesApi,
        actorsApi: bundle.actorsApi,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sidebar-toggle-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('topbar-search-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('topbar-search-input')),
        'SSNI-888',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(
        router.routeInformationProvider.value.uri.path,
        '/desktop/search/SSNI-888',
      );
      // 提交后收起：只剩图标，没有残留输入框。
      expect(find.byKey(const Key('topbar-search-button')), findsOneWidget);
      expect(find.byKey(const Key('topbar-search-field')), findsNothing);
    },
  );

  testWidgets('desktop top bar search collapses on escape', (
    WidgetTester tester,
  ) async {
    final sessionStore = await _buildLoggedInSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    _enqueueOverviewResponses(bundle);

    await _pumpDesktopApp(
      tester,
      bundle: bundle,
      sessionStore: sessionStore,
      statusApi: bundle.statusApi,
      moviesApi: bundle.moviesApi,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('topbar-search-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('topbar-search-field')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('topbar-search-field')), findsNothing);
    expect(find.byKey(const Key('topbar-search-button')), findsOneWidget);
  });

  testWidgets('desktop shell uses compact top bar and overview content', (
    WidgetTester tester,
  ) async {
    final sessionStore = await _buildLoggedInSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    // overview 页 sliver 化后靠视口惰性 build；默认 800×600 装不下
    // SystemDiagnosticsStrip + stats + xxl 间距，'最近添加' sliver 会落在
    // 视口外不构建。撑高视口让所有 sliver 同时进 cacheExtent。
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    _enqueueOverviewResponses(bundle);
    await _pumpDesktopApp(
      tester,
      bundle: bundle,
      sessionStore: sessionStore,
      statusApi: bundle.statusApi,
      moviesApi: bundle.moviesApi,
    );
    await tester.pumpAndSettle();

    final titleText = tester.widget<Text>(
      find.byKey(const Key('app-topbar-title')),
    );
    expect(titleText.style?.fontSize, 14);
    expect(
      tester.getSize(find.byKey(const Key('topbar-header'))).height,
      AppComponentTokens.defaults().desktopTitleBarHeight,
    );
    expect(find.byKey(const Key('topbar-back-button')), findsNothing);
    expect(find.text('Desktop Workbench'), findsNothing);
    expect(find.text('媒体资产'), findsOneWidget);
    expect(find.text('最近添加'), findsOneWidget);
  });

  testWidgets(
    'desktop sidebar logout button clears session and returns to login',
    (WidgetTester tester) async {
      final sessionStore = await _buildLoggedInSessionStore();
      final bundle = await createTestApiBundle(sessionStore);
      addTearDown(bundle.dispose);
      _enqueueOverviewResponses(bundle);
      await _pumpDesktopApp(
        tester,
        bundle: bundle,
        sessionStore: sessionStore,
        statusApi: bundle.statusApi,
        moviesApi: bundle.moviesApi,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sidebar-logout-button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('sidebar-logout-button')));
      await tester.pumpAndSettle();

      expect(sessionStore.hasSession, isFalse);
      expect(find.byKey(const Key('login-form-base-url')), findsOneWidget);
    },
  );
}

Future<SessionStore> _buildLoggedInSessionStore() async {
  final store = SessionStore.inMemory();
  await store.saveBaseUrl('https://api.example.com');
  await store.saveTokens(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    expiresAt: DateTime.parse('2026-03-10T12:00:00Z'),
  );
  return store;
}

Future<void> _pumpDesktopApp(
  WidgetTester tester, {
  required TestApiBundle bundle,
  required SessionStore sessionStore,
  required StatusApi statusApi,
  required MoviesApi moviesApi,
  ThemeData? theme,
}) async {
  final router = buildDesktopRouter(sessionStore: sessionStore);
  await tester.pumpWidget(
    ProviderScope(
      overrides: bundle.riverpodOverrides(),
      child: OKToast(
        child: MaterialApp.router(
          theme: theme ?? sakuraThemeData,
          routerConfig: router,
        ),
      ),
    ),
  );
}

Future<GoRouter> _pumpDesktopAppWithRouter(
  WidgetTester tester, {
  required TestApiBundle bundle,
  required SessionStore sessionStore,
  required StatusApi statusApi,
  required MoviesApi moviesApi,
  required ActorsApi actorsApi,
}) async {
  final router = buildDesktopRouter(sessionStore: sessionStore);
  await tester.pumpWidget(
    ProviderScope(
      overrides: bundle.riverpodOverrides(),
      child: OKToast(
        child: MaterialApp.router(theme: sakuraThemeData, routerConfig: router),
      ),
    ),
  );
  return router;
}

bool _topBarSearchFieldHasFocus(WidgetTester tester) {
  final editable = tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(const Key('topbar-search-input')),
      matching: find.byType(EditableText),
    ),
  );
  return editable.focusNode.hasFocus;
}

void _enqueueOverviewResponses(TestApiBundle bundle) {
  // Riverpod 迁移后：/status 至少被两个消费方触发（概览统计条 +
  // 侧边栏版本行的 appVersionInfoProvider.load），用 fallback 兜住多次调用。
  bundle.adapter.setFallbackJson(
    method: 'GET',
    path: '/status',
    body: <String, dynamic>{
      'backend_version': 'v0.2.0',
      'actors': <String, dynamic>{'female_total': 12, 'female_subscribed': 8},
      'movies': <String, dynamic>{
        'total': 120,
        'subscribed': 35,
        'playable': 88,
      },
      'media_files': <String, dynamic>{
        'total': 156,
        'total_size_bytes': 987654321,
      },
      'media_libraries': <String, dynamic>{'total': 3},
    },
  );
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/status/image-search',
    body: <String, dynamic>{
      'healthy': true,
      'embedding_service': <String, dynamic>{
        'healthy': true,
        'space_id': 'clip-vit-l-14',
        'dimension': 768,
        'modalities': <String>['image', 'text'],
      },
      'indexing': <String, dynamic>{
        'pending_thumbnails': 23,
        'failed_thumbnails': 2,
      },
    },
  );
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/movies/latest',
    body: <String, dynamic>{
      'items': List<Map<String, dynamic>>.generate(
        8,
        (index) => <String, dynamic>{
          'javdb_id': 'MovieA${index + 1}',
          'movie_number': 'ABC-${(index + 1).toString().padLeft(3, '0')}',
          'title': 'Movie ${index + 1}',
          'cover_image': null,
          'release_date': '2024-01-02',
          'duration_minutes': 120,
          'is_subscribed': index.isEven,
          'can_play': true,
        },
      ),
      'page': 1,
      'page_size': 8,
      'total': 8,
    },
  );
}
