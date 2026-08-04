import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/clip_collections/presentation/widgets/add_to_clip_collection_dialog.dart';
import 'package:sakuramedia/features/clips/data/dto/media_clip_dto.dart';
import 'package:sakuramedia/features/clips/presentation/providers/clip_mutation_events_provider.dart';
import 'package:sakuramedia/features/clips/presentation/providers/clips_api_provider.dart';
import 'package:sakuramedia/features/clips/presentation/widgets/rename_clip_dialog.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_clips_provider.dart';
import 'package:sakuramedia/widgets/base/feedback/app_confirm_dialog.dart';
import 'package:sakuramedia/widgets/domain/clips/clip_player_dialog.dart';

/// 影片详情页「切片」区块的交互动作集合，供桌面 / 移动两端详情页 `with` 复用，
/// 避免播放 / 改名 / 删除 / 加入合集这套 handler 在两端逐行重复。
///
/// 这些动作离不开 `BuildContext`（弹窗 / 确认框），故留在页面侧；数据状态由
/// `movieClipsProvider(movieNumber)` 持有。删除成功后广播
/// `clipMutationEventsProvider`，provider 内部 `ref.listen` 后就地移除
/// （无需手动回写），同时让「我的切片」页同步。
mixin MovieClipSectionMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// 子类暴露本页的影片番号（用于取对应 provider 实例）。
  String get movieNumber;

  void playMovieClip(MediaClipDto clip) {
    showClipPlayerDialog(context, streamUrl: clip.streamUrl, title: clip.title);
  }

  Future<void> renameMovieClip(MediaClipDto clip) async {
    final newTitle = await showRenameClipDialog(
      context,
      initialTitle: clip.title,
    );
    if (!mounted || newTitle == null) {
      return;
    }
    try {
      final updated = await ref
          .read(clipsApiProvider)
          .updateClipTitle(clipId: clip.clipId, title: newTitle);
      if (!mounted) return;
      ref.read(movieClipsProvider(movieNumber).notifier).replaceClip(updated);
      showToast('已重命名');
    } catch (error) {
      showToast(apiErrorMessage(error, fallback: '重命名失败，请重试'));
    }
  }

  Future<void> deleteMovieClip(MediaClipDto clip) async {
    final title = clip.title.trim().isEmpty ? '该切片' : '“${clip.title.trim()}”';
    final confirmed = await showAppConfirmDialog(
      context,
      title: '删除切片',
      message: '确认删除$title？切片文件会被一并删除，该操作不可恢复。',
      danger: true,
      confirmLabel: '删除',
      confirmKey: const Key('movie-clip-delete-confirm-button'),
    );
    if (!mounted || !confirmed) {
      return;
    }
    try {
      await ref.read(clipsApiProvider).deleteClip(clipId: clip.clipId);
      if (!mounted) return;
      // 广播删除：本页 provider 与「我的切片」页监听后各自就地移除。
      ref
          .read(clipMutationEventsProvider.notifier)
          .reportDeleted(clip.clipId);
      showToast('已删除切片');
    } catch (error) {
      showToast(apiErrorMessage(error, fallback: '删除失败，请重试'));
    }
  }

  Future<void> addMovieClipToCollection(MediaClipDto clip) async {
    await showAddToClipCollectionDialog(context, clipId: clip.clipId);
    if (!mounted) {
      return;
    }
    // 合集归属可能变化（含新建）：广播信号，由切片各页统一刷新合集区。
    ref
        .read(clipMutationEventsProvider.notifier)
        .reportCollectionMembershipChanged(clipId: clip.clipId);
  }
}
