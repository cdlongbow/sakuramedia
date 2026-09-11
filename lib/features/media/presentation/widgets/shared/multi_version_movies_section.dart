import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/features/media/data/media_list_item_dto.dart';
import 'package:sakuramedia/features/media/data/multi_version_movie_dto.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_libraries_provider.dart';
import 'package:sakuramedia/features/media/presentation/providers/multi_version_movies_provider.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_cover_thumbnail.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_list_item_meta_line.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';
import 'package:sakuramedia/features/shared/presentation/widgets/paged_async_section.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';
import 'package:sakuramedia/widgets/base/feedback/app_confirm_dialog.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_badge.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_content_card.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_filter_total_header.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_fixed_header_layout.dart';

class MultiVersionMoviesSection extends ConsumerWidget {
  const MultiVersionMoviesSection({
    super.key,
    required this.scrollController,
    required this.keyPrefix,
    required this.mobile,
    required this.onOpenMovieDetail,
  });

  final ScrollController scrollController;
  final String keyPrefix;
  final bool mobile;
  final void Function(BuildContext, String) onOpenMovieDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(multiVersionMoviesProvider);
    final spacing = context.appSpacing;
    Future<void> refresh() async {
      final message = await ref
          .read(multiVersionMoviesProvider.notifier)
          .refresh();
      if (message != null && context.mounted) showToast(message);
    }

    Future<void> deleteVersion(
      MultiVersionMovieDto group,
      MediaListItemDto item,
    ) async {
      final remaining = group.mediaCount - 1;
      final confirmed = await showAppConfirmDialog(
        context,
        title: '删除影片版本',
        message: '确认删除“${item.fileName}”及对应文件？删除后保留 $remaining 个版本。',
        confirmLabel: '删除',
        danger: true,
        dialogKey: Key('$keyPrefix-version-delete-dialog-${item.id}'),
        confirmKey: Key('$keyPrefix-version-delete-confirm-${item.id}'),
        cancelKey: Key('$keyPrefix-version-delete-cancel-${item.id}'),
        onConfirm: () async {
          await ref
              .read(multiVersionMoviesProvider.notifier)
              .deleteVersion(item);
          if (scrollController.hasClients) scrollController.jumpTo(0);
        },
        failureFallback: '删除影片版本失败',
      );
      if (confirmed && context.mounted) showToast('影片版本已删除');
    }

    return AppFixedHeaderLayout(
      header: AppFilterTotalHeader(
        leading: Text(
          '同一番号的多个媒体',
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s12,
            weight: AppTextWeight.regular,
            tone: AppTextTone.secondary,
          ),
        ),
        totalText: '共 ${asyncState.value?.total ?? 0} 部',
        totalKey: Key('$keyPrefix-versions-total'),
        trailing: AppIconButton(
          key: Key('$keyPrefix-versions-refresh'),
          tooltip: '刷新',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: asyncState.isLoading ? null : refresh,
        ),
      ),
      child: CustomScrollView(
        key: Key('$keyPrefix-versions-scroll'),
        controller: scrollController,
        slivers: [
          SliverPagedAsyncSection<
            PagedListState<MultiVersionMovieDto>,
            MultiVersionMovieDto
          >(
            asyncState: asyncState,
            pagedOf: (state) => state,
            itemSpacing: spacing.lg,
            initialErrorMessage: '多版本影片加载失败，请稍后重试',
            emptyMessage: '暂无多版本影片',
            initialRetryKey: Key('$keyPrefix-versions-retry'),
            onReload: () => unawaited(
              ref.read(multiVersionMoviesProvider.notifier).reload(),
            ),
            onLoadMore: () => unawaited(
              ref.read(multiVersionMoviesProvider.notifier).loadMore(),
            ),
            itemBuilder: (context, group, index) => _MovieVersionCard(
              key: Key('$keyPrefix-version-group-${group.movieNumber}'),
              group: group,
              keyPrefix: keyPrefix,
              mobile: mobile,
              onOpen: () => onOpenMovieDetail(context, group.movieNumber),
              onDelete: (item) => unawaited(deleteVersion(group, item)),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: spacing.xxl)),
        ],
      ),
    );
  }
}

class _MovieVersionCard extends ConsumerWidget {
  const _MovieVersionCard({
    super.key,
    required this.group,
    required this.keyPrefix,
    required this.mobile,
    required this.onOpen,
    required this.onDelete,
  });

  final MultiVersionMovieDto group;
  final String keyPrefix;
  final bool mobile;
  final VoidCallback onOpen;
  final ValueChanged<MediaListItemDto> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final tokens = context.appComponentTokens;
    final movie = group.mediaItems.first;
    final libraries = ref.watch(mediaLibrariesProvider).value?.librariesById;
    return AppContentCard(
      title: group.movieNumber,
      padding: EdgeInsets.all(spacing.lg),
      headerTrailing: AppBadge(
        label: '${group.mediaCount} 个版本',
        tone: AppBadgeTone.neutral,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: Key('$keyPrefix-version-movie-${group.movieNumber}'),
              borderRadius: context.appRadius.mdBorder,
              onTap: onOpen,
              child: Row(
                children: [
                  MediaCoverThumbnail(
                    url: movie.coverImage?.bestAvailableUrl,
                    width: mobile
                        ? tokens.movieDetailPlotThumbnailWidth
                        : tokens.downloadTaskCoverWidth,
                    height: mobile
                        ? tokens.movieDetailPlotThumbnailHeight
                        : tokens.mediaManagementRowHeight,
                    fit: BoxFit.contain,
                    placeholderBackground: context.appColors.surfacePage,
                  ),
                  SizedBox(width: spacing.md),
                  Expanded(
                    child: Text(
                      movie.title ?? group.movieNumber,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: resolveAppTextStyle(
                        context,
                        size: AppTextSize.s14,
                        weight: AppTextWeight.medium,
                        tone: AppTextTone.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: spacing.sm),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.appTextPalette.muted,
                  ),
                ],
              ),
            ),
          ),
          for (final item in group.mediaItems) ...[
            Divider(height: spacing.xl, color: context.appColors.divider),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        item.fileName,
                        key: Key('$keyPrefix-version-file-${item.id}'),
                        style: resolveAppTextStyle(
                          context,
                          size: AppTextSize.s14,
                          weight: AppTextWeight.medium,
                          tone: AppTextTone.primary,
                        ),
                      ),
                      SizedBox(height: spacing.sm),
                      MediaListItemMetaLine(
                        item: item,
                        library: libraries?[item.libraryId],
                        spacing: spacing.sm,
                        runSpacing: spacing.xs,
                      ),
                      if (!item.valid) ...[
                        SizedBox(height: spacing.sm),
                        const AppBadge(
                          label: '失效',
                          tone: AppBadgeTone.error,
                          size: AppBadgeSize.compact,
                        ),
                      ],
                    ],
                  ),
                ),
                if (!mobile) ...[
                  SizedBox(width: spacing.lg),
                  _deleteButton(item),
                ],
              ],
            ),
            if (mobile) ...[
              SizedBox(height: spacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: _deleteButton(item),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _deleteButton(MediaListItemDto item) => AppButton(
    key: Key('$keyPrefix-version-delete-${item.id}'),
    label: '删除此版本',
    size: AppButtonSize.small,
    variant: AppButtonVariant.danger,
    icon: const Icon(Icons.delete_outline_rounded),
    onPressed: () => onDelete(item),
  );
}
