import 'package:material_ui/material_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/actors/presentation/pages/desktop/actor_detail_page.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';
import 'package:sakuramedia/widgets/base/navigation/app_filter_entry_button.dart';
import 'package:sakuramedia/widgets/base/navigation/app_list_header.dart';

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

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: bundle.riverpodOverrides(),
      child: OKToast(
        child: MaterialApp(
          theme: sakuraThemeData,
          home: Scaffold(body: child),
        ),
      ),
    );
  }

  testWidgets('桌面女优详情影片区顶栏与移动端同构：筛选入口 + 选择入口', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 1600);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors/1',
      body: _actorJson(),
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/movies',
      body: _moviesJson(),
    );

    await tester.pumpWidget(wrap(const DesktopActorDetailPage(actorId: 1)));
    await tester.pumpAndSettle();

    expect(find.byType(AppListHeader), findsOneWidget);
    expect(
      tester
          .widget<AppFilterEntryButton>(find.byType(AppFilterEntryButton))
          .label,
      isNotNull,
    );
    // 桌面「选择」留在顶栏操作槽。
    expect(
      find.descendant(
        of: find.byKey(const Key('app-list-header-action-slots')),
        matching: find.byKey(const Key('actor-detail-enter-selection-button')),
      ),
      findsOneWidget,
    );

    // 打开筛选浮层时懒加载年份分节和标签数据。
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors/1/years',
      body: <Map<String, dynamic>>[
        <String, dynamic>{'year': 2024, 'movie_count': 2},
      ],
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/tags',
      body: <Map<String, dynamic>>[
        <String, dynamic>{'tag_id': 3, 'name': '巨乳', 'movie_count': 100},
      ],
    );

    await tester.tap(find.byKey(const Key('actor-detail-filter-trigger')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('actor-detail-filter-panel')), findsOneWidget);
    // 标签分节在面板最末，不挤占其它筛选维度；这里只确认它存在。
    expect(find.text('标签'), findsOneWidget);
    expect(find.byKey(const Key('tags-option-3')), findsOneWidget);
    expect(find.text('状态筛选'), findsOneWidget);
    expect(find.text('发行年份'), findsOneWidget);
    expect(find.text('2024(2)'), findsOneWidget);
    expect(find.text('重置'), findsOneWidget);
  });

  testWidgets('桌面女优详情可以打开并保存本地显示名称', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 760);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors/1',
      body: <String, dynamic>{
        ..._actorJson(),
        'has_profile_image_override': true,
      },
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/movies',
      body: _moviesJson(),
    );
    await tester.pumpWidget(wrap(const DesktopActorDetailPage(actorId: 1)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('actor-detail-edit-button')));
    await tester.pumpAndSettle();
    expect(find.text('编辑女优资料'), findsOneWidget);
    expect(find.text('显示内容'), findsNothing);
    expect(find.text('不会覆盖外部来源资料'), findsNothing);
    expect(find.text('别名'), findsOneWidget);
    expect(find.text('填写一个别名，会优先展示别名。'), findsOneWidget);
    expect(find.text('基础资料'), findsOneWidget);
    expect(find.byKey(const Key('actor-profile-image-pick')), findsOneWidget);
    expect(find.byKey(const Key('actor-profile-image-clear')), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const Key('actor-profile-image-pick'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('actor-display-name-field'))).dy,
      ),
    );
    final submit = find.byKey(const Key('actor-profile-editor-submit'));
    final initialSubmitY = tester.getTopLeft(submit).dy;
    expect(tester.getBottomRight(submit).dy, lessThanOrEqualTo(760));

    await tester.enterText(
      find.byKey(const Key('actor-display-name-field')),
      '本地展示名',
    );
    final formScrollView = find.descendant(
      of: find.byKey(const Key('actor-profile-editor-form')),
      matching: find.byType(SingleChildScrollView),
    );
    await tester.drag(formScrollView, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(submit).dy, closeTo(initialSubmitY, 0.1));

    bundle.adapter.enqueueJson(
      method: 'PATCH',
      path: '/actors/1',
      body: <String, dynamic>{
        ..._actorJson(),
        'display_name': '本地展示名',
        'display_name_override': '本地展示名',
        'mutation_revision': 1,
      },
    );
    await tester.tap(submit);
    await tester.pumpAndSettle();

    final request = bundle.adapter.requests.singleWhere(
      (item) => item.method == 'PATCH' && item.path == '/actors/1',
    );
    expect(request.body, <String, dynamic>{
      'expected_revision': 0,
      'display_name_override': '本地展示名',
    });
    expect(find.text('编辑女优资料'), findsNothing);
    expect(find.text('本地展示名'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('女优基础资料校验血型并统一为大写', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 760);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors/1',
      body: _actorJson(),
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/movies',
      body: _moviesJson(),
    );
    await tester.pumpWidget(wrap(const DesktopActorDetailPage(actorId: 1)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('actor-detail-edit-button')));
    await tester.pumpAndSettle();

    final bloodTypeField = find.byKey(const Key('actor-blood-type-field'));
    await tester.ensureVisible(bloodTypeField);
    await tester.enterText(bloodTypeField, 'AB+');
    await tester.tap(find.byKey(const Key('actor-profile-editor-submit')));
    await tester.pumpAndSettle();

    expect(find.text('请输入 A、B、O 或 AB'), findsOneWidget);
    expect(bundle.adapter.hitCount('PATCH', '/actors/1'), 0);

    await tester.enterText(bloodTypeField, 'ab');
    bundle.adapter.enqueueJson(
      method: 'PATCH',
      path: '/actors/1',
      body: <String, dynamic>{
        ..._actorJson(),
        'blood_type': 'AB',
        'mutation_revision': 1,
      },
    );
    await tester.tap(find.byKey(const Key('actor-profile-editor-submit')));
    await tester.pumpAndSettle();

    final request = bundle.adapter.requests.singleWhere(
      (item) => item.method == 'PATCH' && item.path == '/actors/1',
    );
    expect(request.body, <String, dynamic>{
      'expected_revision': 0,
      'blood_type': 'AB',
    });
    expect(find.text('编辑女优资料'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('女优基础资料要求罩杯为一个大写英文字母', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 760);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors/1',
      body: _actorJson(),
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/movies',
      body: _moviesJson(),
    );
    await tester.pumpWidget(wrap(const DesktopActorDetailPage(actorId: 1)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('actor-detail-edit-button')));
    await tester.pumpAndSettle();

    final cupField = find.byKey(const Key('actor-cup-field'));
    await tester.ensureVisible(cupField);
    await tester.enterText(cupField, 'AA');
    await tester.tap(find.byKey(const Key('actor-profile-editor-submit')));
    await tester.pumpAndSettle();

    expect(find.text('请输入 1 个大写英文字母'), findsOneWidget);
    expect(bundle.adapter.hitCount('PATCH', '/actors/1'), 0);

    await tester.enterText(cupField, 'a');
    await tester.tap(find.byKey(const Key('actor-profile-editor-submit')));
    await tester.pumpAndSettle();

    expect(find.text('请输入 1 个大写英文字母'), findsOneWidget);
    expect(bundle.adapter.hitCount('PATCH', '/actors/1'), 0);

    await tester.enterText(cupField, 'C');
    bundle.adapter.enqueueJson(
      method: 'PATCH',
      path: '/actors/1',
      body: <String, dynamic>{
        ..._actorJson(),
        'cup': 'C',
        'mutation_revision': 1,
      },
    );
    await tester.tap(find.byKey(const Key('actor-profile-editor-submit')));
    await tester.pumpAndSettle();

    final request = bundle.adapter.requests.singleWhere(
      (item) => item.method == 'PATCH' && item.path == '/actors/1',
    );
    expect(request.body, <String, dynamic>{'expected_revision': 0, 'cup': 'C'});
    expect(find.text('编辑女优资料'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final succeeds in [true, false]) {
    testWidgets('批量屏蔽${succeeds ? '成功移除所选影片并退出多选' : '失败保留影片与选中状态'}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 1600);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/actors/1',
        body: _actorJson(),
      );
      bundle.adapter.enqueueJson(
        method: 'GET',
        path: '/movies',
        body: _moviesJson(),
      );
      bundle.adapter.enqueueJson(
        method: 'PUT',
        path: '/movies/blacklist',
        statusCode: succeeds ? 204 : 500,
      );
      await tester.pumpWidget(wrap(const DesktopActorDetailPage(actorId: 1)));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('actor-detail-enter-selection-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('movie-summary-card-ABC-001')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('actor-detail-batch-blacklist-button')),
      );
      await tester.pumpAndSettle();
      expect(bundle.adapter.hitCount('PUT', '/movies/blacklist'), 0);
      await tester.tap(
        find.byKey(const Key('actor-detail-batch-blacklist-confirm')),
      );
      await tester.pumpAndSettle();
      final request = bundle.adapter.requests.singleWhere(
        (r) => r.method == 'PUT',
      );
      expect(request.body, {
        'movie_numbers': ['ABC-001'],
      });
      expect(
        find.byKey(const Key('movie-summary-card-ABC-001')),
        succeeds ? findsNothing : findsOneWidget,
      );
      expect(
        find.byKey(const Key('movie-summary-card-ABC-002')),
        findsOneWidget,
      );
      if (succeeds) {
        expect(
          find.byKey(const Key('actor-detail-enter-selection-button')),
          findsOneWidget,
        );
        expect(find.text('作品 · 1 部'), findsOneWidget);
      } else {
        expect(find.text('已选 1 部'), findsOneWidget);
        expect(
          find.byKey(const Key('actor-detail-batch-blacklist-dialog')),
          findsOneWidget,
        );
      }
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('筛选面板内按标签过滤作品，重置同时清空标签', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 1600);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors/1',
      body: _actorJson(),
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/movies',
      body: _moviesJson(),
    );
    await tester.pumpWidget(wrap(const DesktopActorDetailPage(actorId: 1)));
    await tester.pumpAndSettle();

    // 标签数据是懒加载：面板打开前不发 /tags。
    expect(bundle.adapter.hitCount('GET', '/tags'), 0);

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors/1/years',
      body: <Map<String, dynamic>>[
        <String, dynamic>{'year': 2024, 'movie_count': 2},
      ],
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/tags',
      body: <Map<String, dynamic>>[
        <String, dynamic>{'tag_id': 3, 'name': '巨乳', 'movie_count': 100},
        <String, dynamic>{'tag_id': 5, 'name': '单体作品', 'movie_count': 80},
      ],
    );
    await tester.tap(find.byKey(const Key('actor-detail-filter-trigger')));
    await tester.pumpAndSettle();
    expect(bundle.adapter.hitCount('GET', '/tags'), 1);
    // 标签分节在面板最末，先滚到它再操作。
    expect(find.byKey(const Key('tags-option-3')), findsOneWidget);
    expect(find.text('状态筛选'), findsOneWidget);

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/movies',
      body: _moviesJson(total: 1),
    );
    await tester.ensureVisible(find.byKey(const Key('tags-option-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tags-option-3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final tagged = bundle.adapter.requests.lastWhere(
      (request) => request.path == '/movies',
    );
    expect(tagged.uri.queryParameters['actor_id'], '1');
    expect(tagged.uri.queryParameters['tag_ids'], '3');
    expect(tagged.uri.queryParameters['tag_match'], 'or');
    // 入口摘要直接反映标签条件。
    final entry = tester.widget<AppFilterEntryButton>(
      find.byType(AppFilterEntryButton),
    );
    expect(entry.label, '标签 · 1');

    // 面板 footer 的重置同时清空标签条件。
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/movies',
      body: _moviesJson(),
    );
    await tester.tap(find.text('重置'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final cleared = bundle.adapter.requests.lastWhere(
      (request) => request.path == '/movies',
    );
    expect(cleared.uri.queryParameters['actor_id'], '1');
    expect(cleared.uri.queryParameters.containsKey('tag_ids'), isFalse);
    expect(find.byKey(const Key('tags-selected-3')), findsNothing);
    expect(find.byKey(const Key('tags-option-3')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('标签节默认收起搜索并只展示前 5 个，展开后显示全部', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 1600);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors/1',
      body: _actorJson(),
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/movies',
      body: _moviesJson(),
    );
    await tester.pumpWidget(wrap(const DesktopActorDetailPage(actorId: 1)));
    await tester.pumpAndSettle();

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors/1/years',
      body: <Map<String, dynamic>>[],
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/tags',
      body: <Map<String, dynamic>>[
        for (var index = 1; index <= 70; index += 1)
          <String, dynamic>{
            'tag_id': index,
            'name': '标签$index',
            'movie_count': 100 - index,
          },
      ],
    );
    await tester.tap(find.byKey(const Key('actor-detail-filter-trigger')));
    await tester.pumpAndSettle();

    // 标签节在面板末尾：默认只展示前 5 个，且搜索框收起。
    await tester.ensureVisible(find.byKey(const Key('tags-option-5')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tags-search-field')), findsNothing);
    expect(find.byKey(const Key('tags-option-5')), findsOneWidget);
    expect(find.byKey(const Key('tags-option-6')), findsNothing);
    expect(find.text('展开全部'), findsOneWidget);
    // 女优筛选面板的标签不带影片数量。
    final firstTagChip = tester.widget<AppTextButton>(
      find.byKey(const Key('tags-option-1')),
    );
    expect(firstTagChip.label, '标签1');

    // 点搜索图标才展开输入框。
    await tester.ensureVisible(find.byKey(const Key('tags-search-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tags-search-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tags-search-field')), findsOneWidget);

    // 回归：follower 浮层内 hover 搜索图标不得触发
    // 「The paint transform cannot be reliably computed」断言
    // （图标曾带 Tooltip，Tooltip 的 OverlayPortal 与浮层的
    // CompositedTransformFollower 组合会崩，见 flutter/flutter#178522）。
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(
      tester.getCenter(find.byKey(const Key('tags-search-toggle'))),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await mouse.moveTo(Offset.zero);
    await tester.pump();

    // 收起搜索并「展开全部」后展示全部标签（旧实现在第 60 个处静默截断）。
    await tester.tap(find.byKey(const Key('tags-search-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tags-search-field')), findsNothing);
    await tester.ensureVisible(find.text('展开全部'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('展开全部'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tags-option-6')), findsOneWidget);
    expect(find.byKey(const Key('tags-option-70')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Map<String, dynamic> _actorJson() {
  return <String, dynamic>{
    'id': 1,
    'javdb_id': 'javdb-1',
    'name': '演员一号',
    'alias_name': '',
    'profile_image': null,
    'is_subscribed': false,
    'mutation_revision': 0,
  };
}

Map<String, dynamic> _moviesJson({int total = 2}) {
  return <String, dynamic>{
    'items': <Map<String, dynamic>>[
      for (var index = 0; index < total; index++)
        <String, dynamic>{
          'javdb_id': 'MovieA$index',
          'movie_number': 'ABC-00${index + 1}',
          'title': 'Movie $index',
          'cover_image': null,
          'release_date': '2024-01-02',
          'duration_minutes': 120,
          'is_subscribed': false,
          'can_play': true,
        },
    ],
    'page': 1,
    'page_size': 24,
    'total': total,
  };
}
