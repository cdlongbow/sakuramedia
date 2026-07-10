import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/format/file_size.dart';
import 'package:sakuramedia/core/format/media_timecode.dart';
import 'package:sakuramedia/core/format/transfer_speed.dart';
import 'package:sakuramedia/core/format/updated_at_label.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/core/network/api_exception.dart';
import 'package:sakuramedia/features/downloads/data/download_request_dto.dart';
import 'package:sakuramedia/features/downloads/presentation/download_task_center_controller.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';
import 'package:sakuramedia/widgets/base/feedback/app_confirm_dialog.dart';
import 'package:sakuramedia/widgets/base/feedback/app_empty_state.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_badge.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_paged_load_more_footer.dart';

/// 构建「下载任务」Tab 的 sliver 列表。
///
/// 与 [buildResourceTaskSlivers] 对齐的纯函数风格：调用方负责把返回的 slivers 放进
/// 外层 `CustomScrollView`。
List<Widget> buildDownloadTaskSlivers({
  required BuildContext context,
  required DownloadTaskCenterController controller,
}) {
  if (controller.isInitialLoading) {
    return const <Widget>[SliverToBoxAdapter(child: _DownloadInitialLoading())];
  }
  if (controller.initialErrorMessage != null) {
    return <Widget>[
      SliverToBoxAdapter(
        child: AppEmptyState(
          message: controller.initialErrorMessage!,
          onRetry: () => controller.retryInitialize(),
        ),
      ),
    ];
  }

  final slivers = <Widget>[
    SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(bottom: context.appSpacing.lg),
        child: _DownloadClientSpeedBar(controller: controller),
      ),
    ),
  ];

  if (controller.items.isEmpty) {
    slivers.add(
      const SliverToBoxAdapter(
        child: AppEmptyState(message: '暂无下载任务'),
      ),
    );
    return slivers;
  }

  slivers.add(
    SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final row = controller.items[index];
        final isLast = index == controller.items.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : context.appSpacing.md),
          child: RepaintBoundary(
            child: _DownloadTaskCard(controller: controller, row: row),
          ),
        );
      }, childCount: controller.items.length),
    ),
  );

  if (controller.hasMore || controller.loadMoreErrorMessage != null) {
    slivers.add(
      SliverToBoxAdapter(
        child: Column(
          children: [
            SizedBox(height: context.appSpacing.lg),
            AppPagedLoadMoreFooter(
              isLoading: controller.isLoadingMore,
              errorMessage: controller.loadMoreErrorMessage,
              onRetry: controller.loadMore,
            ),
            SizedBox(height: context.appSpacing.xl),
          ],
        ),
      ),
    );
  }
  return slivers;
}

class _DownloadInitialLoading extends StatelessWidget {
  const _DownloadInitialLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.appSpacing.xxl),
      child: Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: context.appComponentTokens.movieCardLoaderStrokeWidth,
          ),
        ),
      ),
    );
  }
}

class _DownloadClientSpeedBar extends StatelessWidget {
  const _DownloadClientSpeedBar({required this.controller});

  final DownloadTaskCenterController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final transfers = controller.clientTransfers.values.toList()
      ..sort((a, b) => a.clientId.compareTo(b.clientId));
    final hasAnyLiveData = transfers.isNotEmpty;
    final totalDown = controller.totalDownloadSpeedBytes;
    final totalUp = controller.totalUploadSpeedBytes;

    return Container(
      key: const Key('download-client-speed-bar'),
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.appSpacing.lg,
        vertical: context.appSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SpeedSummaryLabel(
            icon: Icons.arrow_downward_rounded,
            value: hasAnyLiveData ? formatTransferSpeed(totalDown) : '—',
          ),
          SizedBox(width: context.appSpacing.md),
          _SpeedSummaryLabel(
            icon: Icons.arrow_upward_rounded,
            value: hasAnyLiveData ? formatTransferSpeed(totalUp) : '—',
          ),
          SizedBox(width: context.appSpacing.lg),
          Expanded(
            child: Wrap(
              spacing: context.appSpacing.sm,
              runSpacing: context.appSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final transfer in transfers)
                  _ClientTransferPill(
                    controller: controller,
                    transfer: transfer,
                  ),
              ],
            ),
          ),
          if (controller.streamState != DownloadTaskStreamState.idle) ...[
            SizedBox(width: context.appSpacing.sm),
            _DownloadStreamBadge(state: controller.streamState),
          ],
        ],
      ),
    );
  }
}

class _SpeedSummaryLabel extends StatelessWidget {
  const _SpeedSummaryLabel({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: context.appComponentTokens.iconSizeSm,
          color: context.appTextPalette.secondary,
        ),
        SizedBox(width: context.appSpacing.xs),
        Text(
          value,
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s14,
            weight: AppTextWeight.semibold,
            tone: AppTextTone.primary,
          ),
        ),
      ],
    );
  }
}

class _ClientTransferPill extends StatelessWidget {
  const _ClientTransferPill({
    required this.controller,
    required this.transfer,
  });

  final DownloadTaskCenterController controller;
  final DownloadClientTransferState transfer;

  @override
  Widget build(BuildContext context) {
    final name = controller.clientNameOf(transfer.clientId);
    if (!transfer.isAvailable) {
      return Tooltip(
        message: transfer.unavailableMessage ?? '客户端不可用',
        child: AppBadge(
          key: Key('download-client-status-${transfer.clientId}'),
          label: '$name · 不可用',
          tone: AppBadgeTone.error,
          size: AppBadgeSize.compact,
        ),
      );
    }
    final label =
        '$name · ↓${formatTransferSpeed(transfer.downloadSpeedBytes)} · ↑${formatTransferSpeed(transfer.uploadSpeedBytes)}';
    return AppBadge(
      key: Key('download-client-status-${transfer.clientId}'),
      label: label,
      tone: AppBadgeTone.neutral,
      size: AppBadgeSize.compact,
    );
  }
}

class _DownloadStreamBadge extends StatelessWidget {
  const _DownloadStreamBadge({required this.state});

  final DownloadTaskStreamState state;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (state) {
      DownloadTaskStreamState.live => ('实时', AppBadgeTone.success),
      DownloadTaskStreamState.connecting => ('连接中', AppBadgeTone.neutral),
      DownloadTaskStreamState.reconnecting => ('重连中', AppBadgeTone.warning),
      DownloadTaskStreamState.polling => ('轮询', AppBadgeTone.info),
      DownloadTaskStreamState.idle => ('未连接', AppBadgeTone.neutral),
    };
    return AppBadge(
      key: const Key('download-task-stream-badge'),
      label: label,
      tone: tone,
      size: AppBadgeSize.compact,
    );
  }
}

class _DownloadTaskCard extends StatelessWidget {
  const _DownloadTaskCard({required this.controller, required this.row});

  final DownloadTaskCenterController controller;
  final DownloadTaskRowState row;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final task = row.task;
    final live = row.live;
    final progress = row.progress.clamp(0.0, 1.0);
    final downloadState = row.downloadState;
    final isPending = controller.isTaskPending(task.id);
    final isImportRunning = task.importStatus == 'running';

    return Container(
      key: Key('download-task-${task.id}'),
      width: double.infinity,
      padding: EdgeInsets.all(context.appSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.name.isEmpty ? task.infoHash : task.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: resolveAppTextStyle(
                          context,
                          size: AppTextSize.s14,
                          weight: AppTextWeight.regular,
                          tone: AppTextTone.secondary,
                        ),
                      ),
                    ),
                    if ((task.movieNumber ?? '').isNotEmpty) ...[
                      SizedBox(width: context.appSpacing.sm),
                      AppBadge(
                        label: task.movieNumber!,
                        tone: AppBadgeTone.neutral,
                        size: AppBadgeSize.compact,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: context.appSpacing.md),
              AppBadge(
                label: _labelForDownloadState(downloadState),
                tone: _toneForDownloadState(downloadState),
              ),
            ],
          ),
          SizedBox(height: context.appSpacing.md),
          ClipRRect(
            borderRadius: context.appRadius.pillBorder,
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress,
              backgroundColor: colors.surfaceMuted,
            ),
          ),
          SizedBox(height: context.appSpacing.md),
          Wrap(
            spacing: context.appSpacing.sm,
            runSpacing: context.appSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: resolveAppTextStyle(
                  context,
                  size: AppTextSize.s12,
                  weight: AppTextWeight.regular,
                  tone: AppTextTone.muted,
                ),
              ),
              if (live != null && live.totalSizeBytes > 0)
                Text(
                  '${formatFileSize(live.downloadedBytes)} / ${formatFileSize(live.totalSizeBytes)}',
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s12,
                    weight: AppTextWeight.regular,
                    tone: AppTextTone.muted,
                  ),
                ),
              if (live != null && downloadState == 'downloading') ...[
                Text(
                  '↓${formatTransferSpeed(live.downloadSpeedBytes)}',
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s12,
                    weight: AppTextWeight.regular,
                    tone: AppTextTone.muted,
                  ),
                ),
                Text(
                  '↑${formatTransferSpeed(live.uploadedSpeedBytes)}',
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s12,
                    weight: AppTextWeight.regular,
                    tone: AppTextTone.muted,
                  ),
                ),
              ],
              if (live?.etaSeconds != null && (live?.etaSeconds ?? 0) > 0)
                Text(
                  '剩余 ${formatMediaDurationLabel(live!.etaSeconds!)}',
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s12,
                    weight: AppTextWeight.regular,
                    tone: AppTextTone.muted,
                  ),
                ),
              if (task.importStatusLabel.isNotEmpty)
                AppBadge(
                  label: task.importStatusLabel,
                  tone: _toneForImportStatus(task.importStatus),
                  size: AppBadgeSize.compact,
                ),
              Text(
                controller.clientNameOf(task.clientId),
                style: resolveAppTextStyle(
                  context,
                  size: AppTextSize.s12,
                  weight: AppTextWeight.regular,
                  tone: AppTextTone.muted,
                ),
              ),
              if (formatUpdatedAtLabel(task.createdAt) != null)
                Text(
                  '创建 ${formatUpdatedAtLabel(task.createdAt)}',
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s12,
                    weight: AppTextWeight.regular,
                    tone: AppTextTone.muted,
                  ),
                ),
            ],
          ),
          SizedBox(height: context.appSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 已完成的任务不再显示暂停/恢复：qB 里此状态两个动作都无意义。
              if (downloadState == 'paused')
                AppIconButton(
                  key: Key('download-task-resume-${task.id}'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  tooltip: '恢复',
                  onPressed: isPending
                      ? null
                      : () => _resume(context, controller, task.id),
                )
              else if (downloadState != 'completed')
                AppIconButton(
                  key: Key('download-task-pause-${task.id}'),
                  icon: const Icon(Icons.pause_rounded),
                  tooltip: '暂停',
                  onPressed: isPending
                      ? null
                      : () => _pause(context, controller, task.id),
                ),
              if (downloadState != 'completed')
                SizedBox(width: context.appSpacing.sm),
              AppIconButton(
                key: Key('download-task-delete-${task.id}'),
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: isImportRunning ? '任务正在导入，无法删除' : '删除',
                onPressed: (isPending || isImportRunning)
                    ? null
                    : () => _confirmDelete(context, controller, task),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _pause(
  BuildContext context,
  DownloadTaskCenterController controller,
  int taskId,
) async {
  try {
    await controller.pauseTask(taskId);
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    showToast(_downloadErrorMessage(error, fallback: '暂停失败'));
  }
}

Future<void> _resume(
  BuildContext context,
  DownloadTaskCenterController controller,
  int taskId,
) async {
  try {
    await controller.resumeTask(taskId);
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    showToast(_downloadErrorMessage(error, fallback: '恢复失败'));
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  DownloadTaskCenterController controller,
  DownloadTaskDto task,
) async {
  var deleteFiles = false;
  await showAppConfirmDialog(
    context,
    dialogKey: const Key('download-task-delete-dialog'),
    title: '删除下载任务',
    message: '确认删除任务「${task.name.isEmpty ? task.infoHash : task.name}」？',
    danger: true,
    confirmLabel: '删除',
    failureFallback: '删除失败',
    extraContent: _DeleteFilesCheckbox(
      onChanged: (value) => deleteFiles = value,
    ),
    onConfirm: () async {
      try {
        await controller.deleteTask(task.id, deleteFiles: deleteFiles);
      } catch (error) {
        // 抛一个只带 message 的 ApiException，让 confirm dialog 的
        // apiErrorMessage 直接吐出我们映射的中文（error.error 留空 →
        // 走 message 分支）。
        throw ApiException(
          message: _downloadErrorMessage(error, fallback: '删除失败'),
        );
      }
    },
  );
}

String _downloadErrorMessage(Object error, {required String fallback}) {
  if (error is ApiException) {
    final code = error.error?.code;
    switch (code) {
      case 'download_task_remote_missing':
        return '任务在下载器中已不存在';
      case 'download_task_not_managed':
        return '该任务不受本系统管理';
      case 'download_task_import_running':
        return '任务正在导入，无法删除';
    }
  }
  return apiErrorMessage(error, fallback: fallback);
}

class _DeleteFilesCheckbox extends StatefulWidget {
  const _DeleteFilesCheckbox({required this.onChanged});

  final ValueChanged<bool> onChanged;

  @override
  State<_DeleteFilesCheckbox> createState() => _DeleteFilesCheckboxState();
}

class _DeleteFilesCheckboxState extends State<_DeleteFilesCheckbox> {
  bool _deleteFiles = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          _deleteFiles = !_deleteFiles;
        });
        widget.onChanged(_deleteFiles);
      },
      borderRadius: context.appRadius.smBorder,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.appSpacing.xs),
        child: Row(
          children: [
            Checkbox(
              key: const Key('download-task-delete-files-checkbox'),
              value: _deleteFiles,
              onChanged: (value) {
                setState(() {
                  _deleteFiles = value ?? false;
                });
                widget.onChanged(_deleteFiles);
              },
            ),
            SizedBox(width: context.appSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '同时删除下载器里的种子文件',
                    style: resolveAppTextStyle(
                      context,
                      size: AppTextSize.s12,
                      weight: AppTextWeight.regular,
                      tone: AppTextTone.secondary,
                    ),
                  ),
                  SizedBox(height: context.appSpacing.xs / 2),
                  Text(
                    '不影响已导入媒体库的文件',
                    style: resolveAppTextStyle(
                      context,
                      size: AppTextSize.s10,
                      weight: AppTextWeight.regular,
                      tone: AppTextTone.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _labelForDownloadState(String state) {
  return switch (state) {
    'downloading' => '下载中',
    'completed' => '已完成',
    'paused' => '已暂停',
    'failed' => '失败',
    'stalled' => '等待资源',
    'checking' => '校验中',
    'queued' => '排队中',
    _ => state.isEmpty ? '未知' : state,
  };
}

AppBadgeTone _toneForDownloadState(String state) {
  return switch (state) {
    'downloading' => AppBadgeTone.primary,
    'completed' => AppBadgeTone.success,
    'paused' => AppBadgeTone.neutral,
    'failed' => AppBadgeTone.error,
    'stalled' => AppBadgeTone.warning,
    'checking' => AppBadgeTone.info,
    'queued' => AppBadgeTone.neutral,
    _ => AppBadgeTone.neutral,
  };
}

AppBadgeTone _toneForImportStatus(String state) {
  return switch (state) {
    'running' => AppBadgeTone.primary,
    'completed' => AppBadgeTone.success,
    'failed' => AppBadgeTone.error,
    'pending' || 'skipped' => AppBadgeTone.neutral,
    _ => AppBadgeTone.neutral,
  };
}
