import 'dart:async';

import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';
import 'package:sakuramedia/widgets/base/navigation/app_list_header.dart';
import 'package:sakuramedia/widgets/base/navigation/app_mobile_filter_drawer_scaffold.dart';
import 'package:sakuramedia/widgets/base/overlays/app_bottom_drawer.dart';
import 'package:sakuramedia/widgets/base/overlays/app_filter_popover.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_api_provider.dart';
import 'package:sakuramedia/widgets/base/interaction/selection/app_selection_toolbar.dart';
import 'package:sakuramedia/widgets/base/interaction/selection/app_selection_bottom_bar.dart';
import 'package:sakuramedia/widgets/base/operations/batch/batch_progress_dialog.dart';
import 'package:sakuramedia/features/media/data/media_list_item_dto.dart';
import 'package:sakuramedia/features/media/data/multi_version_movie_dto.dart';
import 'package:sakuramedia/features/media/presentation/media_placeholders.dart';
import 'package:sakuramedia/features/media/presentation/providers/multi_version_movies_provider.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_file_group_card.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';
import 'package:sakuramedia/features/shared/presentation/widgets/paged_async_section.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';
import 'package:sakuramedia/widgets/base/feedback/app_confirm_dialog.dart';
import 'package:sakuramedia/widgets/base/feedback/app_skeletonizer.dart';
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

    Widget filterOptions(BuildContext context) => HookBuilder(
      builder: (context) {
        useListenable(includeVr);
        useListenable(includeFc2);
        return Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.sm,
          children: [
            for (final filter in [
              (label: '包含 VR', state: includeVr, key: 'vr'),
              (label: '包含 FC2', state: includeFc2, key: 'fc2'),
            ])
              AppTextButton(
                key: Key('$keyPrefix-versions-include-${filter.key}'),
                label: filter.label,
                size: AppTextButtonSize.xSmall,
                isSelected: filter.state.value,
                onPressed: () {
                  exitSelection();
                  filter.state.value = !filter.state.value;
                  if (scrollController.hasClients) scrollController.jumpTo(0);
                },
              ),
          ],
        );
      },
    );

    Widget filterFooter() => HookBuilder(
      builder: (context) {
        useListenable(includeVr);
        useListenable(includeFc2);
        return AppFilterPanelFooter(
          isDefault: !includeVr.value && !includeFc2.value,
          onReset: () {
            includeVr.value = false;
            includeFc2.value = false;
            if (scrollController.hasClients) scrollController.jumpTo(0);
          },
        );
      },
    );

    Widget buildGroup(BuildContext context, MultiVersionMovieDto group) {
      return MediaFileGroupCard(
        key: Key('$keyPrefix-version-group-${group.movieNumber}'),
        items: group.mediaItems,
        countLabel: '${group.mediaCount} 个版本',
        headerKey: Key('$keyPrefix-version-movie-${group.movieNumber}'),
        deleteLabel: '删除此版本',
        keyPrefix: '$keyPrefix-version',
        mobile: mobile,
        onOpen: () => onOpenMovieDetail(context, group.movieNumber),
        onDelete: (item) => unawaited(deleteVersion(group, item)),
        selectedIds: selectionMode.value ? selectedIds.value : null,
        onToggle: (item) {
          final next = {...selectedIds.value};
          if (!next.remove(item.id)) next.add(item.id);
          selectedIds.value = next;
        },
      );
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
          : AppListHeader(
              filterButtonKey: Key('$keyPrefix-versions-filter'),
              filterLabel: !includeVr.value && !includeFc2.value
                  ? '筛选'
                  : [
                      if (includeVr.value) 'VR',
                      if (includeFc2.value) 'FC2',
                    ].join(' / '),
              filterPanelKey: Key('$keyPrefix-versions-filter-panel'),
              filterPanelBuilder: mobile ? null : filterOptions,
              filterPanelFooter: mobile ? null : filterFooter(),
              onFilterTap: mobile
                  ? () => showAppBottomDrawer(
                      context: context,
                      drawerKey: Key('$keyPrefix-versions-filter-drawer'),
                      maxHeightFactor: 0.8,
                      builder: (context) => AppMobileFilterDrawerScaffold(
                        footer: filterFooter(),
                        child: filterOptions(context),
                      ),
                    )
                  : null,
              informationSlots: [
                AppListHeaderInfo(
                  key: Key('$keyPrefix-versions-total'),
                  label: '共 ${asyncState.value?.total ?? 0} 部',
                ),
              ],
              actionSlots: [
                AppSelectionEntryButton(
                  key: Key('$keyPrefix-versions-select'),
                  onPressed: groups.isEmpty
                      ? null
                      : () => selectionMode.value = true,
                ),
                AppIconButton(
                  key: Key('$keyPrefix-versions-refresh'),
                  tooltip: '刷新',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: asyncState.isLoading ? null : refresh,
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
            // loading 用占位分组渲染真实组卡，由 [AppSkeletonizer] 灰化。
            skeletonBuilder: (context) {
              final placeholders = multiVersionMoviePlaceholders();
              return AppSkeletonizer(
                enabled: true,
                child: Column(
                  children: [
                    for (var index = 0;
                        index < placeholders.length;
                        index++) ...[
                      if (index > 0) SizedBox(height: spacing.lg),
                      buildGroup(context, placeholders[index]),
                    ],
                  ],
                ),
              );
            },
            initialRetryKey: Key('$keyPrefix-versions-retry'),
            onReload: () => unawaited(ref.read(provider.notifier).reload()),
            onLoadMore: () => unawaited(ref.read(provider.notifier).loadMore()),
            itemBuilder: (context, group, index) =>
                buildGroup(context, group),
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
