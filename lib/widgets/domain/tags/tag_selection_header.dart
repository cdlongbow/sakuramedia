import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/listing/movie_filter_state.dart';
import 'package:sakuramedia/features/tags/presentation/providers/tag_selection_provider.dart';
import 'package:sakuramedia/features/tags/presentation/providers/tag_selection_scope.dart';
import 'package:sakuramedia/widgets/domain/tags/tag_selector_panel.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';
import 'package:sakuramedia/widgets/base/overlays/app_adaptive_modal.dart';

/// 固定区只显示入口和横向摘要；完整标签云在自适应弹窗内滚动查看。
///
/// 点入口：移动端弹全高底部抽屉，桌面弹居中对话框；弹窗里的
/// [TagSelectorPanel] 以 `scrollableTagCloud` 展示全部标签。
class TagSelectionHeader extends ConsumerWidget {
  const TagSelectionHeader({
    super.key,
    required this.scope,
    required this.mobile,
  });
  final TagSelectionScope scope;
  final bool mobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(tagSelectionProvider(scope));
    final notifier = ref.read(tagSelectionProvider(scope).notifier);
    final label = selection.hasSelection
        ? '标签 · ${selection.selectedCount}'
        : '选择标签';
    final Widget trigger = mobile
        ? AppTextButton(
            key: const Key('tags-selector-trigger'),
            label: label,
            onPressed: () => _openSelector(context),
          )
        : AppTextButton(
            key: const Key('tags-selector-trigger'),
            label: label,
            icon: const Icon(Icons.filter_alt_outlined),
            trailingIcon: const Icon(Icons.expand_more),
            size: AppTextButtonSize.small,
            isSelected: selection.hasSelection,
            onPressed: () => _openSelector(context),
          );
    return Padding(
      padding: EdgeInsets.only(bottom: context.appSpacing.sm),
      child: Row(
        children: [
          trigger,
          if (selection.hasSelection) ...[
            SizedBox(width: context.appSpacing.sm),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final tag in selection.selectedTags)
                      AppTextButton(
                        key: Key('tags-summary-${tag.tagId}'),
                        label: tag.name,
                        trailingIcon: const Icon(Icons.close),
                        size: AppTextButtonSize.xSmall,
                        onPressed: () => notifier.remove(tag.tagId),
                      ),
                    AppTextButton(
                      key: const Key('tags-summary-clear'),
                      label: '清空',
                      size: AppTextButtonSize.xSmall,
                      onPressed: notifier.clear,
                    ),
                  ],
                ),
              ),
            ),
            AppTextButton(
              key: const Key('tags-summary-match'),
              label: '匹配${selection.matchMode.label}',
              size: AppTextButtonSize.xSmall,
              onPressed: () => notifier.setMatchMode(
                selection.matchMode == TagMatchMode.or
                    ? TagMatchMode.and
                    : TagMatchMode.or,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openSelector(BuildContext context) {
    showAppAdaptiveModal<void>(
      context: context,
      variant: mobile
          ? AppAdaptiveModalVariant.drawer
          : AppAdaptiveModalVariant.dialog,
      drawerKey: const Key('tags-selector-drawer'),
      dialogKey: const Key('tags-selector-dialog'),
      desktopHeight: MediaQuery.sizeOf(context).height * 0.72,
      builder: (_) => _TagSelectionPanel(scope: scope),
    );
  }
}

class _TagSelectionPanel extends ConsumerWidget {
  const _TagSelectionPanel({required this.scope});
  final TagSelectionScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(tagSelectionProvider(scope));
    final notifier = ref.read(tagSelectionProvider(scope).notifier);
    return TagSelectorPanel(
      selection: selection,
      scrollableTagCloud: true,
      onToggleTag: notifier.toggle,
      onRemoveTag: notifier.remove,
      onClear: notifier.clear,
      onQueryChanged: notifier.setQuery,
      onToggleExpanded: notifier.toggleExpanded,
      onMatchModeChanged: notifier.setMatchMode,
      onRetry: () => unawaited(notifier.retry()),
    );
  }
}
