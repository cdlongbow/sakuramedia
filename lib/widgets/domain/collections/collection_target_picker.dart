import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/feedback/app_empty_state.dart';
import 'package:sakuramedia/widgets/base/forms/app_search_field.dart';
import 'package:sakuramedia/widgets/base/interaction/app_interactive_surface.dart';
import 'package:sakuramedia/widgets/base/overlays/app_adaptive_modal.dart';

/// 从一个合集列表里选一个目标合集。返回选中的合集；取消返回 `null`。
///
/// 只负责「选中并返回」，实际成员写入由调用方执行（批量加入合集场景）。
/// 切片、时刻、视频三处的「加入合集」选择器共用此组件，各域只提供数据源、
/// 行文案和「新建合集」入口；数据源经 [watchCollections] 监听各自 overview
/// provider，与列表页共享缓存。
Future<T?> showCollectionTargetPicker<T extends Object>({
  required BuildContext context,
  required AsyncValue<List<T>> Function(WidgetRef ref) watchCollections,
  required int Function(T value) idOf,
  required String Function(T value) nameOf,
  required String Function(T value) countTextOf,
  required String optionKeyPrefix,
  required Future<T?> Function(BuildContext context, bool isDrawer) onCreate,
  int? excludedCollectionId,
  AppAdaptiveModalVariant variant = AppAdaptiveModalVariant.auto,
  Key? drawerKey,
  String title = '加入合集',
  String createButtonLabel = '新建合集并加入',
}) {
  return showAppAdaptiveModal<T>(
    context: context,
    variant: variant,
    drawerKey: drawerKey,
    desktopWidth: 420,
    mobileMaxHeightFactor: 0.7,
    builder: (_) => _CollectionTargetPicker<T>(
      watchCollections: watchCollections,
      idOf: idOf,
      nameOf: nameOf,
      countTextOf: countTextOf,
      optionKeyPrefix: optionKeyPrefix,
      onCreate: onCreate,
      excludedCollectionId: excludedCollectionId,
      title: title,
      createButtonLabel: createButtonLabel,
    ),
  );
}

class _CollectionTargetPicker<T extends Object> extends ConsumerStatefulWidget {
  const _CollectionTargetPicker({
    required this.watchCollections,
    required this.idOf,
    required this.nameOf,
    required this.countTextOf,
    required this.optionKeyPrefix,
    required this.onCreate,
    required this.excludedCollectionId,
    required this.title,
    required this.createButtonLabel,
  });

  final AsyncValue<List<T>> Function(WidgetRef ref) watchCollections;
  final int Function(T value) idOf;
  final String Function(T value) nameOf;
  final String Function(T value) countTextOf;

  /// 行测试锚点前缀，最终 Key 为 `<前缀><合集 id>`。
  final String optionKeyPrefix;

  /// 「新建合集并加入」入口，返回新建的合集；[isDrawer] 为当前弹层壳形态。
  final Future<T?> Function(BuildContext context, bool isDrawer) onCreate;

  /// 不在列表中显示的合集 id（从合集详情页发起「加入其它合集」时排除自身）。
  final int? excludedCollectionId;

  final String title;
  final String createButtonLabel;

  @override
  ConsumerState<_CollectionTargetPicker<T>> createState() =>
      _CollectionTargetPickerState<T>();
}

class _CollectionTargetPickerState<T extends Object>
    extends ConsumerState<_CollectionTargetPicker<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';

  bool get _isBottomDrawer => AppAdaptiveModalShellScope.maybeIsDrawer(context);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createAndPick() async {
    final created = await widget.onCreate(context, _isBottomDrawer);
    if (created != null && mounted) {
      Navigator.of(context).pop(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final collectionsAsync = widget.watchCollections(ref);
    // 抽屉形态：列表占据抽屉剩余空间并内部滚动，表头/按钮常驻，整体由抽屉 maxHeightFactor
    // 约束，避免矮屏上「表头 + 固定高列表 + 按钮」超过抽屉封顶导致溢出。桌面弹窗仍用固定上限。
    final listSection = _isBottomDrawer
        ? Flexible(child: _buildBody(context, collectionsAsync))
        : ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: _buildBody(context, collectionsAsync),
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s16,
            weight: AppTextWeight.semibold,
            tone: AppTextTone.primary,
          ),
        ),
        SizedBox(height: spacing.md),
        AppSearchField(
          fieldKey: const Key('collection-target-picker-search-field'),
          controller: _searchController,
          hintText: '搜索合集',
          onChanged: (value) =>
              setState(() => _keyword = value.trim().toLowerCase()),
          clearKey: const Key('collection-target-picker-search-clear'),
        ),
        SizedBox(height: spacing.md),
        listSection,
        SizedBox(height: spacing.md),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: widget.createButtonLabel,
                onPressed: _createAndPick,
              ),
            ),
            SizedBox(width: spacing.md),
            AppButton(
              label: '关闭',
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<T>> collectionsAsync,
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
    final allCollections = collectionsAsync.value ?? <T>[];
    final excluded = widget.excludedCollectionId;
    var collections = excluded == null
        ? allCollections
        : allCollections
              .where((collection) => widget.idOf(collection) != excluded)
              .toList(growable: false);
    if (_keyword.isNotEmpty) {
      collections = collections
          .where(
            (collection) =>
                widget.nameOf(collection).toLowerCase().contains(_keyword),
          )
          .toList(growable: false);
    }
    if (collections.isEmpty) {
      return AppEmptyState(
        message: allCollections.isEmpty ? '暂无合集，点击下方新建' : '没有匹配的合集',
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: collections.length,
      separatorBuilder: (context, _) => SizedBox(height: context.appSpacing.sm),
      itemBuilder: (context, index) {
        final collection = collections[index];
        return _CollectionTargetOptionTile(
          key: Key('${widget.optionKeyPrefix}${widget.idOf(collection)}'),
          name: widget.nameOf(collection),
          countText: widget.countTextOf(collection),
          onTap: () => Navigator.of(context).pop(collection),
        );
      },
    );
  }
}

/// 「加入合集」选项行：浅灰卡片上的单行条目，名称过长时省略，右侧为计数和加号。
class _CollectionTargetOptionTile extends StatelessWidget {
  const _CollectionTargetOptionTile({
    super.key,
    required this.name,
    required this.countText,
    required this.onTap,
  });

  static const double _minHeight = 44;

  final String name;
  final String countText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    return AppInteractiveSurface(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: _minHeight),
        padding: EdgeInsets.symmetric(horizontal: spacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: context.appRadius.xsBorder,
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: resolveAppTextStyle(
                  context,
                  size: AppTextSize.s14,
                  weight: AppTextWeight.medium,
                  tone: AppTextTone.primary,
                ),
              ),
            ),
            SizedBox(width: spacing.md),
            Text(
              countText,
              maxLines: 1,
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s12,
                tone: AppTextTone.muted,
              ),
            ),
            SizedBox(width: spacing.sm),
            Icon(
              Icons.add,
              size: context.appComponentTokens.iconSizeSm,
              color: context.appTextPalette.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
