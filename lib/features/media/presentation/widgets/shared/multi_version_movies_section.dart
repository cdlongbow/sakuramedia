import 'dart:async';

import 'package:sakuramedia/widgets/base/actions/app_switch.dart';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_api_provider.dart';
import 'package:sakuramedia/widgets/base/interaction/selection/app_selection_toolbar.dart';
import 'package:sakuramedia/widgets/base/interaction/selection/app_selection_bottom_bar.dart';
import 'package:sakuramedia/widgets/base/operations/batch/batch_progress_dialog.dart';
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

class MultiVersionMoviesSection extends HookConsumerWidget {
  const MultiVersionMoviesSection({
    super.key,
    required this.scrollController,
    required this.keyPrefix,
    required this.mobile,
    required this.onOpenMovieDetail,
    required this.includeVr,
    required this.includeFc2,
  });

  final ValueNotifier<bool> includeVr;
  final ValueNotifier<bool> includeFc2;
  final ScrollController scrollController;
  final String keyPrefix;
  final bool mobile;
  final void Function(BuildContext, String) onOpenMovieDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = multiVersionMoviesProvider(
      includeVr: includeVr.value,
      includeFc2: includeFc2.value,
    );
    final asyncState = ref.watch(provider);
    final spacing = context.appSpacing;
    final selectionMode = useState(false);
    final selectedIds = useState(<int>{});
    final deleting = useState(false);
    final groups = asyncState.value?.items ?? const <MultiVersionMovieDto>[];
    final selected = [
      for (final group in groups)
        for (final item in group.mediaItems)
          if (selectedIds.value.contains(item.id)) item,
    ];
    void exitSelection() {
      selectionMode.value = false;
      selectedIds.value = {};
    }

    Future<void> deleteSelected() async {
      if (deleting.value || selected.isEmpty) return;
      final confirmed = await showAppConfirmDialog(
        context,
        title: '批量删除影片版本',
        message: '将删除选中的 ${selected.length} 个版本及对应文件，每部影片至少保留一个版本。确认继续？',
        confirmLabel: '删除',
        danger: true,
        dialogKey: Key('$keyPrefix-versions-batch-confirm-dialog'),
        confirmKey: Key('$keyPrefix-versions-batch-confirm'),
      );
      if (!confirmed || !context.mounted) return;
      final currentGroups = ref.read(provider).value?.items ?? [];
      final ids = selected.map((item) => item.id).toSet();
      final currentIds = currentGroups
          .expand((group) => group.mediaItems)
          .map((item) => item.id)
          .toSet();
      if (!currentIds.containsAll(ids) ||
          currentGroups.any(
            (group) => group.mediaItems.every((item) => ids.contains(item.id)),
          )) {
        exitSelection();
        showToast('影片版本已变化，请重新选择，至少保留一个版本');
        return;
      }
      deleting.value = true;
      final notifier = ref.read(provider.notifier);
      final api = ref.read(mediaApiProvider);
      try {
        final result = await runBatchOperation<MediaListItemDto>(
          context,
          title: '正在删除影片版本',
          items: selected,
          action: (item) => api.deleteMedia(mediaId: item.id),
        );
        await notifier.refreshAfterDelete(result.succeeded);
        if (!context.mounted) return;
        selectedIds.value = result.failed.map((item) => item.id).toSet();
        if (result.failed.isEmpty) exitSelection();
        if (scrollController.hasClients) scrollController.jumpTo(0);
      } finally {
        if (context.mounted) deleting.value = false;
      }
    }

    final deleteButton = AppButton(
      key: Key('$keyPrefix-versions-batch-delete'),
      label: '删除已选',
      icon: const Icon(Icons.delete_outline_rounded),
      variant: AppButtonVariant.danger,
      size: mobile ? AppButtonSize.medium : AppButtonSize.small,
      isLoading: deleting.value,
      onPressed: selected.isEmpty || deleting.value ? null : deleteSelected,
    );

    Future<void> refresh() async {
      final message = await ref.read(provider.notifier).refresh();
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
          await ref.read(provider.notifier).deleteVersion(item);
          if (scrollController.hasClients) scrollController.jumpTo(0);
        },
        failureFallback: '删除影片版本失败',
      );
      if (confirmed && context.mounted) showToast('影片版本已删除');
    }

    final content = AppFixedHeaderLayout(
      header: selectionMode.value
          ? AppSelectionHeaderToolbar(
              countLabel: '已选 ${selected.length} 个',
              countKey: Key('$keyPrefix-versions-selected-count'),
              selectAllLabel: '清空',
              selectAllKey: Key('$keyPrefix-versions-clear-selection'),
              onToggleAll: deleting.value || selected.isEmpty
                  ? null
                  : () => selectedIds.value = {},
              actions: mobile ? [] : [deleteButton],
              exitKey: Key('$keyPrefix-versions-exit-selection'),
              onExit: deleting.value ? null : exitSelection,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppFilterTotalHeader(
                  leading: Text(
                    '影片筛选',
                    style: resolveAppTextStyle(
                      context,
                      size: AppTextSize.s12,
                      weight: AppTextWeight.regular,
                      tone: AppTextTone.secondary,
                    ),
                  ),
                  totalText: '共 ${asyncState.value?.total ?? 0} 部',
                  totalKey: Key('$keyPrefix-versions-total'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppSelectionEntryButton(
                        key: Key('$keyPrefix-versions-select'),
                        onPressed: groups.isEmpty
                            ? null
                            : () => selectionMode.value = true,
                      ),
                      SizedBox(width: spacing.sm),
                      AppIconButton(
                        key: Key('$keyPrefix-versions-refresh'),
                        tooltip: '刷新',
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: asyncState.isLoading ? null : refresh,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: spacing.md),
                  child: Wrap(
                    spacing: spacing.lg,
                    runSpacing: spacing.sm,
                    children: [
                      for (final filter in [
                        (label: '包含 VR', state: includeVr, key: 'vr'),
                        (label: '包含 FC2', state: includeFc2, key: 'fc2'),
                      ])
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              filter.label,
                              style: resolveAppTextStyle(
                                context,
                                size: AppTextSize.s12,
                                weight: AppTextWeight.regular,
                                tone: AppTextTone.secondary,
                              ),
                            ),
                            SizedBox(width: spacing.sm),
                            AppSwitch(
                              key: Key(
                                '$keyPrefix-versions-include-${filter.key}',
                              ),
                              value: filter.state.value,
                              onChanged: (value) {
                                exitSelection();
                                filter.state.value = value;
                                if (scrollController.hasClients) {
                                  scrollController.jumpTo(0);
                                }
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
      child: CustomScrollView(
        key: Key('$keyPrefix-versions-scroll'),
        controller: scrollController,
        slivers: [
          if (selectionMode.value)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: spacing.md),
                child: Text(
                  '请选择要删除的版本，每部影片至少保留一个',
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s12,
                    weight: AppTextWeight.regular,
                    tone: AppTextTone.secondary,
                  ),
                ),
              ),
            ),
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
            onReload: () => unawaited(ref.read(provider.notifier).reload()),
            onLoadMore: () => unawaited(ref.read(provider.notifier).loadMore()),
            itemBuilder: (context, group, index) => _MovieVersionCard(
              key: Key('$keyPrefix-version-group-${group.movieNumber}'),
              group: group,
              keyPrefix: keyPrefix,
              mobile: mobile,
              onOpen: () => onOpenMovieDetail(context, group.movieNumber),
              onDelete: (item) => unawaited(deleteVersion(group, item)),
              selectedIds: selectionMode.value ? selectedIds.value : null,
              onToggle: (item) {
                final next = {...selectedIds.value};
                if (!next.remove(item.id)) {
                  if (group.mediaItems
                          .where((media) => next.contains(media.id))
                          .length >=
                      group.mediaItems.length - 1) {
                    return;
                  }
                  next.add(item.id);
                }
                selectedIds.value = next;
              },
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: spacing.xxl)),
        ],
      ),
    );
    return Column(
      children: [
        Expanded(child: content),
        if (mobile && selectionMode.value)
          AppSelectionBottomBar(actions: [deleteButton]),
      ],
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
    required this.selectedIds,
    required this.onToggle,
  });

  final MultiVersionMovieDto group;
  final String keyPrefix;
  final bool mobile;
  final VoidCallback onOpen;
  final ValueChanged<MediaListItemDto> onDelete;
  final Set<int>? selectedIds;
  final ValueChanged<MediaListItemDto> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final tokens = context.appComponentTokens;
    final movie = group.mediaItems.first;
    final selectionLimitReached =
        group.mediaItems
            .where((item) => selectedIds?.contains(item.id) ?? false)
            .length >=
        group.mediaItems.length - 1;
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
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: Key('$keyPrefix-version-row-${item.id}'),
                borderRadius: context.appRadius.mdBorder,
                onTap:
                    selectedIds == null ||
                        (selectionLimitReached &&
                            !selectedIds!.contains(item.id))
                    ? null
                    : () => onToggle(item),
                child: IgnorePointer(
                  ignoring: selectedIds != null,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectedIds != null) ...[
                        Tooltip(
                          message:
                              selectionLimitReached &&
                                  !selectedIds!.contains(item.id)
                              ? '至少保留一个版本'
                              : '选择此版本',
                          child: Checkbox(
                            key: Key('$keyPrefix-version-select-${item.id}'),
                            value: selectedIds!.contains(item.id),
                            onChanged:
                                selectionLimitReached &&
                                    !selectedIds!.contains(item.id)
                                ? null
                                : (_) => onToggle(item),
                          ),
                        ),
                        SizedBox(width: spacing.sm),
                      ],
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
                      if (!mobile && selectedIds == null) ...[
                        SizedBox(width: spacing.lg),
                        _deleteButton(item),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (mobile && selectedIds == null) ...[
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
