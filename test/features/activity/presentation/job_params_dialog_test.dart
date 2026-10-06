import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/features/activity/data/job_metadata_dto.dart';
import 'package:sakuramedia/features/activity/presentation/job_params_dialog.dart';
import 'package:sakuramedia/theme.dart';

void main() {
  testWidgets('keeps parameter actions visible in a short mobile drawer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraMobileThemeData,
        home: AppPlatformScope(
          platform: AppPlatform.mobile,
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () =>
                      showJobParamsDialog(context, job: _jobWithManyFields),
                  child: const Text('打开'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('activity-job-params-dialog')), findsOneWidget);
    expect(
      find.byKey(const Key('activity-job-params-submit-button')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const Key('activity-job-params-form-scroll')),
      const Offset(0, -180),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('activity-job-params-submit-button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('filters dependent options and resets stale selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Map<String, dynamic>? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraMobileThemeData,
        home: AppPlatformScope(
          platform: AppPlatform.mobile,
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await showJobParamsDialog(
                      context,
                      job: _jobWithLinkedOptions,
                    );
                  },
                  child: const Text('打开'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.text('榜单 *'), findsOneWidget);
    expect(find.text('周期 *'), findsOneWidget);

    // 选择“热播”后，周期下拉只保留该榜单支持的日/周/月
    await tester.tap(find.text('请选择').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('热播'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('请选择'));
    await tester.pumpAndSettle();
    expect(find.text('日榜'), findsOneWidget);
    expect(find.text('周榜'), findsOneWidget);
    expect(find.text('全部'), findsNothing);
    await tester.tap(find.text('日榜'));
    await tester.pumpAndSettle();
    expect(find.text('日榜'), findsOneWidget);

    // 改选 TOP250 后，周期选择被重置并切换为 TOP250 的选项
    await tester.tap(find.text('热播'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TOP250'));
    await tester.pumpAndSettle();
    expect(find.text('日榜'), findsNothing);
    expect(find.text('请选择'), findsOneWidget);

    // 必填校验拦截空提交
    await tester.tap(
      find.byKey(const Key('activity-job-params-submit-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('请选择周期'), findsOneWidget);

    // 选择“全部”后可提交，提交的是 const 原始值
    await tester.tap(find.text('请选择'));
    await tester.pumpAndSettle();
    expect(find.text('日榜'), findsNothing);
    expect(find.text('全部'), findsOneWidget);
    await tester.tap(find.text('全部'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('activity-job-params-submit-button')),
    );
    await tester.pumpAndSettle();
    expect(result, <String, dynamic>{'board_key': 'top250', 'period': 'all'});
    expect(tester.takeException(), isNull);
  });
}

final _jobWithLinkedOptions = JobMetadataDto(
  taskKey: 'sakuramedia_javdb_ranking_sync_board',
  logName: 'javdb-ranking-sync-board',
  cliName: 'sync-javdb-ranking-board',
  cliHelp: '手动同步单个 JavDB 榜单',
  cronSetting: '',
  cronExpr: '',
  manualTriggerAllowed: true,
  lastTaskRun: null,
  paramsSchema: <String, dynamic>{
    'type': 'object',
    'required': <String>['board_key', 'period'],
    'properties': <String, dynamic>{
      'board_key': <String, dynamic>{
        'type': 'string',
        'title': '榜单',
        'description': '选择要同步的榜单',
        'oneOf': <Map<String, dynamic>>[
          <String, dynamic>{'const': 'playback_all', 'title': '热播'},
          <String, dynamic>{'const': 'top250', 'title': 'TOP250'},
        ],
      },
      'period': <String, dynamic>{
        'type': 'string',
        'title': '周期',
        'description': '可选项随所选榜单变化',
        'x-options-by': 'board_key',
        'oneOf': <Map<String, dynamic>>[
          <String, dynamic>{
            'const': 'daily',
            'title': '日榜',
            'x-when': <String>['playback_all'],
          },
          <String, dynamic>{
            'const': 'weekly',
            'title': '周榜',
            'x-when': <String>['playback_all'],
          },
          <String, dynamic>{
            'const': 'monthly',
            'title': '月榜',
            'x-when': <String>['playback_all'],
          },
          <String, dynamic>{
            'const': 'all',
            'title': '全部',
            'x-when': <String>['top250'],
          },
          <String, dynamic>{
            'const': '2026',
            'title': '2026年',
            'x-when': <String>['top250'],
          },
        ],
      },
    },
  },
);

final _jobWithManyFields = JobMetadataDto(
  taskKey: 'bulk_job',
  logName: 'bulk_job',
  cliName: 'bulk-job',
  cliHelp: '批量任务参数',
  cronSetting: '',
  cronExpr: '',
  manualTriggerAllowed: true,
  lastTaskRun: null,
  paramsSchema: <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      for (var index = 0; index < 6; index++)
        'path_$index': <String, dynamic>{
          'type': 'string',
          'title': '路径 ${index + 1}',
        },
    },
  },
);
