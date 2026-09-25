import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/videos/data/dto/video_item_list_item_dto.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';
import 'package:sakuramedia/widgets/base/feedback/app_confirm_dialog.dart';
import 'package:sakuramedia/widgets/domain/collections/playback/collection_episode_queue_item.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/overlays/app_action_menu.dart';

enum VideoCollectionEpisodeAction { remove, delete }

/// [presentation] 由触发方式决定：行长按 / 右键用
/// [AppMenuPresentation.popup]（锚定浮层），行尾「更多」按钮在移动端用
/// [AppMenuPresentation.bottomDrawer]（底部操作表）。
Future<VideoCollectionEpisodeAction?> showVideoCollectionEpisodeActions({
  required BuildContext context,
  required String title,
  required AppMenuPresentation presentation,
  Offset position = Offset.zero,
}) {
  final isDrawer = presentation == AppMenuPresentation.bottomDrawer;
  return showAppActionMenu<VideoCollectionEpisodeAction>(
    context: context,
    globalPosition: position,
    presentation: presentation,
    useRootNavigator: !isDrawer,
    drawerKey: const Key('video-episode-actions'),
    title: isDrawer ? title : null,
    items: const <AppMenuItem<VideoCollectionEpisodeAction>>[
      AppMenuItem(
        key: Key('video-episode-action-remove'),
        value: VideoCollectionEpisodeAction.remove,
        label: '移出合集',
        subtitle: '保留视频和媒体文件',
        icon: Icons.playlist_remove_rounded,
      ),
      AppMenuItem(
        key: Key('video-episode-action-delete'),
        value: VideoCollectionEpisodeAction.delete,
        label: '删除选集',
        subtitle: '删除视频及全部关联媒体',
        icon: Icons.delete_outline_rounded,
        tone: AppTextTone.error,
      ),
    ],
  );
}

Future<bool> showVideoEpisodeDeleteConfirmation({
  required BuildContext context,
  required String title,
  required Future<void> Function() onConfirm,
}) => showAppConfirmDialog(
  context,
  title: '删除选集',
  message: '将删除该视频及全部关联媒体文件，并从所有合集中移除。此操作不可恢复。',
  extraContent: Text(
    title,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: resolveAppTextStyle(
      context,
      size: AppTextSize.s14,
      tone: AppTextTone.primary,
    ),
  ),
  confirmLabel: '删除选集',
  danger: true,
  // 横屏使用紧凑确认窗；菜单仍为移动操作表。
  variant: AppConfirmVariant.dialog,
  confirmKey: const Key('video-episode-delete-confirm'),
  onConfirm: onConfirm,
);

class VideoEpisodeQueueItem extends StatelessWidget {
  const VideoEpisodeQueueItem({
    super.key,
    required this.video,
    required this.index,
    required this.isCurrent,
    required this.isBusy,
    required this.onPlay,
    required this.onContextActions,
    this.onMoreActions,
  });

  final VideoItemListItemDto video;
  final int index;
  final bool isCurrent;
  final bool isBusy;
  final VoidCallback? onPlay;

  /// 行长按 / 右键 → 锚定浮层，回调带按压点全局坐标。
  final ValueChanged<Offset>? onContextActions;

  /// 行尾「更多」按钮 → 移动端底部操作表 / 桌面浮层，回调带按钮右下角坐标。
  final ValueChanged<Offset>? onMoreActions;

  @override
  Widget build(BuildContext context) {
    final onContextActions = this.onContextActions;
    final onMoreActions = this.onMoreActions;
    return GestureDetector(
      onSecondaryTapDown: onContextActions == null
          ? null
          : (details) => onContextActions(details.globalPosition),
      onLongPressStart: onContextActions == null
          ? null
          : (details) => onContextActions(details.globalPosition),
      child: CollectionEpisodeQueueItem(
        itemKey: Key('video-collection-play-queue-item-${video.id}'),
        coverUrl: video.coverImage?.bestAvailableUrl,
        coverStyle: CollectionQueueCoverStyle.containOnMuted,
        title: video.preferredTitle,
        subtitle: '第 ${index + 1} 集',
        isCurrent: isCurrent,
        onTap: onPlay,
        trailing: Builder(
          builder: (buttonContext) => AppIconButton(
            key: Key('video-episode-more-${video.id}'),
            size: AppIconButtonSize.regular,
            tooltip: '选集操作',
            icon: isBusy
                ? SizedBox.square(
                    dimension: context.appComponentTokens.iconSizeSm,
                    child: const CircularProgressIndicator.adaptive(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.more_horiz_rounded),
            onPressed: onMoreActions == null
                ? null
                : () {
                    final box =
                        buttonContext.findRenderObject()! as RenderBox;
                    onMoreActions(
                      box.localToGlobal(Offset(box.size.width, box.size.height)),
                    );
                  },
          ),
        ),
      ),
    );
  }
}
