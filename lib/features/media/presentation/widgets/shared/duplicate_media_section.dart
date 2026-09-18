import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/features/media/data/duplicate_media_group_dto.dart';
import 'package:sakuramedia/features/media/data/media_list_item_dto.dart';
import 'package:sakuramedia/features/media/presentation/providers/duplicate_media_provider.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_browse_provider.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_file_group_card.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_file_group_card_skeleton.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';
import 'package:sakuramedia/features/shared/presentation/widgets/paged_async_section.dart';
import 'package:sakuramedia/features/videos/presentation/widgets/listing/video_collection_chips.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';
import 'package:sakuramedia/widgets/base/feedback/app_confirm_dialog.dart';
import 'package:sakuramedia/widgets/base/interaction/selection/app_selection_toolbar.dart';
import 'package:sakuramedia/widgets/base/interaction/selection/app_selection_bottom_bar.dart';
import 'package:sakuramedia/widgets/base/operations/batch/batch_progress_dialog.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_fixed_header_layout.dart';
import 'package:sakuramedia/widgets/base/navigation/app_list_header.dart';
import 'package:sakuramedia/widgets/base/navigation/app_mobile_filter_drawer_scaffold.dart';
import 'package:sakuramedia/widgets/base/overlays/app_bottom_drawer.dart';
import 'package:sakuramedia/widgets/base/overlays/app_filter_popover.dart';

class DuplicateMediaSection extends HookConsumerWidget {
  const DuplicateMediaSection({
    super.key,
    required this.scrollController,
    required this.kind,
    required this.onKindChanged,
    required this.keyPrefix,
    required this.mobile,
    required this.onRefresh,
    required this.onOpenVideoCollectionDetail,
    this.onOpenMovieDetail,
  });

  final ScrollController scrollController;
  final MediaListItemKind kind;
  final ValueChanged<MediaListItemKind> onKindChanged;
  final String keyPrefix;
  final bool mobile;
  final Future<void> Function() onRefresh;
  final void Function(BuildContext context, int collectionId)
  onOpenVideoCollectionDetail;
  final void Function(BuildContext context, String movieNumber)?
  onOpenMovieDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = duplicateMediaProvider(kind);
    final asyncState = ref.watch(provider);
    final groups = asyncState.value?.items ?? const <DuplicateMediaGroupDto>[];
    final spacing = context.appSpacing;
    final selectionMode = useState(false);
    final selectedIds = useState(<int>{});
    final deleting = useState(false);
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
        title: '批量删除重复媒体',
        message: '将删除选中的 ${selected.length} 项媒体及对应文件，每组至少保留一个副本。确认继续？',
        confirmLabel: '删除',
        danger: true,
        dialogKey: Key('$keyPrefix-duplicates-batch-confirm-dialog'),
        confirmKey: Key('$keyPrefix-duplicates-batch-confirm'),
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
        showToast('重复媒体已变化，请重新选择，至少保留一个副本');
        return;
      }
      deleting.value = true;
      final notifier = ref.read(provider.notifier);
      final browseNotifier = ref.read(mediaBrowseProvider.notifier);
      try {
        final result = await runBatchOperation<MediaListItemDto>(
          context,
          title: '正在删除重复媒体',
          items: selected,
          action: (item) async {
            await notifier.deleteDuplicateMedia(mediaId: item.id);
            browseNotifier.removeItemsByIds([item.id]);
          },
        );
        if (!context.mounted) return;
        selectedIds.value = result.failed.map((item) => item.id).toSet();
        if (result.failed.isEmpty) exitSelection();
        if (scrollController.hasClients) scrollController.jumpTo(0);
      } finally {
        if (context.mounted) deleting.value = false;
      }
    }

    final deleteButton = AppButton(
      key: Key('$keyPrefix-duplicates-batch-delete'),
      label: '删除已选',
      icon: const Icon(Icons.delete_outline_rounded),
      variant: AppButtonVariant.danger,
      size: mobile ? AppButtonSize.medium : AppButtonSize.small,
      isLoading: deleting.value,
      onPressed: selected.isEmpty || deleting.value ? null : deleteSelected,
    );

    Future<void> deleteMedia(
      DuplicateMediaGroupDto group,
      MediaListItemDto item,
    ) async {
      final remainingCount = group.mediaItems.length - 1;
      final remainingHint = remainingCount >= 2
          ? '删除后该组还会保留 $remainingCount 项媒体。'
          : '删除后该组将不再属于重复媒体。';
      final confirmed = await showAppConfirmDialog(
        context,
        title: '删除重复媒体',
        message: '确认删除“${item.fileName}”及对应文件？$remainingHint',
        confirmLabel: '删除',
        danger: true,
        dialogKey: Key('$keyPrefix-duplicate-delete-dialog-${item.id}'),
        confirmKey: Key(
          '$keyPrefix-duplicate-delete-confirm-button-${item.id}',
        ),
        cancelKey: Key('$keyPrefix-duplicate-delete-cancel-button-${item.id}'),
        onConfirm: () async {
          await ref
              .read(duplicateMediaProvider(kind).notifier)
              .deleteDuplicateMedia(mediaId: item.id);
          ref.read(mediaBrowseProvider.notifier).removeItemsByIds([item.id]);
        },
        failureFallback: '删除重复媒体失败',
      );
      if (confirmed && context.mounted) {
        showToast('重复媒体已删除');
      }
    }

    final content = AppFixedHeaderLayout(
      header: selectionMode.value
          ? AppSelectionHeaderToolbar(
              countLabel: '已选 ${selected.length} 个',
              countKey: Key('$keyPrefix-duplicates-selected-count'),
              selectAllLabel: '清空',
              selectAllKey: Key('$keyPrefix-duplicates-clear-selection'),
              onToggleAll: deleting.value || selected.isEmpty
                  ? null
                  : () => selectedIds.value = {},
              actions: mobile ? [] : [deleteButton],
              exitKey: Key('$keyPrefix-duplicates-exit-selection'),
              onExit: deleting.value ? null : exitSelection,
            )
          : _DuplicateMediaHeader(
              mobile: mobile,
              kind: kind,
              keyPrefix: keyPrefix,
              onKindChanged: (next) {
                exitSelection();
                onKindChanged(next);
              },
              onRefresh: onRefresh,
              onSelect: groups.isEmpty
                  ? null
                  : () => selectionMode.value = true,
            ),
      child: CustomScrollView(
        key: Key('$keyPrefix-duplicate-scroll-view'),
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: spacing.md),
              child: Text(
                selectionMode.value
                    ? '请选择要删除的媒体，每组至少保留一个副本'
                    : '按文件内容指纹聚合同一文件的媒体记录。删除前请确认至少保留一个可用副本。',
                key: Key('$keyPrefix-duplicate-description'),
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
            PagedListState<DuplicateMediaGroupDto>,
            DuplicateMediaGroupDto
          >(
            asyncState: asyncState,
            pagedOf: (state) => state,
            itemSpacing: spacing.lg,
            initialErrorMessage: '重复媒体加载失败，请稍后重试',
            emptyMessage: '当前类型没有发现重复文件。',
            skeletonBuilder: (context) =>
                MediaFileGroupCardSkeleton(mobile: mobile),
            initialRetryKey: Key('$keyPrefix-duplicate-initial-retry-button'),
            onReload: () => unawaited(ref.read(provider.notifier).reload()),
            onLoadMore: () => unawaited(ref.read(provider.notifier).loadMore()),
            itemBuilder: (context, group, index) {
              if (group.mediaItems.isEmpty) return const SizedBox.shrink();
              final first = group.mediaItems.first;
              return MediaFileGroupCard(
                key: Key('$keyPrefix-duplicate-group-${first.id}'),
                items: group.mediaItems,
                countLabel: '${group.mediaCount} 个副本',
                headerKey: Key('$keyPrefix-duplicate-cover-tap-${first.id}'),
                deleteLabel: '删除此项',
                keyPrefix: '$keyPrefix-duplicate',
                mobile: mobile,
                onOpen:
                    first.isJav &&
                        first.movieNumber != null &&
                        onOpenMovieDetail != null
                    ? () => onOpenMovieDetail!(context, first.movieNumber!)
                    : null,
                onDelete: (item) => unawaited(deleteMedia(group, item)),
                selectedIds: selectionMode.value ? selectedIds.value : null,
                onToggle: (item) {
                  final next = {...selectedIds.value};
                  if (!next.remove(item.id)) next.add(item.id);
                  selectedIds.value = next;
                },
                itemSupplement: (item) {
                  if (item.displayHeading == first.displayHeading &&
                      (!item.isVideo || item.collections.isEmpty)) {
                    return null;
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.displayHeading != first.displayHeading)
                        if (item.isJav &&
                            item.movieNumber != null &&
                            onOpenMovieDetail != null)
                          AppTextButton(
                            label: item.displayHeading,
                            onPressed: () =>
                                onOpenMovieDetail!(context, item.movieNumber!),
                          )
                        else
                          Text(
                            item.displayHeading,
                            style: resolveAppTextStyle(
                              context,
                              size: AppTextSize.s12,
                              weight: AppTextWeight.medium,
                              tone: AppTextTone.secondary,
                            ),
                          ),
                      if (item.isVideo && item.collections.isNotEmpty) ...[
                        Text(
                          '所属合集',
                          key: Key(
                            'duplicate-media-collections-title-${item.id}',
                          ),
                          style: resolveAppTextStyle(
                            context,
                            size: AppTextSize.s12,
                            weight: AppTextWeight.medium,
                            tone: AppTextTone.secondary,
                          ),
                        ),
                        SizedBox(height: spacing.xs),
                        VideoCollectionChips(
                          collections: item.collections,
                          onCollectionTap: (collection) =>
                              onOpenVideoCollectionDetail(
                                context,
                                collection.id,
                              ),
                        ),
                      ],
                    ],
                  );
                },
              );
            },
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

class _DuplicateMediaHeader extends HookConsumerWidget {
  const _DuplicateMediaHeader({
    required this.mobile,
    required this.kind,
    required this.keyPrefix,
    required this.onKindChanged,
    required this.onRefresh,
    required this.onSelect,
  });

  final bool mobile;
  final MediaListItemKind kind;
  final String keyPrefix;
  final ValueChanged<MediaListItemKind> onKindChanged;
  final Future<void> Function() onRefresh;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(duplicateMediaProvider(kind));
    final total = asyncState.value?.total ?? 0;
    final isInitialLoading = asyncState.isLoading && !asyncState.hasValue;
    final selectedKind = useState(kind);
    void applyKind(MediaListItemKind next) {
      selectedKind.value = next;
      onKindChanged(next);
    }

    Widget filterOptions(BuildContext context) => HookBuilder(
      builder: (context) {
        useListenable(selectedKind);
        return Wrap(
          spacing: context.appSpacing.sm,
          runSpacing: context.appSpacing.sm,
          children: [
            for (final option in [
              MediaListItemKind.jav,
              MediaListItemKind.video,
            ])
              AppTextButton(
                key: Key('$keyPrefix-duplicate-kind-${option.name}'),
                label: option.label,
                size: AppTextButtonSize.xSmall,
                isSelected: selectedKind.value == option,
                onPressed: () => applyKind(option),
              ),
          ],
        );
      },
    );

    Widget filterFooter() => HookBuilder(
      builder: (context) {
        useListenable(selectedKind);
        return AppFilterPanelFooter(
          isDefault: selectedKind.value == MediaListItemKind.jav,
          onReset: () => applyKind(MediaListItemKind.jav),
        );
      },
    );

    return AppListHeader(
      filterButtonKey: Key('$keyPrefix-duplicates-filter'),
      filterLabel: kind.label,
      filterPanelKey: Key('$keyPrefix-duplicates-filter-panel'),
      filterPanelBuilder: mobile ? null : filterOptions,
      filterPanelFooter: mobile ? null : filterFooter(),
      onFilterTap: mobile
          ? () => showAppBottomDrawer(
              context: context,
              drawerKey: Key('$keyPrefix-duplicates-filter-drawer'),
              maxHeightFactor: 0.8,
              builder: (context) => AppMobileFilterDrawerScaffold(
                footer: filterFooter(),
                child: filterOptions(context),
              ),
            )
          : null,
      informationSlots: [
        AppListHeaderInfo(
          key: Key('$keyPrefix-duplicate-total-text'),
          label: '共 $total 组',
        ),
      ],
      actionSlots: [
        AppSelectionEntryButton(
          key: Key('$keyPrefix-duplicates-select'),
          onPressed: onSelect,
        ),
        AppIconButton(
          key: Key('$keyPrefix-duplicate-refresh-button'),
          tooltip: isInitialLoading ? '刷新中' : '刷新',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: isInitialLoading ? null : onRefresh,
        ),
      ],
    );
  }
}
