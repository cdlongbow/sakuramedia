import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/shared/data/sort_direction.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';
import 'package:sakuramedia/widgets/base/l10n/app_l10n.dart';
import 'package:sakuramedia/widgets/base/navigation/app_filter_entry_button.dart';
import 'package:sakuramedia/widgets/base/navigation/app_mobile_filter_drawer_scaffold.dart';
import 'package:sakuramedia/widgets/base/overlays/app_bottom_drawer.dart';
import 'package:sakuramedia/widgets/base/overlays/app_filter_popover.dart';

/// 列表的独立排序入口。
///
/// 排序是视图偏好，不属于筛选条件：桌面在顶栏右侧展开锚定浮层，移动端用底部
/// 抽屉。两端按钮长得一样（桌面带摘要，移动仅图标），排序内容都由内部
/// [_AppSortSection] 渲染，选中即应用并关闭。
///
/// 字段类型由调用方提供；方向使用跨 feature 共享的 [SortDirection]，本组件不
/// 依赖具体业务域的排序枚举。
class AppSortMenuButton<F> extends StatefulWidget {
  const AppSortMenuButton({
    super.key,
    required this.fields,
    required this.selectedField,
    required this.fieldLabelBuilder,
    required this.onFieldChanged,
    required this.selectedDirection,
    required this.onDirectionChanged,
    this.directionVisibleWhen,
    this.allowDefaultOption = false,
    this.defaultOptionLabel,
    this.triggerLabel,
    this.useDrawer = false,
    this.enabled = true,
    this.triggerKey,
    this.panelKey,
    this.drawerKey,
    this.fieldKeyBuilder,
    this.directionKeyBuilder,
    this.defaultOptionKey,
    this.tooltip,
  });

  final List<F> fields;
  final F? selectedField;
  final String Function(F field) fieldLabelBuilder;
  final ValueChanged<F?> onFieldChanged;

  final SortDirection selectedDirection;
  final ValueChanged<SortDirection> onDirectionChanged;

  /// 方向分节是否显示；参数是当前字段。为空时始终显示。
  final bool Function(F? field)? directionVisibleWhen;

  /// 是否在字段前渲染「默认」选项；选中时回调 `null`。
  final bool allowDefaultOption;
  final String? defaultOptionLabel;

  /// 完全覆盖自动生成的摘要（一般不需要）。
  final String? triggerLabel;

  /// 移动端传 `true`，点击弹底部抽屉。
  final bool useDrawer;

  /// 为 false 时入口不可点（例如女优搜索中按相关度排序）。
  final bool enabled;

  final Key? triggerKey;
  final Key? panelKey;
  final Key? drawerKey;

  final Key? Function(F field)? fieldKeyBuilder;
  final Key? Function(SortDirection direction)? directionKeyBuilder;
  final Key? defaultOptionKey;
  final String? tooltip;

  @override
  State<AppSortMenuButton<F>> createState() => _AppSortMenuButtonState<F>();
}

class _AppSortMenuButtonState<F> extends State<AppSortMenuButton<F>> {
  final AppPopoverController _popoverController = AppPopoverController();

  String _label(AppLocalizations l10n) {
    final override = widget.triggerLabel;
    if (override != null) {
      return override;
    }
    final field = widget.selectedField;
    if (field == null) {
      return widget.defaultOptionLabel ?? l10n.baseSortDefault;
    }
    final fieldLabel = widget.fieldLabelBuilder(field);
    final showArrow = widget.directionVisibleWhen?.call(field) ?? true;
    return showArrow
        ? '$fieldLabel ${widget.selectedDirection.symbol}'
        : fieldLabel;
  }

  Widget _buildSection({
    required ValueChanged<F?> onFieldChanged,
    required ValueChanged<SortDirection> onDirectionChanged,
  }) {
    return _AppSortSection<F>(
      fields: widget.fields,
      selectedField: widget.selectedField,
      fieldLabelBuilder: widget.fieldLabelBuilder,
      onFieldChanged: onFieldChanged,
      selectedDirection: widget.selectedDirection,
      onDirectionChanged: onDirectionChanged,
      directionVisibleWhen: widget.directionVisibleWhen,
      allowDefaultOption: widget.allowDefaultOption,
      defaultOptionLabel: widget.defaultOptionLabel,
      fieldKeyBuilder: widget.fieldKeyBuilder,
      directionKeyBuilder: widget.directionKeyBuilder,
      defaultOptionKey: widget.defaultOptionKey,
    );
  }

  void _applyField(F? value) {
    widget.onFieldChanged(value);
    _popoverController.close();
  }

  void _applyDirection(SortDirection value) {
    widget.onDirectionChanged(value);
    _popoverController.close();
  }

  Future<void> _showDrawer(BuildContext context) {
    return showAppBottomDrawer<void>(
      context: context,
      drawerKey: widget.drawerKey ?? const Key('app-sort-drawer'),
      maxHeightFactor: 0.75,
      builder: (sheetContext) => AppMobileFilterDrawerScaffold(
        child: _buildSection(
          onFieldChanged: (value) {
            widget.onFieldChanged(value);
            Navigator.of(sheetContext).pop();
          },
          onDirectionChanged: (value) {
            widget.onDirectionChanged(value);
            Navigator.of(sheetContext).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    if (widget.useDrawer) {
      return AppFilterEntryButton(
        key: widget.triggerKey,
        icon: Icons.swap_vert_rounded,
        tooltip: widget.tooltip ?? l10n.baseSortTooltip,
        onTap: widget.enabled ? () => _showDrawer(context) : null,
      );
    }
    return AppFilterPopover(
      triggerLabel: _label(l10n),
      panelKey: widget.panelKey ?? const Key('app-sort-panel'),
      controller: _popoverController,
      panelExtraWidth: 300,
      enabled: widget.enabled,
      triggerBuilder: (context, isOpen, toggle) => AppFilterEntryButton(
        key: widget.triggerKey,
        icon: Icons.swap_vert_rounded,
        label: _label(l10n),
        tooltip: widget.tooltip ?? l10n.baseSortTooltip,
        trailingIcon: isOpen
            ? Icons.expand_less_rounded
            : Icons.expand_more_rounded,
        onTap: widget.enabled ? toggle : null,
      ),
      panelBuilder: (context) => _buildSection(
        onFieldChanged: _applyField,
        onDirectionChanged: _applyDirection,
      ),
    );
  }
}

/// 排序面板的标准内容：标题 + 字段 chips +（可选）方向 chips。
///
/// 桌面浮层与移动抽屉共用同一份内容，只有外层容器不同。
class _AppSortSection<F> extends StatelessWidget {
  const _AppSortSection({
    required this.fields,
    required this.selectedField,
    required this.fieldLabelBuilder,
    required this.onFieldChanged,
    required this.selectedDirection,
    required this.onDirectionChanged,
    this.directionVisibleWhen,
    this.allowDefaultOption = false,
    this.defaultOptionLabel,
    this.fieldKeyBuilder,
    this.directionKeyBuilder,
    this.defaultOptionKey,
  });

  final List<F> fields;
  final F? selectedField;
  final String Function(F field) fieldLabelBuilder;
  final ValueChanged<F?> onFieldChanged;

  final SortDirection selectedDirection;
  final ValueChanged<SortDirection> onDirectionChanged;

  /// 更细的方向显示条件，参数是当前字段。为空时始终显示。
  final bool Function(F? field)? directionVisibleWhen;

  /// 是否在字段前渲染「默认」选项；选中时回调 `null`。
  final bool allowDefaultOption;
  final String? defaultOptionLabel;

  final Key? Function(F field)? fieldKeyBuilder;
  final Key? Function(SortDirection direction)? directionKeyBuilder;
  final Key? defaultOptionKey;

  bool get _showDirection => directionVisibleWhen?.call(selectedField) ?? true;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final spacing = context.appSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.baseSortTitle,
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s14,
            weight: AppTextWeight.regular,
            tone: AppTextTone.primary,
          ),
        ),
        SizedBox(height: spacing.sm),
        Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.sm,
          children: [
            if (allowDefaultOption)
              AppTextButton(
                key: defaultOptionKey,
                label: defaultOptionLabel ?? l10n.baseSortDefault,
                size: AppTextButtonSize.xSmall,
                isSelected: selectedField == null,
                onPressed: () => onFieldChanged(null),
              ),
            for (final field in fields)
              AppTextButton(
                key: fieldKeyBuilder?.call(field),
                label: fieldLabelBuilder(field),
                size: AppTextButtonSize.xSmall,
                isSelected: field == selectedField,
                onPressed: () => onFieldChanged(field),
              ),
          ],
        ),
        if (_showDirection) ...[
          SizedBox(height: spacing.md),
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.sm,
            children: [
              for (final direction in SortDirection.values)
                AppTextButton(
                  key: directionKeyBuilder?.call(direction),
                  label: direction.label,
                  size: AppTextButtonSize.xSmall,
                  isSelected: direction == selectedDirection,
                  onPressed: () => onDirectionChanged(direction),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
