import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/videos/data/dto/video_collection_dto.dart';
import 'package:sakuramedia/features/videos/presentation/providers/video_collections_overview_provider.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_empty_state.dart';
import 'package:sakuramedia/widgets/base/forms/app_picker_option_tile.dart';
import 'package:sakuramedia/widgets/base/forms/app_search_field.dart';
import 'package:sakuramedia/widgets/base/overlays/app_adaptive_modal.dart';

/// 单选合集的返回值：`collectionId == null` 表示「不加入合集」。
/// 整个弹层取消时返回 `null`（与「不加入合集」区分）。
class VideoCollectionSelection {
  const VideoCollectionSelection(this.collectionId);

  final int? collectionId;
}

/// 单选一个视频合集（导入表单用）：带搜索与「不加入合集」选项，取消返回 `null`。
Future<VideoCollectionSelection?> showPickVideoCollectionSingleDialog(
  BuildContext context, {
  required int? selectedCollectionId,
}) {
  return showAppAdaptiveModal<VideoCollectionSelection>(
    context: context,
    drawerKey: const Key('pick-video-collection-single-drawer'),
    desktopWidth: 420,
    mobileMaxHeightFactor: 0.7,
    builder:
        (_) => _PickVideoCollectionSingleDialog(
          selectedCollectionId: selectedCollectionId,
        ),
  );
}

class _PickVideoCollectionSingleDialog extends ConsumerStatefulWidget {
  const _PickVideoCollectionSingleDialog({required this.selectedCollectionId});

  final int? selectedCollectionId;

  @override
  ConsumerState<_PickVideoCollectionSingleDialog> createState() =>
      _PickVideoCollectionSingleDialogState();
}

class _PickVideoCollectionSingleDialogState
    extends ConsumerState<_PickVideoCollectionSingleDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';

  List<VideoCollectionDto> _visibleCollections(
    List<VideoCollectionDto> collections,
  ) {
    if (_keyword.isEmpty) {
      return collections;
    }
    return collections
        .where((collection) => collection.name.toLowerCase().contains(_keyword))
        .toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final collectionsAsync = ref.watch(videoCollectionsOverviewProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择合集',
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s16,
            weight: AppTextWeight.semibold,
            tone: AppTextTone.primary,
          ),
        ),
        SizedBox(height: spacing.md),
        AppSearchField(
          fieldKey: const Key('pick-video-collection-single-search-field'),
          controller: _searchController,
          hintText: '搜索合集',
          onChanged: (value) =>
              setState(() => _keyword = value.trim().toLowerCase()),
          clearKey: const Key('pick-video-collection-single-search-clear'),
        ),
        SizedBox(height: spacing.md),
        _buildBody(context, collectionsAsync),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<VideoCollectionDto>> collectionsAsync,
  ) {
    if (collectionsAsync.isLoading && !collectionsAsync.hasValue) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator.adaptive(),
        ),
      );
    }
    if (collectionsAsync.hasError && !collectionsAsync.hasValue) {
      return AppEmptyState(
        message: apiErrorMessage(collectionsAsync.error!, fallback: '合集加载失败'),
      );
    }
    final collections = collectionsAsync.value ?? <VideoCollectionDto>[];
    final visible = _visibleCollections(collections);
    final noneSelected = widget.selectedCollectionId == null;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: ListView.separated(
        key: const Key('pick-video-collection-single-list'),
        shrinkWrap: true,
        // 首行固定为「不加入合集」；搜索无结果时第二行给出提示而不是空列表。
        itemCount: visible.isEmpty ? 2 : visible.length + 1,
        separatorBuilder: (context, _) => SizedBox(height: context.appSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return AppPickerOptionTile.text(
              selected: noneSelected,
              onTap: () => Navigator.of(
                context,
              ).pop(const VideoCollectionSelection(null)),
              title: '不加入合集',
              optionKey: const Key('pick-video-collection-single-none'),
              checkboxKey: const Key(
                'pick-video-collection-single-none-checkbox',
              ),
            );
          }
          if (visible.isEmpty) {
            return Padding(
              padding: EdgeInsets.all(context.appSpacing.md),
              child: Text(
                collections.isEmpty ? '暂无合集' : '没有匹配的合集',
                style: resolveAppTextStyle(
                  context,
                  size: AppTextSize.s14,
                  tone: AppTextTone.muted,
                ),
              ),
            );
          }
          final collection = visible[index - 1];
          return AppPickerOptionTile.text(
            selected: widget.selectedCollectionId == collection.id,
            onTap: () => Navigator.of(
              context,
            ).pop(VideoCollectionSelection(collection.id)),
            title: collection.name,
            trailingText:
                collection.itemCount > 0 ? '${collection.itemCount}' : null,
            optionKey: Key('pick-video-collection-single-${collection.id}'),
            checkboxKey: Key(
              'pick-video-collection-single-checkbox-${collection.id}',
            ),
          );
        },
      ),
    );
  }
}
