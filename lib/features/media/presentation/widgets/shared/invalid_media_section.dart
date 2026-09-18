import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_fixed_header_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/configuration/data/dto/media_library_dto.dart';
import 'package:sakuramedia/features/media/data/invalid_media_dto.dart';
import 'package:sakuramedia/features/media/data/media_list_item_dto.dart';
import 'package:sakuramedia/features/media/presentation/providers/invalid_media_provider.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_libraries_provider.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_list_item_card.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_list_item_card_skeleton.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';
import 'package:sakuramedia/features/shared/presentation/widgets/paged_async_section.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';
import 'package:sakuramedia/widgets/base/feedback/app_confirm_dialog.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_filter_total_header.dart';

/// 「失效媒体」列表：后端只提供列表和删除，因此每条记录直接允许删除。
class InvalidMediaSection extends StatelessWidget {
  const InvalidMediaSection({
    super.key,
    required this.scrollController,
    this.mobile = false,
  });

  final ScrollController scrollController;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return AppFixedHeaderLayout(
      header: _InvalidMediaHeader(),
      child: CustomScrollView(
        key: const Key('invalid-media-scroll-view'),
        controller: scrollController,
        slivers: [
          _InvalidMediaBodySliver(mobile: mobile),
          SliverToBoxAdapter(child: SizedBox(height: context.appSpacing.xxl)),
        ],
      ),
    );
  }
}

class _InvalidMediaHeader extends ConsumerWidget {
  const _InvalidMediaHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headerState = ref.watch(
      invalidMediaProvider.select(
        (asyncState) => (
          total: asyncState.value?.paged.total ?? 0,
          isInitialLoading: asyncState.isLoading && !asyncState.hasValue,
        ),
      ),
    );
    return AppFilterTotalHeader(
      leading: Text(
        '巡检标记为失效的媒体会出现在这里。确认是真实丢失的文件，可删除记录，jav影片会再次自动下载新的资源。',
        key: const Key('invalid-media-section-description'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: resolveAppTextStyle(
          context,
          size: AppTextSize.s12,
          weight: AppTextWeight.regular,
          tone: AppTextTone.muted,
        ),
      ),
      totalText: '共 ${headerState.total} 条失效媒体',
      totalKey: const Key('invalid-media-total-text'),
      trailing: AppIconButton(
        key: const Key('invalid-media-refresh-button'),
        tooltip: headerState.isInitialLoading ? '刷新中' : '刷新',
        icon: const Icon(Icons.refresh_rounded),
        onPressed: headerState.isInitialLoading
            ? null
            : () async {
                final message = await ref
                    .read(invalidMediaProvider.notifier)
                    .refresh();
                if (message != null) showToast(message);
              },
      ),
    );
  }
}

class _InvalidMediaBodySliver extends ConsumerWidget {
  const _InvalidMediaBodySliver({required this.mobile});

  final bool mobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPaged = ref.watch(
      invalidMediaProvider.select(
        (asyncState) => asyncState.whenData((state) => state.paged),
      ),
    );
    return SliverPagedAsyncSection<
      PagedListState<InvalidMediaDto>,
      InvalidMediaDto
    >(
      asyncState: asyncPaged,
      pagedOf: (state) => state,
      itemSpacing: context.appSpacing.md,
      initialErrorMessage: '失效媒体加载失败，请稍后重试',
      emptyMessage: '当前没有失效媒体',
      skeletonBuilder: (context) => MediaListItemCardSkeletonList(
        mobile: mobile,
        itemSpacing: context.appSpacing.md,
      ),
      initialRetryKey: const Key('invalid-media-initial-retry-button'),
      onReload: () =>
          unawaited(ref.read(invalidMediaProvider.notifier).reload()),
      onLoadMore: () =>
          unawaited(ref.read(invalidMediaProvider.notifier).loadMore()),
      itemBuilder: (context, item, _) =>
          _InvalidMediaRowConsumer(item: item, mobile: mobile),
    );
  }
}

class _InvalidMediaRowConsumer extends ConsumerWidget {
  const _InvalidMediaRowConsumer({required this.item, required this.mobile});

  final InvalidMediaDto item;
  final bool mobile;

  Future<void> _handleDelete(
    WidgetRef ref,
    BuildContext context,
    InvalidMediaDto item,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: '删除失效媒体',
      message: '确认删除“${item.displayTitle}”的这条失效媒体记录及对应文件？该操作不可恢复。',
      confirmLabel: '删除',
      danger: true,
      dialogKey: const Key('invalid-media-delete-confirm-dialog'),
      confirmKey: const Key('invalid-media-delete-confirm-button'),
      cancelKey: const Key('invalid-media-delete-cancel-button'),
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref
          .read(invalidMediaProvider.notifier)
          .deleteInvalidMedia(mediaId: item.id);
      if (context.mounted) showToast('失效媒体已删除');
    } catch (error) {
      if (context.mounted) {
        showToast(apiErrorMessage(error, fallback: '删除失效媒体失败'));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(
      invalidMediaProvider.select(
        (asyncState) => asyncState.value?.deletingMediaId,
      ),
    );
    final librariesById = ref.watch(
      mediaLibrariesProvider.select(
        (asyncState) =>
            asyncState.value?.librariesById ?? const <int, MediaLibraryDto>{},
      ),
    );
    final library = item.libraryId == null
        ? null
        : librariesById[item.libraryId];
    final isDeleting = actionState == item.id;
    return MediaListItemCard(
      keyPrefix: 'invalid-media',
      item: _toMediaListItem(item),
      library: library,
      mobile: mobile,
      onDelete: () => unawaited(_handleDelete(ref, context, item)),
      isDeleting: isDeleting,
      canDelete: actionState == null,
      showUpdatedAt: true,
    );
  }
}

MediaListItemDto _toMediaListItem(InvalidMediaDto item) {
  final kind = item.videoItemId != null
      ? MediaListItemKind.video
      : item.movieNumber != null
      ? MediaListItemKind.jav
      : MediaListItemKind.unknown;
  return MediaListItemDto(
    id: item.id,
    kind: kind,
    movieNumber: item.movieNumber,
    videoItemId: item.videoItemId,
    title: item.movieTitle,
    coverImage: item.coverImage,
    thinCoverImage: item.thinCoverImage,
    libraryId: item.libraryId,
    libraryName: item.libraryName,
    fileName: item.fileName,
    fileSizeBytes: item.fileSizeBytes,
    durationSeconds: 0,
    valid: false,
    createdAt: null,
    updatedAt: item.updatedAt,
  );
}
