import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/configuration/data/dto/media_library_dto.dart';
import 'package:sakuramedia/features/media/data/invalid_media_dto.dart';
import 'package:sakuramedia/features/media/data/media_list_item_dto.dart';
import 'package:sakuramedia/features/media/presentation/media_placeholders.dart';
import 'package:sakuramedia/features/media/presentation/providers/invalid_media_provider.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_libraries_provider.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_list_item_card.dart';
import 'package:sakuramedia/features/shared/presentation/providers/paged_async_notifier.dart';
import 'package:sakuramedia/features/shared/presentation/widgets/paged_async_section.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';
import 'package:sakuramedia/widgets/base/feedback/app_confirm_dialog.dart';
import 'package:sakuramedia/widgets/base/feedback/app_skeletonizer.dart';
import 'package:sakuramedia/widgets/base/interaction/selection/app_selection_bottom_bar.dart';
import 'package:sakuramedia/widgets/base/interaction/selection/app_selection_toolbar.dart';
import 'package:sakuramedia/widgets/base/interaction/selection/multi_select_state_mixin.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_filter_total_header.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_fixed_header_layout.dart';
import 'package:sakuramedia/widgets/base/navigation/app_list_header.dart';
import 'package:sakuramedia/widgets/base/operations/batch/batch_progress_dialog.dart';

/// 「失效媒体」列表：后端只提供列表和删除，因此每条记录直接允许删除；
/// 支持多选批量删除（桌面点卡片即选中，移动长按进入选择态）。
class InvalidMediaSection extends ConsumerStatefulWidget {
  const InvalidMediaSection({
    super.key,
    required this.scrollController,
    this.mobile = false,
  });

  final ScrollController scrollController;
  final bool mobile;

  @override
  ConsumerState<InvalidMediaSection> createState() =>
      _InvalidMediaSectionState();
}

class _InvalidMediaSectionState extends ConsumerState<InvalidMediaSection>
    with MultiSelectStateMixin<InvalidMediaSection, int> {
  @override
  Widget build(BuildContext context) {
    final content = AppFixedHeaderLayout(
      header: _InvalidMediaHeader(
        mobile: widget.mobile,
        selectionMode: widget.mobile && selectionMode,
        selectedIds: selectedIds,
        isAllSelected: (ids) => isAllSelected(ids),
        onExitSelection: exitSelection,
        onToggleAll: toggleSelectAll,
        onBatchDelete: _batchDelete,
      ),
      child: CustomScrollView(
        key: const Key('invalid-media-scroll-view'),
        controller: widget.scrollController,
        slivers: [
          _InvalidMediaBodySliver(
            mobile: widget.mobile,
            selectionMode: widget.mobile && selectionMode,
            selectedIds: selectedIds,
            onToggleSelect: toggleSelect,
            onEnterSelection: (id) {
              enterSelection();
              toggleSelect(id);
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: context.appSpacing.xxl)),
        ],
      ),
    );

    if (!widget.mobile || !selectionMode) return content;
    return Column(
      children: [
        Expanded(child: content),
        AppSelectionBottomBar(
          leading: Text(
            '已选 $selectedCount 项',
            key: const Key('invalid-media-bottom-selection-count'),
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s14,
              weight: AppTextWeight.semibold,
              tone: AppTextTone.primary,
            ),
          ),
          actions: [
            AppButton(
              key: const Key('invalid-media-batch-delete-button'),
              label: '删除',
              variant: AppButtonVariant.danger,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: selectedCount == 0
                  ? null
                  : () => _batchDelete(selectedIds.toList(growable: false)),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _batchDelete(List<int> mediaIds) async {
    if (mediaIds.isEmpty) return;
    final confirmed = await showAppConfirmDialog(
      context,
      dialogKey: const Key('invalid-media-batch-delete-dialog'),
      confirmKey: const Key('invalid-media-batch-delete-confirm-button'),
      cancelKey: const Key('invalid-media-batch-delete-cancel-button'),
      title: '批量删除失效媒体',
      message: '将删除已选 ${mediaIds.length} 条失效媒体记录及对应文件，且不可恢复。确认要继续吗？',
      confirmLabel: '删除',
      danger: true,
    );
    if (!confirmed || !mounted) return;

    final notifier = ref.read(invalidMediaProvider.notifier);
    final result = await runBatchOperation<int>(
      context,
      title: '正在删除失效媒体',
      items: mediaIds,
      action: (id) => notifier.deleteInvalidMedia(mediaId: id),
    );
    if (!mounted) return;
    exitSelection();
    final succeeded = result.succeeded.length;
    final failed = result.failed.length;
    if (failed == 0) {
      showToast('已删除 $succeeded 项失效媒体');
    } else {
      showToast('已删除 $succeeded 项，$failed 项失败');
    }
  }
}

class _InvalidMediaHeader extends ConsumerWidget {
  const _InvalidMediaHeader({
    required this.mobile,
    required this.selectionMode,
    required this.selectedIds,
    required this.isAllSelected,
    required this.onExitSelection,
    required this.onToggleAll,
    required this.onBatchDelete,
  });

  final bool mobile;
  final bool selectionMode;
  final Set<int> selectedIds;
  final bool Function(List<int> ids) isAllSelected;
  final VoidCallback onExitSelection;
  final void Function(List<int> ids) onToggleAll;
  final Future<void> Function(List<int> mediaIds) onBatchDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      invalidMediaProvider.select(
        (asyncState) => (
          total: asyncState.value?.paged.total ?? 0,
          ids:
              asyncState.value?.paged.items
                  .map((item) => item.id)
                  .toList(growable: false) ??
              const <int>[],
          isInitialLoading: asyncState.isLoading && !asyncState.hasValue,
        ),
      ),
    );
    final loadedIds = state.ids;
    final selectedCount = selectedIds.length;
    final allSelected = isAllSelected(loadedIds);

    if (mobile && selectionMode) {
      return AppListHeader.selection(
        key: const Key('invalid-media-selection-header'),
        selectionLabel: '已选 $selectedCount 项',
        selectionExitButtonKey: const Key('invalid-media-exit-selection-button'),
        onExitSelection: onExitSelection,
        actionSlots: [
          AppTextButton(
            key: const Key('invalid-media-select-all-button'),
            label: allSelected ? '取消全选本页' : '全选本页',
            size: AppTextButtonSize.small,
            onPressed: loadedIds.isEmpty
                ? null
                : () => onToggleAll(loadedIds),
          ),
        ],
      );
    }

    // 桌面没有显式「选择模式」：选中任意一条即出现批量操作条。
    if (!mobile && selectedCount > 0) {
      return AppSelectionHeaderToolbar(
        countKey: const Key('invalid-media-selection-count'),
        selectAllKey: const Key('invalid-media-select-all-button'),
        exitKey: const Key('invalid-media-exit-selection-button'),
        countLabel: '已选 $selectedCount 条',
        selectAllLabel: allSelected ? '取消全选本页' : '全选本页',
        onToggleAll: loadedIds.isEmpty ? null : () => onToggleAll(loadedIds),
        onExit: onExitSelection,
        actions: [
          AppButton(
            key: const Key('invalid-media-batch-delete-button'),
            label: '批量删除（$selectedCount）',
            variant: AppButtonVariant.danger,
            size: AppButtonSize.small,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: selectedCount == 0
                ? null
                : () => onBatchDelete(selectedIds.toList(growable: false)),
          ),
        ],
      );
    }

    final description = Text(
      '巡检标记为失效的媒体会出现在这里。确认是真实丢失的文件，可删除记录，jav影片会再次自动下载新的资源。',
      key: const Key('invalid-media-section-description'),
      maxLines: mobile ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: resolveAppTextStyle(
        context,
        size: AppTextSize.s12,
        weight: AppTextWeight.regular,
        tone: AppTextTone.muted,
      ),
    );
    final totalText = '共 ${state.total} 条失效媒体';
    final refreshButton = AppIconButton(
      key: const Key('invalid-media-refresh-button'),
      tooltip: state.isInitialLoading ? '刷新中' : '刷新',
      icon: const Icon(Icons.refresh_rounded),
      onPressed: state.isInitialLoading
          ? null
          : () async {
              final message = await ref
                  .read(invalidMediaProvider.notifier)
                  .refresh();
              if (message != null) showToast(message);
            },
    );

    // 移动端文案一行放不下：说明独立成最多两行，计数与刷新单独一行，
    // 避免和计数、刷新按钮挤在一起被截断。
    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          description,
          SizedBox(height: context.appSpacing.sm),
          AppFilterTotalHeader(
            leading: const SizedBox.shrink(),
            totalText: totalText,
            totalKey: const Key('invalid-media-total-text'),
            trailing: refreshButton,
          ),
        ],
      );
    }
    return AppFilterTotalHeader(
      leading: description,
      totalText: totalText,
      totalKey: const Key('invalid-media-total-text'),
      trailing: refreshButton,
    );
  }
}

class _InvalidMediaBodySliver extends ConsumerWidget {
  const _InvalidMediaBodySliver({
    required this.mobile,
    required this.selectionMode,
    required this.selectedIds,
    required this.onToggleSelect,
    required this.onEnterSelection,
  });

  final bool mobile;
  final bool selectionMode;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggleSelect;
  final ValueChanged<int> onEnterSelection;

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
      // loading 用占位媒体渲染真实行，由 [AppSkeletonizer] 灰化。
      skeletonBuilder: (context) {
        final placeholders = invalidMediaPlaceholders();
        return AppSkeletonizer(
          enabled: true,
          child: Column(
            children: [
              for (var index = 0; index < placeholders.length; index++) ...[
                if (index > 0) SizedBox(height: context.appSpacing.md),
                _InvalidMediaRowConsumer(
                  item: placeholders[index],
                  mobile: mobile,
                  selectionMode: false,
                  selected: false,
                  onToggleSelect: () {},
                  onEnterSelection: () {},
                ),
              ],
            ],
          ),
        );
      },
      initialRetryKey: const Key('invalid-media-initial-retry-button'),
      onReload: () =>
          unawaited(ref.read(invalidMediaProvider.notifier).reload()),
      onLoadMore: () =>
          unawaited(ref.read(invalidMediaProvider.notifier).loadMore()),
      itemBuilder: (context, item, _) => _InvalidMediaRowConsumer(
        item: item,
        mobile: mobile,
        selectionMode: selectionMode,
        selected: selectedIds.contains(item.id),
        onToggleSelect: () => onToggleSelect(item.id),
        onEnterSelection: () => onEnterSelection(item.id),
      ),
    );
  }
}

class _InvalidMediaRowConsumer extends ConsumerWidget {
  const _InvalidMediaRowConsumer({
    required this.item,
    required this.mobile,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelect,
    required this.onEnterSelection,
  });

  final InvalidMediaDto item;
  final bool mobile;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onToggleSelect;
  final VoidCallback onEnterSelection;

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
      selected: selected,
      onTap: mobile
          ? (selectionMode ? onToggleSelect : null)
          : onToggleSelect,
      onLongPress: mobile && !selectionMode ? onEnterSelection : null,
      onDelete: selectionMode
          ? null
          : () => unawaited(_handleDelete(ref, context, item)),
      isDeleting: isDeleting,
      canDelete: actionState == null,
      showUpdatedAt: !mobile,
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
