import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/actors/presentation/pages/desktop/actors_page.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_filter_total_header.dart';
import 'package:sakuramedia/widgets/base/navigation/app_filter_entry_button.dart';
import 'package:sakuramedia/widgets/base/navigation/app_list_header.dart';
import 'package:sakuramedia/widgets/domain/actors/actor_list_search_field.dart';
import 'package:sakuramedia/widgets/domain/actors/actor_summary_card.dart';

import '../../../../../support/test_api_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionStore sessionStore;
  late TestApiBundle bundle;

  setUp(() async {
    sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.parse('2026-03-10T12:00:00Z'),
    );
    bundle = await createTestApiBundle(sessionStore);
  });

  tearDown(() {
    bundle.dispose();
  });

  testWidgets('桌面女优页顶栏与移动端同构：筛选入口 + 总数信息胶囊', (WidgetTester tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors',
      body: _actorsJson(total: 3),
    );

    await _pumpActorsPage(tester, sessionStore: sessionStore, bundle: bundle);
    await tester.pumpAndSettle();

    // 顶栏收敛到 AppListHeader，旧的 AppFilterTotalHeader 不再出现。
    expect(find.byType(AppListHeader), findsOneWidget);
    expect(find.byType(AppFilterTotalHeader), findsNothing);

    // 关键词搜索默认只占一个图标位，点击才展开搜索框。
    expect(find.byKey(const Key('actors-search-toggle')), findsOneWidget);
    expect(find.byKey(const Key('actors-search-field')), findsNothing);

    // 筛选入口与移动端共用同一个按钮，摘要只报订阅状态这一主维度。
    final entry = tester.widget<AppFilterEntryButton>(
      find.byType(AppFilterEntryButton),
    );
    expect(entry.label, '已订阅');

    // 总数走只读信息胶囊，不再是顶栏右侧裸文本。
    expect(
      find.descendant(
        of: find.byKey(const Key('app-list-header-information-slots')),
        matching: find.byKey(const Key('actors-page-total')),
      ),
      findsOneWidget,
    );
    expect(find.text('3 位'), findsOneWidget);
  });

  testWidgets('桌面筛选浮层与移动抽屉同构，选中即时生效并重新拉取', (WidgetTester tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors',
      body: _actorsJson(total: 3),
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors/filter-options',
      body: _filterOptionsJson(),
    );

    await _pumpActorsPage(tester, sessionStore: sessionStore, bundle: bundle);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('actors-filter-trigger')));
    await tester.pumpAndSettle();

    // 面板内容与移动抽屉逐节一致，重置在 footer 里。
    expect(find.byKey(const Key('actors-filter-panel')), findsOneWidget);
    expect(find.text('订阅筛选'), findsOneWidget);
    expect(find.text('性别筛选'), findsOneWidget);
    expect(find.text('播放筛选'), findsOneWidget);
    expect(find.text('确定'), findsNothing);

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors',
      body: _actorsJson(total: 1),
    );

    await tester.tap(find.text('未订阅'));
    await tester.pump();
    await tester.pump();

    // 控件与摘要先动，250ms 防抖窗口内不请求，旧列表/总数继续显示。
    expect(bundle.adapter.hitCount('GET', '/actors'), 1);
    expect(find.text('3 位'), findsOneWidget);
    expect(find.text('正在更新筛选结果'), findsNothing);
    expect(
      find.byKey(const Key('app-filter-result-loading-overlay')),
      findsNothing,
    );
    final pendingEntry = tester.widget<AppFilterEntryButton>(
      find.byType(AppFilterEntryButton),
    );
    expect(pendingEntry.label, '未订阅');

    await tester.pumpAndSettle();

    // 防抖结束后只用新条件拉取并替换结果。
    final lastRequest = bundle.adapter.requests
        .where((request) => request.path == '/actors')
        .last;
    expect(lastRequest.path, '/actors');
    expect(
      lastRequest.uri.queryParameters['subscription_status'],
      'unsubscribed',
    );
    expect(find.text('1 位'), findsOneWidget);

    final entry = tester.widget<AppFilterEntryButton>(
      find.byType(AppFilterEntryButton),
    );
    expect(entry.label, '未订阅');
  });

  testWidgets('搜索框输入防抖后带 query 请求，清空后移除 query', (WidgetTester tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors',
      body: _actorsJson(total: 3),
    );

    await _pumpActorsPage(tester, sessionStore: sessionStore, bundle: bundle);
    await tester.pumpAndSettle();
    expect(bundle.adapter.hitCount('GET', '/actors'), 1);

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors',
      body: _actorsJson(total: 1),
    );
    await tester.tap(find.byKey(const Key('actors-search-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('actors-search-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('actors-search-field')),
      '三上',
    );
    await tester.pump();

    // 防抖窗口内不请求，旧列表继续显示。
    expect(bundle.adapter.hitCount('GET', '/actors'), 1);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final searchRequest = bundle.adapter.requests
        .where((request) => request.path == '/actors')
        .last;
    expect(searchRequest.uri.queryParameters['query'], '三上');
    // 搜索开始时默认「已订阅」放宽为全部，筛选入口如实显示。
    expect(searchRequest.uri.queryParameters['subscription_status'], 'all');
    final searchingEntry = tester.widget<AppFilterEntryButton>(
      find.byType(AppFilterEntryButton),
    );
    expect(searchingEntry.label, '全部');

    // 展开后左侧筛选入口与总数原位保留，输入框与搜索 icon 共存于同一行。
    expect(find.byKey(const Key('actors-filter-trigger')), findsOneWidget);
    expect(find.text('1 位'), findsOneWidget);
    expect(find.byKey(const Key('actors-search-toggle')), findsOneWidget);

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors',
      body: _actorsJson(total: 3),
    );
    await tester.tap(find.byKey(const Key('actors-search-clear')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final clearedRequest = bundle.adapter.requests
        .where((request) => request.path == '/actors')
        .last;
    expect(clearedRequest.uri.queryParameters.containsKey('query'), isFalse);
    // 清空搜索后保持放宽后的「全部」，不回滚筛选。
    expect(clearedRequest.uri.queryParameters['subscription_status'], 'all');

    await tester.tap(find.byKey(const Key('actors-search-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('actors-search-field')), findsNothing);
    expect(find.text('3 位'), findsOneWidget);
  });

  testWidgets('收起搜索保留关键词并高亮入口，再展开回填原词', (WidgetTester tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors',
      body: _actorsJson(total: 3),
    );
    await _pumpActorsPage(tester, sessionStore: sessionStore, bundle: bundle);
    await tester.pumpAndSettle();

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors',
      body: _actorsJson(total: 1),
    );
    await tester.tap(find.byKey(const Key('actors-search-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('actors-search-field')),
      '三上',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('1 位'), findsOneWidget);
    expect(find.byKey(const Key('actors-search-toggle')), findsOneWidget);

    await tester.tap(find.byKey(const Key('actors-search-toggle')));
    await tester.pumpAndSettle();

    // 收起只隐藏输入框：关键词仍生效，入口保持高亮。
    expect(find.byKey(const Key('actors-search-field')), findsNothing);
    expect(find.text('1 位'), findsOneWidget);
    final toggle = tester.widget<ActorListSearchToggle>(
      find.byKey(const Key('actors-search-toggle')),
    );
    expect(toggle.isActive, isTrue);

    await tester.tap(find.byKey(const Key('actors-search-toggle')));
    await tester.pumpAndSettle();
    final field = tester.widget<TextFormField>(
      find.byKey(const Key('actors-search-field')),
    );
    expect(field.controller?.text, '三上');
  });

  testWidgets('搜索入口与筛选头固定在滚动区上方', (WidgetTester tester) async {
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors',
      body: _actorsJson(
        total: 40,
        items: List<Map<String, dynamic>>.generate(
          24,
          (index) => _actorItem(id: index + 1, name: '演员$index'),
        ),
      ),
    );

    await _pumpActorsPage(tester, sessionStore: sessionStore, bundle: bundle);
    await tester.pumpAndSettle();

    final searchTop = tester
        .getTopLeft(find.byKey(const Key('actors-search-toggle')))
        .dy;
    final headerTop = tester
        .getTopLeft(find.byKey(const Key('actors-filter-trigger')))
        .dy;
    final firstCardTop = tester
        .getTopLeft(find.byType(ActorSummaryCard).first)
        .dy;

    final scroll = tester
        .widget<CustomScrollView>(find.byType(CustomScrollView))
        .controller!;
    scroll.jumpTo(400);
    await tester.pump();

    expect(
      tester.getTopLeft(find.byKey(const Key('actors-search-toggle'))).dy,
      searchTop,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('actors-filter-trigger'))).dy,
      headerTop,
    );
    expect(
      tester.getTopLeft(find.byType(ActorSummaryCard).first).dy,
      lessThan(firstCardTop),
    );
  });
}

Future<void> _pumpActorsPage(
  WidgetTester tester, {
  required SessionStore sessionStore,
  required TestApiBundle bundle,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: bundle.riverpodOverrides(),
      child: OKToast(
        child: MaterialApp(
          theme: sakuraThemeData,
          home: const Scaffold(body: DesktopActorsPage()),
        ),
      ),
    ),
  );
}

Map<String, dynamic> _actorsJson({
  int page = 1,
  int pageSize = 20,
  int total = 1,
  List<Map<String, dynamic>>? items,
}) {
  return <String, dynamic>{
    'items': items ?? <Map<String, dynamic>>[_actorItem()],
    'page': page,
    'page_size': pageSize,
    'total': total,
  };
}

Map<String, dynamic> _filterOptionsJson() {
  return <String, dynamic>{
    'actor_count': 3,
    'as_of_date': '2026-09-10',
    'age': <String, dynamic>{'min': 20, 'max': 40, 'populated_count': 3},
    'height_cm': <String, dynamic>{
      'min': 150,
      'max': 170,
      'populated_count': 3,
    },
    'cups': <Map<String, dynamic>>[],
  };
}

Map<String, dynamic> _actorItem({
  int id = 1,
  String name = '演员一号',
  bool isSubscribed = true,
}) {
  return <String, dynamic>{
    'id': id,
    'javdb_id': 'javdb-$id',
    'name': name,
    'alias_name': '',
    'profile_image': null,
    'is_subscribed': isSubscribed,
  };
}
