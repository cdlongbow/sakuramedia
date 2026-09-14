import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/media/data/media_list_item_dto.dart';
import 'package:sakuramedia/features/media/presentation/providers/duplicate_media_provider.dart';
import 'package:sakuramedia/features/media/presentation/providers/invalid_media_provider.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_api_provider.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_browse_provider.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_libraries_provider.dart';
import 'package:sakuramedia/features/media/presentation/providers/multi_version_movies_provider.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/duplicate_media_section.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/invalid_media_section.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_list_section.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_transfer_target_dialog.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/multi_version_movies_section.dart';
import 'package:sakuramedia/features/shared/presentation/hooks/paged_scroll_hook.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_confirm_dialog.dart';
import 'package:sakuramedia/widgets/base/interaction/refresh/app_page_refresh_scope.dart';
import 'package:sakuramedia/widgets/base/navigation/app_tab_bar.dart';

/// 「媒体管理」双端共享内容（桌面 / 移动壳收敛的 content 层）。
///
/// 提供媒体列表、重复媒体、多版本影片和失效媒体管理。
class MediaManagementContent extends HookConsumerWidget {
  const MediaManagementContent({
    super.key,
    required this.keyPrefix,
    required this.rootKey,
    required this.onOpenMovieDetail,
    required this.onOpenVideoCollectionDetail,
    this.mobile = false,
  });

  final String keyPrefix;
  final Key rootKey;
  final void Function(BuildContext context, String movieNumber)
  onOpenMovieDetail;
  final void Function(BuildContext context, int collectionId)
  onOpenVideoCollectionDetail;
  final bool mobile;

  static const int _duplicateTabIndex = 1;
  static const int _versionsTabIndex = 2;
  static const int _maintenanceTabIndex = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabTickerProvider = useSingleTickerProvider();
    final tabController = useMemoized(
      () => TabController(length: 4, vsync: tabTickerProvider),
      [tabTickerProvider],
    );
    useEffect(() => tabController.dispose, [tabController]);
    useListenable(tabController);
    final currentTab = tabController.index;
    final duplicateKind = useState(MediaListItemKind.jav);
    final includeVr = useState(false);
    final includeFc2 = useState(false);
    final versionsProvider = multiVersionMoviesProvider(
      includeVr: includeVr.value,
      includeFc2: includeFc2.value,
    );
    final versionsVisited = useRef(false);
    if (currentTab == _versionsTabIndex) versionsVisited.value = true;
    // 首次访问后由管理页持有订阅，切换 Tab 时保留当前筛选的数据和分页。
    if (versionsVisited.value) ref.watch(versionsProvider);
    final scrollController = usePagedLoadMoreScroll(
      onReachBottom: () {
        if (currentTab == _maintenanceTabIndex) {
          unawaited(ref.read(invalidMediaProvider.notifier).loadMore());
        } else if (currentTab == _versionsTabIndex) {
          unawaited(ref.read(versionsProvider.notifier).loadMore());
        } else if (currentTab == _duplicateTabIndex) {
          unawaited(
            ref
                .read(duplicateMediaProvider(duplicateKind.value).notifier)
                .loadMore(),
          );
        } else {
          unawaited(ref.read(mediaBrowseProvider.notifier).loadMore());
        }
      },
      enabled: true,
      keys: [
        currentTab,
        duplicateKind.value,
        includeVr.value,
        includeFc2.value,
      ],
    );
    ref.listen(mediaBrowseProvider.select((value) => value.value?.filter), (
      previous,
      next,
    ) {
      if (previous != null &&
          next != null &&
          previous != next &&
          currentTab == 0 &&
          scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
    });

    useEffect(() {
      void onTabChanged() {
        if (tabController.indexIsChanging) return;
        if (scrollController.hasClients) {
          scrollController.jumpTo(0);
        }
      }

      tabController.addListener(onTabChanged);
      return () => tabController.removeListener(onTabChanged);
    }, [tabController, scrollController]);

    final isDeleting = useState<bool>(false);
    final isTransferring = useState<bool>(false);
    final deletingMediaId = useState<int?>(null);
    final selectionMode = useState<bool>(false);

    void exitSelectionMode() {
      selectionMode.value = false;
    }

    return AppPageRefreshScope(
      onRefresh: () => _refreshAll(
        ref,
        currentTab: currentTab,
        duplicateKind: duplicateKind.value,
        versionsProvider: versionsProvider,
      ),
      child: Column(
        key: rootKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTabBar(
            controller: tabController,
            tabs: [
              Tab(key: Key('$keyPrefix-tab-list'), text: '媒体列表'),
              Tab(key: Key('$keyPrefix-tab-duplicates'), text: '重复媒体'),
              Tab(key: Key('$keyPrefix-tab-versions'), text: '多版本影片'),
              Tab(key: Key('$keyPrefix-tab-maintenance'), text: '失效媒体'),
            ],
          ),
          SizedBox(height: context.appSpacing.lg),
          Expanded(
            child: switch (currentTab) {
              _versionsTabIndex => MultiVersionMoviesSection(
                includeVr: includeVr,
                includeFc2: includeFc2,
                scrollController: scrollController,
                keyPrefix: keyPrefix,
                mobile: mobile,
                onOpenMovieDetail: onOpenMovieDetail,
              ),
              _maintenanceTabIndex => InvalidMediaSection(
                key: Key('$keyPrefix-invalid-media-section'),
                scrollController: scrollController,
                mobile: mobile,
              ),
              _duplicateTabIndex => DuplicateMediaSection(
                key: Key('$keyPrefix-duplicate-media-section'),
                scrollController: scrollController,
                kind: duplicateKind.value,
                onKindChanged: (next) {
                  if (duplicateKind.value == next) return;
                  duplicateKind.value = next;
                  if (scrollController.hasClients) {
                    scrollController.jumpTo(0);
                  }
                },
                keyPrefix: keyPrefix,
                mobile: mobile,
                onRefresh: () => _refreshAll(
                  ref,
                  currentTab: currentTab,
                  duplicateKind: duplicateKind.value,
                  versionsProvider: versionsProvider,
                ),
                onOpenMovieDetail: onOpenMovieDetail,
                onOpenVideoCollectionDetail: onOpenVideoCollectionDetail,
              ),
              _ => MediaListSection(
                scrollController: scrollController,
                isDeleting: isDeleting.value,
                isTransferring: isTransferring.value,
                onBatchDelete: () => _openBatchDeleteDialog(
                  context,
                  ref,
                  isDeleting,
                  selectionMode,
                ),
                onBatchTransfer: () => _openBatchTransferDialog(
                  context,
                  ref,
                  isTransferring,
                  selectionMode,
                ),
                onRefresh: () => _refreshAll(
                  ref,
                  currentTab: currentTab,
                  duplicateKind: duplicateKind.value,
                  versionsProvider: versionsProvider,
                ),
                onOpenMovieDetail: onOpenMovieDetail,
                keyPrefix: keyPrefix,
                mobile: mobile,
                selectionMode: selectionMode.value,
                onEnterSelection: () => selectionMode.value = true,
                onExitSelection: exitSelectionMode,
                onDeleteItem: (item) => _openSingleDeleteDialog(
                  context,
                  ref,
                  item,
                  deletingMediaId,
                ),
                deletingItemId: deletingMediaId,
              ),
            },
          ),
        ],
      ),
    );
  }

  Future<void> _refreshAll(
    WidgetRef ref, {
    required int currentTab,
    required MediaListItemKind duplicateKind,
    required MultiVersionMoviesProvider versionsProvider,
  }) async {
    final refreshes = <Future<String?>>[
      ref.read(mediaBrowseProvider.notifier).refresh(),
      ref.read(invalidMediaProvider.notifier).refresh(),
      ref.read(mediaLibrariesProvider.notifier).refresh(),
    ];
    if (currentTab == _duplicateTabIndex) {
      refreshes.add(
        ref.read(duplicateMediaProvider(duplicateKind).notifier).refresh(),
      );
    }
    if (currentTab == _versionsTabIndex) {
      refreshes.add(ref.read(versionsProvider.notifier).refresh());
    }
    final results = await Future.wait<String?>(refreshes);
    for (final message in results) {
      if (message != null) showToast(message);
    }
  }

  Future<void> _openBatchDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isDeleting,
    ValueNotifier<bool> selectionMode,
  ) async {
    if (isDeleting.value) return;
    final browseState = ref.read(mediaBrowseProvider).value;
    if (browseState == null) return;
    final selectedIds = browseState.selectedIds.toList(growable: false);
    if (selectedIds.isEmpty) return;

    final confirmed = await showAppConfirmDialog(
      context,
      dialogKey: const Key('media-management-batch-delete-dialog'),
      confirmKey: const Key('media-management-batch-delete-confirm-button'),
      cancelKey: const Key('media-management-batch-delete-cancel-button'),
      title: '批量删除媒体',
      message: '将删除已选 ${selectedIds.length} 项媒体及其对应文件，且不可恢复。请确认要继续吗？',
      confirmLabel: '删除',
      danger: true,
    );
    if (!confirmed || !context.mounted) return;

    isDeleting.value = true;
    final okIds = <int>[];
    final failedIds = <int>[];
    Object? firstError;
    try {
      final mediaApi = ref.read(mediaApiProvider);
      for (final mediaId in selectedIds) {
        try {
          await mediaApi.deleteMedia(mediaId: mediaId);
          okIds.add(mediaId);
        } catch (error) {
          failedIds.add(mediaId);
          firstError ??= error;
        }
      }
    } finally {
      if (context.mounted) {
        isDeleting.value = false;
      }
    }

    if (okIds.isNotEmpty) {
      ref.read(mediaBrowseProvider.notifier).removeItemsByIds(okIds);
      if (mobile && context.mounted) {
        selectionMode.value = false;
      }
    }
    if (!context.mounted) return;
    if (failedIds.isEmpty) {
      showToast('已删除 ${okIds.length} 项媒体');
    } else {
      final errorMessage = firstError == null
          ? '未知错误'
          : apiErrorMessage(firstError, fallback: '批量删除失败');
      showToast('已删除 ${okIds.length} 项，${failedIds.length} 项失败：$errorMessage');
      unawaited(ref.read(mediaBrowseProvider.notifier).refresh());
    }
  }

  Future<void> _openSingleDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    MediaListItemDto item,
    ValueNotifier<int?> deletingMediaId,
  ) async {
    if (deletingMediaId.value != null) return;
    final confirmed = await showAppConfirmDialog(
      context,
      dialogKey: Key('media-management-delete-dialog-${item.id}'),
      confirmKey: Key('media-management-delete-confirm-${item.id}'),
      cancelKey: Key('media-management-delete-cancel-${item.id}'),
      title: '删除媒体',
      message: '确认删除“${item.fileName}”及对应文件？该操作不可恢复。',
      confirmLabel: '删除',
      danger: true,
    );
    if (!confirmed || !context.mounted) return;

    deletingMediaId.value = item.id;
    try {
      await ref.read(mediaApiProvider).deleteMedia(mediaId: item.id);
      ref.read(mediaBrowseProvider.notifier).removeItemsByIds([item.id]);
      if (context.mounted) showToast('媒体已删除');
    } catch (error) {
      if (context.mounted) {
        showToast(apiErrorMessage(error, fallback: '删除媒体失败'));
      }
    } finally {
      if (context.mounted && deletingMediaId.value == item.id) {
        deletingMediaId.value = null;
      }
    }
  }

  Future<void> _openBatchTransferDialog(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isTransferring,
    ValueNotifier<bool> selectionMode,
  ) async {
    if (isTransferring.value) return;
    final browseState = ref.read(mediaBrowseProvider).value;
    if (browseState == null || browseState.selectedIds.isEmpty) return;
    final selectedIds = browseState.selectedIds.toList(growable: false);

    isTransferring.value = true;
    try {
      final mediaApi = ref.read(mediaApiProvider);
      final candidates = await mediaApi.getMediaTransferCandidates(
        mediaIds: selectedIds,
      );
      if (!context.mounted) return;
      isTransferring.value = false;
      if (candidates.targets.isEmpty) {
        showToast('当前媒体库没有可用的迁移目标');
        return;
      }
      final targetLibraryId = await showMediaTransferTargetDialog(
        context,
        selectedCount: selectedIds.length,
        candidates: candidates,
      );
      if (targetLibraryId == null || !context.mounted) return;
      isTransferring.value = true;
      final accepted = await mediaApi.createMediaTransfer(
        mediaIds: selectedIds,
        targetLibraryId: targetLibraryId,
      );
      ref.read(mediaBrowseProvider.notifier).clearSelection();
      if (mobile) selectionMode.value = false;
      showToast('迁移任务 #${accepted.taskRunId} 已提交，请在活动中心查看进度');
    } catch (error) {
      if (context.mounted) {
        showToast(apiErrorMessage(error, fallback: '提交迁移任务失败，请稍后重试。'));
      }
    } finally {
      if (context.mounted) isTransferring.value = false;
    }
  }
}
