import 'package:sakuramedia/features/activity/data/activity_notification_dto.dart';
import 'package:sakuramedia/features/activity/data/task_run_dto.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// 活动/通知加载态占位数据：真实 DTO + [BoneMock] 文案，
/// 供 `AppSkeletonizer` 渲染与真实卡片同形的静态骨架。
///
/// 通知占位一律 `isRead: true`，避免构建后触发已读上报副作用。

List<ActivityNotificationDto> activityNotificationPlaceholders({int count = 5}) {
  return List<ActivityNotificationDto>.generate(
    count,
    (index) => ActivityNotificationDto(
      id: -1 - index,
      category: 'task',
      title: BoneMock.words(2),
      content: BoneMock.words(8),
      eventType: 'task_finished',
      dedupeKey: null,
      resourceType: null,
      resourceId: null,
      isRead: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      relatedTaskRunId: null,
      relatedResourceType: null,
      relatedResourceId: null,
    ),
    growable: false,
  );
}

List<TaskRunDto> taskRunPlaceholders({int count = 3, bool finished = true}) {
  return List<TaskRunDto>.generate(
    count,
    (index) => TaskRunDto(
      id: -1 - index,
      taskKey: 'task-$index',
      taskName: BoneMock.words(2),
      triggerType: 'manual',
      // 不用 running / pending，避免占位卡渲染动画进度条。
      state: finished ? 'success' : 'failed',
      progressCurrent: 10,
      progressTotal: 10,
      progressText: null,
      resultText: '完成',
      resultSummary: null,
      errorMessage: null,
      startedAt: DateTime(2026, 1, 1),
      finishedAt: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    growable: false,
  );
}
