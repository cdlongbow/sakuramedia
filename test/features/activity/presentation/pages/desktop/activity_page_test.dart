import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/activity/presentation/providers/activity_center_provider.dart';
import 'package:sakuramedia/features/activity/presentation/providers/activity_center_state.dart';
import 'package:sakuramedia/features/activity/presentation/pages/desktop/activity_page.dart';
import 'package:sakuramedia/features/downloads/presentation/download_task_filter_state.dart';
import 'package:sakuramedia/features/downloads/presentation/providers/download_task_center_provider.dart';
import 'package:sakuramedia/features/downloads/presentation/providers/download_task_center_state.dart';
import 'package:sakuramedia/theme.dart';

import '../../../../../support/test_api_bundle.dart';

void main() {
  testWidgets('shows task and download tabs without removed task UI', (
    tester,
  ) async {
    const pluginId = 'sakuramedia_115_provider';
    tester.view.physicalSize = const Size(1400, 900);
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
      body: const <dynamic>[],
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/system/activity/bootstrap',
      body: <String, dynamic>{
        'notifications': <String, dynamic>{
          'items': const <dynamic>[],
          'page': 1,
          'page_size': 20,
          'total': 0,
        },
        'unread_count': 0,
        'active_task_runs': const <dynamic>[],
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: MaterialApp(
          theme: sakuraDesktopThemeData,
          home: const Scaffold(body: DesktopActivityPage()),
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

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/system/jobs',
      body: <Map<String, dynamic>>[
        <String, dynamic>{
          'task_key': 'core_job',
          'cli_help': '核心维护任务',
          'manual_trigger_allowed': true,
        },
        <String, dynamic>{
          'task_key': 'plugin_job_1',
          'plugin_id': pluginId,
          'cli_help': '插件任务一',
          'manual_trigger_allowed': true,
        },
        <String, dynamic>{
          'task_key': 'plugin_job_2',
          'plugin_id': pluginId,
          'cli_help': '插件任务二',
          'manual_trigger_allowed': true,
        },
      ],
    );

    await tester.tap(find.byKey(const Key('activity-jobs-toggle')));
    await tester.pumpAndSettle();

    expect(
      bundle.adapter.requests.where((r) => r.path == '/system/jobs'),
      hasLength(2),
    );
    expect(find.byKey(const Key('activity-job-plugin-filter')), findsOneWidget);
    await tester.tap(find.byKey(const Key('activity-job-plugin-filter')));
    await tester.pumpAndSettle();

    expect(find.text('系统任务'), findsOneWidget);
    expect(find.text(pluginId), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('activity-job-plugin-filter'))).width,
      moreOrLessEquals(
        sakuraDesktopThemeData.appLayoutTokens.dialogWidthMd -
            sakuraDesktopThemeData.appSpacing.xl * 2,
        epsilon: 0.1,
      ),
    );
    await tester.tap(find.text(pluginId));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('activity-job-core_job')), findsNothing);
    expect(find.byKey(const Key('activity-job-plugin_job_1')), findsOneWidget);
    expect(find.byKey(const Key('activity-job-plugin_job_2')), findsOneWidget);
  });

  testWidgets('task key filter lists chinese task names but filters by key', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
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
      body: const <dynamic>[],
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/system/activity/bootstrap',
      body: <String, dynamic>{
        'notifications': <String, dynamic>{
          'items': const <dynamic>[],
          'page': 1,
          'page_size': 20,
          'total': 0,
        },
        'unread_count': 0,
        'active_task_runs': const <dynamic>[],
        'task_runs': <String, dynamic>{
          'items': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 601,
              'task_key': 'download_task_sync',
              'task_name': '下载任务状态同步',
              'trigger_type': 'scheduled',
              'state': 'completed',
            },
          ],
          'page': 1,
          'page_size': 20,
          'total': 1,
        },
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: MaterialApp(
          theme: sakuraDesktopThemeData,
          home: const Scaffold(body: DesktopActivityPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('activity-task-key-filter')));
    await tester.pumpAndSettle();

    expect(find.text('全部任务类型'), findsNWidgets(2));
    expect(find.text('下载任务状态同步'), findsWidgets);
    expect(find.text('download_task_sync'), findsNothing);

    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/system/task-runs',
      body: <String, dynamic>{
        'items': const <dynamic>[],
        'page': 1,
        'page_size': 20,
        'total': 0,
      },
    );
    await tester.tap(find.text('下载任务状态同步').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final request = bundle.adapter.requests.lastWhere(
      (request) => request.path == '/system/task-runs',
    );
    expect(request.uri.queryParameters['task_key'], 'download_task_sync');
    expect(find.text('download_task_sync'), findsNothing);
  });

  testWidgets('completed import task exposes failed file handling entry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
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
      body: const <dynamic>[],
    );
    bundle.adapter.enqueueJson(
      method: 'GET',
      path: '/system/activity/bootstrap',
      body: <String, dynamic>{
        'notifications': <String, dynamic>{
          'items': const <dynamic>[],
          'page': 1,
          'page_size': 20,
          'total': 0,
        },
        'unread_count': 0,
        'active_task_runs': const <dynamic>[],
        'task_runs': <String, dynamic>{
          'items': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 301,
              'task_key': 'library_import',
              'task_name': 'JAV媒体库导入',
              'trigger_type': 'manual',
              'state': 'failed',
              'result_summary': <String, dynamic>{
                'failed_count': 1,
                'failed_files': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 'failure-1',
                    'state': 'pending',
                    'reason': 'movie_number_not_found',
                    'kind': 'file',
                  },
                ],
              },
            },
            <String, dynamic>{
              'id': 302,
              'task_key': 'library_import',
              'task_name': '视频导入',
              'trigger_type': 'manual',
              'state': 'completed',
              'result_summary': <String, dynamic>{
                'failed_count': 0,
                'failed_files': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 'skipped-1',
                    'state': 'pending',
                    'reason': 'unsupported_format',
                    'kind': 'skipped',
                  },
                  <String, dynamic>{
                    'id': 'skipped-2',
                    'state': 'pending',
                    'reason': 'file_too_small',
                    'kind': 'skipped',
                  },
                ],
              },
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
      path: '/imports/301/failed-items',
      body: <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'failure-1',
          'relative_path': 'release/no-number.mp4',
          'size_bytes': 2048,
          'is_video': true,
          'reason': 'movie_number_not_found',
          'detail': '无法从文件名识别番号',
          'kind': 'file',
          'state': 'pending',
          'retry_task_run_id': null,
          'resolved_movie_id': null,
          'resolved_media_id': null,
          'last_retry_error': null,
          'can_manual_search': true,
        },
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: bundle.riverpodOverrides(),
        child: MaterialApp(
          theme: sakuraDesktopThemeData,
          home: const Scaffold(body: DesktopActivityPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final entry = find.byKey(const Key('activity-task-failed-items-301'));
    expect(entry, findsOneWidget);
    expect(find.text('处理失败文件（1）'), findsOneWidget);
    expect(find.byKey(const Key('activity-task-failed-items-302')), findsOneWidget);
    expect(find.text('查看跳过文件（2）'), findsOneWidget);

    await tester.tap(entry);
    await tester.pumpAndSettle();

    expect(find.text('失败与跳过文件'), findsOneWidget);
    expect(find.text('no-number.mp4'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('retained page follows visibility and updated download intent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    _RetainedActivityCenter.instance = null;
    _RetainedDownloadTaskCenter.instance = null;

    var isVisible = false;
    String? movieNumber;
    late StateSetter rebuild;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activityCenterProvider.overrideWith(_RetainedActivityCenter.new),
          downloadTaskCenterProvider.overrideWith(
            _RetainedDownloadTaskCenter.new,
          ),
        ],
        child: MaterialApp(
          theme: sakuraDesktopThemeData,
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return TickerMode(
                enabled: isVisible,
                child: Scaffold(
                  body: DesktopActivityPage(
                    initialDownloadMovieNumber: movieNumber,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final activity = _RetainedActivityCenter.instance!;
    expect(activity.pauseCalls, 1);
    expect(activity.resumeCalls, 0);
    expect(_RetainedDownloadTaskCenter.instance, isNull);

    rebuild(() => isVisible = true);
    await tester.pumpAndSettle();
    expect(activity.resumeCalls, 1);

    rebuild(() => movieNumber = 'ABC-001');
    await tester.pumpAndSettle();
    final downloads = _RetainedDownloadTaskCenter.instance!;
    expect(downloads.appliedFilters.single.search, 'ABC-001');
    expect(activity.current.activeTab, ActivityTab.downloadTasks);

    rebuild(() => movieNumber = 'ABC-002');
    await tester.pumpAndSettle();
    expect(downloads.appliedFilters.map((filter) => filter.search), [
      'ABC-001',
      'ABC-002',
    ]);

    rebuild(() => isVisible = false);
    await tester.pumpAndSettle();
    expect(activity.pauseCalls, 2);
    expect(downloads.pauseCalls, 1);
    expect(downloads.current.pollingState, DownloadTaskPollingState.idle);

    rebuild(() => isVisible = true);
    await tester.pumpAndSettle();
    expect(activity.resumeCalls, 2);
    expect(downloads.resumeCalls, 1);
    expect(downloads.current.pollingState, DownloadTaskPollingState.polling);
  });
}

class _RetainedActivityCenter extends ActivityCenter {
  static _RetainedActivityCenter? instance;

  int pauseCalls = 0;
  int resumeCalls = 0;

  @override
  Future<ActivityCenterState> build() async {
    instance = this;
    return ActivityCenterState.initial.copyWith(
      initialized: true,
      hasMoreTasks: false,
      connectionState: ActivityConnectionState.polling,
    );
  }

  @override
  void pausePolling() {
    pauseCalls++;
    state = AsyncData(current.copyWith(connectionMessage: '已暂停'));
  }

  @override
  Future<void> resumePolling() async {
    resumeCalls++;
    state = AsyncData(current.copyWith(connectionMessage: '轮询中'));
  }

  @override
  void setActiveTab(ActivityTab tab, {int? highlightTaskRunId}) {
    state = AsyncData(
      current.copyWith(
        activeTab: tab,
        highlightedTaskRunId: highlightTaskRunId,
      ),
    );
  }
}

class _RetainedDownloadTaskCenter extends DownloadTaskCenter {
  static _RetainedDownloadTaskCenter? instance;

  final List<DownloadTaskFilterState> appliedFilters =
      <DownloadTaskFilterState>[];
  int pauseCalls = 0;
  int resumeCalls = 0;

  DownloadTaskCenterState get current =>
      state.value ?? DownloadTaskCenterState.initial;

  @override
  Future<DownloadTaskCenterState> build() async {
    instance = this;
    return DownloadTaskCenterState.initial;
  }

  @override
  Future<void> applyFilter(DownloadTaskFilterState next) async {
    appliedFilters.add(next);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(filter: next));
    }
  }

  @override
  void pausePolling() {
    pauseCalls++;
    state = AsyncData(
      current.copyWith(pollingState: DownloadTaskPollingState.idle),
    );
  }

  @override
  Future<void> resumePolling() async {
    resumeCalls++;
    state = AsyncData(
      current.copyWith(pollingState: DownloadTaskPollingState.polling),
    );
  }

  @override
  Future<void> startPolling() async {}

  @override
  void stopPolling() {}
}
