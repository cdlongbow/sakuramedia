import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/activity/presentation/pages/mobile/activity_page.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/media/images/masked_image.dart';

import '../../../../../support/test_api_bundle.dart';

void main() {
  testWidgets('renders task center at mobile width', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.parse('2026-08-10T12:00:00Z'),
    );
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    addTearDown(sessionStore.dispose);
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/system/jobs',
      body: const <Map<String, dynamic>>[],
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/system/activity/bootstrap',
      body: <String, dynamic>{
        'notifications': <String, dynamic>{
          'items': const <Map<String, dynamic>>[],
          'page': 1,
          'page_size': 20,
          'total': 0,
        },
        'unread_count': 0,
        'active_task_runs': const <Map<String, dynamic>>[],
        'task_runs': <String, dynamic>{
          'items': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 201,
              'task_key': 'media_import',
              'task_name': '媒体导入',
              'trigger_type': 'manual',
              'state': 'running',
              'progress_current': 1,
              'progress_total': 2,
              'progress_text': '处理中',
            },
          ],
          'page': 1,
          'page_size': 20,
          'total': 1,
        },
      },
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/download-tasks',
      body: <String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 401,
            'client_id': 1,
            'movie_number': 'ABC-001',
            'name': 'ABC-001',
            'remote_id': 'remote-401',
            'state': 'downloading',
            'progress': 0.5,
            'import_status': 'pending',
            'import_status_label': '等待导入',
            'movie_cover': <String, dynamic>{
              'id': 501,
              'origin': '/files/images/wide-401.jpg',
              'small': '/files/images/wide-401.jpg',
              'medium': '/files/images/wide-401.jpg',
              'large': '/files/images/wide-401.jpg',
            },
            'movie_thin_cover': <String, dynamic>{
              'id': 502,
              'origin': '/files/images/thin-401.jpg',
              'small': '/files/images/thin-401.jpg',
              'medium': '/files/images/thin-401.jpg',
              'large': '/files/images/thin-401.jpg',
            },
            'created_at': '2026-08-10T12:00:00Z',
            'updated_at': '2026-08-10T12:00:00Z',
          },
          <String, dynamic>{
            'id': 402,
            'client_id': 1,
            'movie_number': 'ABC-002',
            'name': 'ABC-002',
            'remote_id': 'remote-402',
            'state': 'downloading',
            'progress': 0.25,
            'import_status': 'pending',
            'import_status_label': '等待导入',
            'movie_cover': <String, dynamic>{
              'id': 503,
              'origin': '/files/images/wide-402.jpg',
              'small': '/files/images/wide-402.jpg',
              'medium': '/files/images/wide-402.jpg',
              'large': '/files/images/wide-402.jpg',
            },
            'created_at': '2026-08-10T12:00:00Z',
            'updated_at': '2026-08-10T12:00:00Z',
          },
        ],
        'page': 1,
        'page_size': 20,
        'total': 2,
      },
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/download-clients',
      body: const <Map<String, dynamic>>[],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: MaterialApp(
          theme: sakuraMobileThemeData,
          home: const AppPlatformScope(
            platform: AppPlatform.mobile,
            child: Scaffold(body: MobileActivityPage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('desktop-activity-page')), findsOneWidget);
    expect(find.byKey(const Key('activity-tab-tasks')), findsOneWidget);
    expect(
      find.byKey(const Key('activity-tab-download-tasks')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('activity-task-201')), findsOneWidget);
    expect(
      find.byKey(const Key('mobile-activity-task-filter-button')),
      findsOneWidget,
    );

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/system/jobs',
      body: <Map<String, dynamic>>[
        <String, dynamic>{
          'task_key': 'new_plugin_job',
          'plugin_id': 'new_plugin',
          'cli_help': '新插件任务',
          'manual_trigger_allowed': true,
        },
      ],
    );
    await tester.tap(find.byKey(const Key('activity-jobs-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('新插件任务'), findsOneWidget);
    expect(
      bundle.adapter.requests.where((r) => r.path == '/system/jobs'),
      hasLength(2),
    );
    expect(tester.takeException(), isNull);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('mobile-activity-task-filter-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('mobile-activity-task-filter-drawer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mobile-activity-task-state-filter')),
      findsOneWidget,
    );

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('activity-tab-download-tasks')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('download-task-401')), findsOneWidget);
    final thinCover = tester.widget<MaskedImage>(
      find.descendant(
        of: find.byKey(const Key('download-task-401')),
        matching: find.byType(MaskedImage),
      ),
    );
    final legacyBackendCover = tester.widget<MaskedImage>(
      find.descendant(
        of: find.byKey(const Key('download-task-402')),
        matching: find.byType(MaskedImage),
      ),
    );
    expect(thinCover.url, '/files/images/thin-401.jpg');
    expect(legacyBackendCover.url, '/files/images/wide-402.jpg');
    expect(
      find.byKey(const Key('mobile-download-filter-button')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('mobile-download-filter-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mobile-download-filter-drawer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mobile-download-filter-state')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

  });

  testWidgets('failed download task offers retrigger import and posts it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.parse('2026-08-10T12:00:00Z'),
    );
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    addTearDown(sessionStore.dispose);
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/system/jobs',
      body: const <Map<String, dynamic>>[],
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/system/activity/bootstrap',
      body: <String, dynamic>{
        'notifications': <String, dynamic>{
          'items': const <Map<String, dynamic>>[],
          'page': 1,
          'page_size': 20,
          'total': 0,
        },
        'unread_count': 0,
        'active_task_runs': const <Map<String, dynamic>>[],
        'task_runs': <String, dynamic>{
          'items': const <Map<String, dynamic>>[],
          'page': 1,
          'page_size': 20,
          'total': 0,
        },
      },
    );
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: '/download-tasks',
      body: <String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 401,
            'client_id': 1,
            'movie_number': 'SSIS-801',
            'name': 'SSIS-801',
            'remote_id': 'remote-401',
            'state': 'completed',
            'progress': 1.0,
            'import_status': 'failed',
            'import_status_label': '导入失败',
            'created_at': '2026-08-10T12:00:00Z',
            'updated_at': '2026-08-10T12:00:00Z',
          },
        ],
        'page': 1,
        'page_size': 20,
        'total': 1,
      },
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/download-clients',
      body: const <Map<String, dynamic>>[],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: OKToast(
          child: MaterialApp(
            theme: sakuraMobileThemeData,
            home: const AppPlatformScope(
              platform: AppPlatform.mobile,
              child: Scaffold(body: MobileActivityPage()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('activity-tab-download-tasks')));
    await tester.pumpAndSettle();

    // pending/导入中的任务不给入口，只有导入失败/已跳过才显示。
    expect(
      find.byKey(const Key('download-task-retrigger-import-401')),
      findsOneWidget,
    );

    bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/download-tasks/401/import',
      statusCode: 202,
      body: <String, dynamic>{
        'task_id': 401,
        'task_run_id': 7,
        'status': 'accepted',
      },
    );
    await tester.tap(
      find.byKey(const Key('download-task-retrigger-import-401')),
    );
    await tester.pumpAndSettle();

    expect(
      bundle.adapter.hitCount('POST', '/download-tasks/401/import'),
      1,
    );
    expect(find.text('已提交导入任务'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('mobile selection deletes download tasks from the bottom bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.parse('2026-08-10T12:00:00Z'),
    );
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    addTearDown(sessionStore.dispose);
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/system/jobs',
      body: const <Map<String, dynamic>>[],
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/system/activity/bootstrap',
      body: <String, dynamic>{
        'notifications': <String, dynamic>{
          'items': const <Map<String, dynamic>>[],
          'page': 1,
          'page_size': 20,
          'total': 0,
        },
        'unread_count': 0,
        'active_task_runs': const <Map<String, dynamic>>[],
        'task_runs': <String, dynamic>{
          'items': const <Map<String, dynamic>>[],
          'page': 1,
          'page_size': 20,
          'total': 0,
        },
      },
    );
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: '/download-tasks',
      body: <String, dynamic>{
        'items': <Map<String, dynamic>>[
          _mobileDownloadTaskJson(401),
          _mobileDownloadTaskJson(402),
        ],
        'page': 1,
        'page_size': 20,
        'total': 2,
      },
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/download-clients',
      body: const <Map<String, dynamic>>[],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: OKToast(
          child: MaterialApp(
            theme: sakuraMobileThemeData,
            home: const AppPlatformScope(
              platform: AppPlatform.mobile,
              child: Scaffold(body: MobileActivityPage()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('activity-tab-download-tasks')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('download-tasks-selection-entry')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('download-tasks-selection-header')),
      findsOneWidget,
    );
    // 多选态顶栏不再显示筛选入口，危险动作在贴底条。
    expect(find.byKey(const Key('mobile-download-filter-button')), findsNothing);
    await tester.tap(
      find.byKey(const Key('download-tasks-select-all-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('已选 2 个'), findsOneWidget);
    expect(
      find.byKey(const Key('download-tasks-batch-delete-button')),
      findsOneWidget,
    );

    for (final id in [401, 402]) {
      bundle.adapter.enqueueJson(
        method: 'DELETE',
        path: '/download-tasks/$id',
        statusCode: 204,
      );
    }
    await tester.tap(
      find.byKey(const Key('download-tasks-batch-delete-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('是否删除 2 个下载任务？'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(bundle.adapter.hitCount('DELETE', '/download-tasks/401'), 1);
    expect(bundle.adapter.hitCount('DELETE', '/download-tasks/402'), 1);
    expect(find.byKey(const Key('download-task-401')), findsNothing);
    expect(
      find.byKey(const Key('download-tasks-batch-delete-button')),
      findsNothing,
    );
    expect(find.text('已删除 2 个下载任务'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });
}

Map<String, dynamic> _mobileDownloadTaskJson(int id) => <String, dynamic>{
  'id': id,
  'client_id': 1,
  'movie_number': 'ABC-00$id',
  'name': 'ABC-00$id',
  'remote_id': 'remote-$id',
  'state': 'downloading',
  'progress': 0.5,
  'import_status': 'pending',
  'import_status_label': '等待导入',
  'created_at': '2026-08-10T12:00:00Z',
  'updated_at': '2026-08-10T12:00:00Z',
};
