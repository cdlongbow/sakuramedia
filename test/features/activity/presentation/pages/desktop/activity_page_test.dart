import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/activity/presentation/pages/desktop/activity_page.dart';
import 'package:sakuramedia/features/activity/presentation/providers/activity_api_provider.dart';
import 'package:sakuramedia/theme.dart';

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
      expiresAt: DateTime.parse('2030-01-01T00:00:00Z'),
    );
    bundle = await createTestApiBundle(sessionStore);
  });

  tearDown(() {
    bundle.dispose();
    sessionStore.dispose();
  });

  testWidgets('任务页 watch provider，资源任务首次进入才加载并可打开详情', (tester) async {
    _setDesktopViewport(tester);
    _enqueueActivity(bundle);
    _enqueueResourceTasks(bundle);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [activityApiProvider.overrideWithValue(bundle.activityApi)],
        child: OKToast(
          child: MaterialApp(
            theme: sakuraThemeData,
            home: const Scaffold(body: DesktopActivityPage()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('desktop-activity-page')), findsOneWidget);
    expect(find.byKey(const Key('activity-tasks-tab')), findsOneWidget);
    expect(find.byKey(const Key('activity-task-201')), findsOneWidget);
    expect(
      bundle.adapter.hitCount(
        'GET',
        '/system/resource-task-states/definitions',
      ),
      0,
    );

    await tester.tap(find.byKey(const Key('activity-tab-resource-tasks')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('activity-resource-tasks-tab')),
      findsOneWidget,
    );
    expect(
      bundle.adapter.hitCount(
        'GET',
        '/system/resource-task-states/definitions',
      ),
      1,
    );
    final record = find.byKey(
      const Key('resource-task-record-movie_interaction_sync/1001'),
    );
    expect(record, findsOneWidget);
    await tester.ensureVisible(record);
    await tester.tap(record);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('resource-task-detail-drawer')),
      findsOneWidget,
    );
  });
}

void _setDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _enqueueActivity(TestApiBundle bundle) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/system/jobs',
    body: const <Map<String, dynamic>>[],
  );
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/system/activity/bootstrap',
    body: <String, dynamic>{
      'latest_event_id': 120,
      'notifications': const <String, dynamic>{
        'items': <Map<String, dynamic>>[],
        'page': 1,
        'page_size': 20,
        'total': 0,
      },
      'unread_count': 0,
      'active_task_runs': const <Map<String, dynamic>>[],
      'task_runs': <String, dynamic>{
        'items': <Map<String, dynamic>>[_taskJson(201)],
        'page': 1,
        'page_size': 20,
        'total': 1,
      },
    },
  );
  bundle.adapter.enqueueSse(
    method: 'GET',
    path: '/system/events/stream',
    chunks: const <String>[],
    keepOpen: true,
  );
}

void _enqueueResourceTasks(TestApiBundle bundle) {
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/system/resource-task-states/definitions',
    body: const <Map<String, dynamic>>[
      <String, dynamic>{
        'task_key': 'movie_interaction_sync',
        'resource_type': 'movie',
        'display_name': '影片描述回填',
        'default_sort': 'last_attempted_at:desc',
        'allow_reset': true,
        'state_counts': <String, dynamic>{
          'pending': 0,
          'running': 0,
          'succeeded': 0,
          'failed': 1,
        },
      },
    ],
  );
  bundle.adapter.enqueueJson(
    method: 'GET',
    path: '/system/resource-task-states',
    body: <String, dynamic>{
      'items': <Map<String, dynamic>>[_resourceRecordJson(1001)],
      'page': 1,
      'page_size': 20,
      'total': 1,
    },
  );
}

Map<String, dynamic> _taskJson(int id) {
  return <String, dynamic>{
    'id': id,
    'task_key': 'example_plugin_sync',
    'task_name': '插件任务执行',
    'trigger_type': 'manual',
    'state': 'completed',
    'progress_current': 1,
    'progress_total': 1,
    'progress_text': '完成',
    'created_at': '2026-03-26T09:10:00Z',
    'updated_at': '2026-03-26T09:20:00Z',
    'started_at': '2026-03-26T09:10:00Z',
    'finished_at': '2026-03-26T09:20:00Z',
  };
}

Map<String, dynamic> _resourceRecordJson(int id) {
  return <String, dynamic>{
    'task_key': 'movie_interaction_sync',
    'resource_type': 'movie',
    'resource_id': id,
    'state': 'failed',
    'attempt_count': 1,
    'last_attempted_at': '2026-04-18T10:00:00Z',
    'last_succeeded_at': null,
    'last_error': 'timeout',
    'last_error_at': '2026-04-18T10:01:00Z',
    'last_task_run_id': 99,
    'last_trigger_type': 'scheduled',
    'created_at': '2026-04-01T00:00:00Z',
    'updated_at': '2026-04-18T10:00:00Z',
    'resource': <String, dynamic>{
      'resource_id': id,
      'movie_number': 'SSIS-$id',
      'title': '示例-$id',
      'valid': true,
    },
  };
}
