import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/actors/presentation/pages/desktop/actor_detail_page.dart';
import 'package:sakuramedia/theme.dart';
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
        child: MaterialApp(theme: sakuraThemeData, home: Scaffold(body: child)),
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

    // 打开筛选浮层时懒加载年份分节。
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/actors/1/years',
      body: <Map<String, dynamic>>[
        <String, dynamic>{'year': 2024, 'movie_count': 2},
      ],
    );

    await tester.tap(find.byKey(const Key('actor-detail-filter-trigger')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('actor-detail-filter-panel')), findsOneWidget);
    expect(find.text('状态筛选'), findsOneWidget);
    expect(find.text('发行年份'), findsOneWidget);
    expect(find.text('2024(2)'), findsOneWidget);
    expect(find.text('重置'), findsOneWidget);
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
}

Map<String, dynamic> _actorJson() {
  return <String, dynamic>{
    'id': 1,
    'javdb_id': 'javdb-1',
    'name': '演员一号',
    'alias_name': '',
    'profile_image': null,
    'is_subscribed': false,
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
