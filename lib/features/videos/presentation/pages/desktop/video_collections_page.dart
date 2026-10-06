import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/videos/data/dto/video_collection_dto.dart';
import 'package:sakuramedia/features/videos/presentation/providers/video_collections_overview_provider.dart';
import 'package:sakuramedia/features/videos/presentation/providers/videos_api_provider.dart';
import 'package:sakuramedia/features/videos/presentation/video_placeholders.dart';
import 'package:sakuramedia/features/videos/presentation/widgets/collections/create_video_collection_dialog.dart';
import 'package:sakuramedia/routes/app_route_paths.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/feedback/app_confirm_dialog.dart';
import 'package:sakuramedia/widgets/base/feedback/app_empty_state.dart';
import 'package:sakuramedia/widgets/base/feedback/app_skeletonizer.dart';
import 'package:sakuramedia/widgets/base/forms/app_search_field.dart';
import 'package:sakuramedia/widgets/base/interaction/refresh/app_page_refresh_scope.dart';
import 'package:sakuramedia/widgets/base/layout/grids/app_adaptive_card_wrap.dart';
import 'package:sakuramedia/widgets/base/layout/grids/grid_column_resolver.dart';
import 'package:sakuramedia/widgets/domain/collections/collection_card.dart';

class DesktopVideoCollectionsPage extends ConsumerStatefulWidget {
  const DesktopVideoCollectionsPage({super.key});

  @override
  ConsumerState<DesktopVideoCollectionsPage> createState() =>
      _DesktopVideoCollectionsPageState();
}

class _DesktopVideoCollectionsPageState
    extends ConsumerState<DesktopVideoCollectionsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final created = await showVideoCollectionDialog(context);
    if (created != null) {
      unawaited(ref.read(videoCollectionsOverviewProvider.notifier).refresh());
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    VideoCollectionDto collection,
  ) async {
    final updated = await showVideoCollectionDialog(
      context,
      existing: collection,
    );
    if (updated != null) {
      unawaited(ref.read(videoCollectionsOverviewProvider.notifier).refresh());
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    VideoCollectionDto collection,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: '删除合集',
      message: '确定删除合集「${collection.name}」吗？合集内的视频不会被删除。',
      danger: true,
      confirmLabel: '删除',
    );
    if (!confirmed) {
      return;
    }
    try {
      await ref
          .read(videoCollectionsApiProvider)
          .deleteCollection(collection.id);
      await ref.read(videoCollectionsOverviewProvider.notifier).refresh();
      if (context.mounted) {
        showToast('已删除');
      }
    } catch (_) {
      if (context.mounted) {
        showToast('删除失败，请稍后重试');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(videoCollectionsOverviewProvider);
    final notifier = ref.read(videoCollectionsOverviewProvider.notifier);

    return AppPageRefreshScope(
      onRefresh: notifier.refresh,
      child: ColoredBox(
        color: context.appColors.surfaceElevated,
        // 页面边距由桌面 shell 的 AppPageInsets.desktopStandard (24px) 统一提供，
        // 此处不再叠加 EdgeInsets.all(spacing.lg)，否则合计 40px 比合集详情等
        // 同类页明显宽（详情页此前已修，这里是漏掉的一处）。
        child: CustomScrollView(
          key: const Key('video-collections-page'),
          slivers: [
            SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: AppSearchField(
                      fieldKey: const Key('video-collections-search-field'),
                      controller: _searchController,
                      hintText: '搜索合集',
                      onChanged: (value) => setState(
                        () => _keyword = value.trim().toLowerCase(),
                      ),
                      clearKey: const Key('video-collections-search-clear'),
                    ),
                  ),
                  SizedBox(width: context.appSpacing.md),
                  AppButton(
                    key: const Key('video-collections-create-button'),
                    label: '新建合集',
                    variant: AppButtonVariant.primary,
                    onPressed: () => _create(context, ref),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: context.appSpacing.lg)),
            _buildBody(context, ref, async),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<VideoCollectionDto>> async,
  ) {
    final isLoading = async.isLoading && async.value == null;
    if (!isLoading && async.hasError && async.value == null) {
      return SliverToBoxAdapter(
        child: AppEmptyState(
          message: apiErrorMessage(async.error!, fallback: '合集加载失败，请稍后重试'),
        ),
      );
    }
    final allCollections = isLoading
        ? videoCollectionPlaceholders(count: 4)
        : async.value ?? const <VideoCollectionDto>[];
    if (allCollections.isEmpty) {
      return const SliverToBoxAdapter(
        child: AppEmptyState(message: '暂无合集，点击「新建合集」创建'),
      );
    }
    final collections = isLoading || _keyword.isEmpty
        ? allCollections
        : allCollections
              .where(
                (collection) =>
                    collection.name.toLowerCase().contains(_keyword),
              )
              .toList(growable: false);
    if (collections.isEmpty) {
      return const SliverToBoxAdapter(
        child: AppEmptyState(message: '没有匹配的合集'),
      );
    }
    return AppSkeletonizer.sliver(
      enabled: isLoading,
      // 懒加载：合集上千时不首帧构建全部卡片与封面图请求。
      child: AppAdaptiveCardWrapSliver<VideoCollectionDto>(
        gridKey: const Key('video-collections-grid'),
        items: collections,
        orientation: AppCardGridOrientation.landscape,
        itemBuilder:
            (context, collection, _) => CollectionCard.video(
              collection: collection,
              onTap: () =>
                  context.go('$desktopVideoCollectionsPath/${collection.id}'),
              onEdit: () => _edit(context, ref, collection),
              onDelete: () => _delete(context, ref, collection),
            ),
      ),
    );
  }
}
