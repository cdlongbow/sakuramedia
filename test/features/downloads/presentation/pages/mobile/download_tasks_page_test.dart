import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/downloads/presentation/pages/mobile/download_tasks_page.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_adaptive_refresh_scroll_view.dart';

import '../../../../../support/test_api_bundle.dart';

void main() {
  testWidgets('mobile download page shows manual add and refresh view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final sessionStore = await _loggedInSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    addTearDown(sessionStore.dispose);
    _fallbackDownloadPage(
      bundle,
      tasks: <Map<String, dynamic>>[
        _mobileDownloadTaskJson(401),
        _mobileDownloadTaskJson(402),
      ],
    );
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: '/download-clients',
      body: const <Map<String, dynamic>>[],
    );

    await tester.pumpWidget(_mobileApp(bundle));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('download-tasks-page')), findsOneWidget);
    expect(find.byKey(const Key('download-task-401')), findsOneWidget);
    expect(find.byKey(const Key('download-tasks-manual-add')), findsOneWidget);
    expect(
      find.byKey(const Key('mobile-download-filter-button')),
      findsOneWidget,
    );
    expect(find.byType(AppAdaptiveRefreshScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360px header keeps manual add, selection and filter', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final sessionStore = await _loggedInSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    addTearDown(sessionStore.dispose);
    _fallbackDownloadPage(
      bundle,
      tasks: <Map<String, dynamic>>[_mobileDownloadTaskJson(401)],
    );
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: '/download-clients',
      body: const <Map<String, dynamic>>[],
    );

    await tester.pumpWidget(_mobileApp(bundle));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('download-tasks-manual-add')), findsOneWidget);
    expect(
      find.byKey(const Key('download-tasks-selection-entry')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('mobile-download-filter-button')),
      findsOneWidget,
    );
  });

  testWidgets('failed download task offers retrigger import and posts it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final sessionStore = await _loggedInSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    addTearDown(sessionStore.dispose);
    _fallbackDownloadPage(
      bundle,
      tasks: <Map<String, dynamic>>[
        <String, dynamic>{
          ..._mobileDownloadTaskJson(401),
          'movie_number': 'SSIS-801',
          'state': 'completed',
          'progress': 1.0,
          'import_status': 'failed',
          'import_status_label': '导入失败',
        },
      ],
    );
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: '/download-clients',
      body: const <Map<String, dynamic>>[],
    );

    await tester.pumpWidget(_mobileApp(bundle));
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

    expect(bundle.adapter.hitCount('POST', '/download-tasks/401/import'), 1);
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
    final sessionStore = await _loggedInSessionStore();
    final bundle = await createTestApiBundle(sessionStore);
    addTearDown(bundle.dispose);
    addTearDown(sessionStore.dispose);
    _fallbackDownloadPage(
      bundle,
      tasks: <Map<String, dynamic>>[
        _mobileDownloadTaskJson(401),
        _mobileDownloadTaskJson(402),
      ],
    );
    bundle.adapter.setFallbackJson(
      method: 'GET',
      path: '/download-clients',
      body: const <Map<String, dynamic>>[],
    );

    await tester.pumpWidget(_mobileApp(bundle));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('download-tasks-selection-entry')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('download-tasks-selection-header')),
      findsOneWidget,
    );
    // 多选态顶栏不再显示筛选入口，危险动作在贴底条。
    expect(
      find.byKey(const Key('mobile-download-filter-button')),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('download-tasks-select-all-button')));
    await tester.pumpAndSettle();
    expect(find.text('已选 2 个'), findsOneWidget);
    expect(
      find.byKey(const Key('download-tasks-batch-delete-button')),
      findsOneWidget,
    );

    bundle.adapter.enqueueJson(
      method: 'POST',
      path: '/batch-operations',
      statusCode: 202,
      body: {
        'task_run_id': 7,
        'task_key': 'batch_operation',
        'state': 'pending',
      },
    );
    await tester.tap(
      find.byKey(const Key('download-tasks-batch-delete-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('是否删除 2 个下载任务？'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    final submit = bundle.adapter.requests
        .where((request) => request.path == '/batch-operations')
        .toList();
    expect(submit, hasLength(1));
    expect(submit.single.body, {
      'operation': 'download_task_delete',
      'ids': [401, 402],
      'delete_files': false,
    });
    expect(bundle.adapter.hitCount('DELETE', '/download-tasks/401'), 0);
    expect(bundle.adapter.hitCount('DELETE', '/download-tasks/402'), 0);
    // 提交后列表不即时变化，等任务完成后手动刷新。
    expect(find.byKey(const Key('download-task-401')), findsOneWidget);
    expect(
      find.byKey(const Key('download-tasks-batch-delete-button')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });
}

Widget _mobileApp(TestApiBundle bundle) {
  return ProviderScope(
    overrides: bundle.riverpodOverrides(),
    child: OKToast(
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
        theme: sakuraMobileThemeData,
        home: const AppPlatformScope(
          platform: AppPlatform.mobile,
          child: Scaffold(body: MobileDownloadTasksPage()),
        ),
      ),
    ),
  );
}

void _fallbackDownloadPage(
  TestApiBundle bundle, {
  required List<Map<String, dynamic>> tasks,
}) {
  bundle.adapter.setFallbackJson(
    method: 'GET',
    path: '/download-tasks',
    body: <String, dynamic>{
      'items': tasks,
      'page': 1,
      'page_size': 20,
      'total': tasks.length,
    },
  );
}

Future<SessionStore> _loggedInSessionStore() async {
  final sessionStore = SessionStore.inMemory();
  await sessionStore.saveBaseUrl('https://api.example.com');
  await sessionStore.saveTokens(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    expiresAt: DateTime.parse('2026-08-10T12:00:00Z'),
  );
  return sessionStore;
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
