import 'dart:ui' show SemanticsRole;

import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/media/images/app_image_fullscreen.dart';
import 'package:sakuramedia/widgets/base/overlays/app_bottom_drawer.dart';

/// 弹出菜单的一项。
///
/// [icon] 为 `null` 时只渲染文字（卡片右键菜单）；[subtitle] 用于补充说明；
/// [tone] 沿用应用文字色调，危险操作传 [AppTextTone.error]；[key] 用于沿用
/// 既有测试锚点。菜单项之间靠固定间距分项，没有分隔线。
class AppMenuItem<T> {
  const AppMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.subtitle,
    this.tone = AppTextTone.primary,
    this.enabled = true,
    this.visible = true,
    this.key,
  });

  final T value;
  final String label;
  final IconData? icon;
  final String? subtitle;
  final AppTextTone tone;
  final bool enabled;
  final bool visible;
  final Key? key;
}

/// 决定 [showAppActionMenu] 用哪种壳显示。
///
/// 形态由**触发方式**决定，不按平台：长按 / 右键这类上下文入口用 [popup]
/// （锚定在按压点，即移动端的「右键菜单」）；「更多」按钮触发的动作列表用
/// [bottomDrawer]（可选标题 + 独立「取消」行）。国内主流 App 的惯例如此。
enum AppMenuPresentation { popup, bottomDrawer }

/// 全应用唯一的右键 / 长按菜单壳。
///
/// 负责：过滤 [AppMenuItem.visible]、定位、统一表面样式与项渲染、底部操作表
/// （可选标题 + 独立「取消」行）、全屏图片下的抽屉宿主。
/// 调用方保留自己的 action 枚举、items 组装与派发 `switch`。
Future<T?> showAppActionMenu<T>({
  required BuildContext context,
  required List<AppMenuItem<T>> items,
  Offset? globalPosition,
  AppMenuPresentation presentation = AppMenuPresentation.popup,
  bool useRootNavigator = false,
  Key? drawerKey,
  String? title,
  bool showCancelRow = true,
}) {
  final visibleItems = items.where((item) => item.visible).toList();
  if (visibleItems.isEmpty) {
    return Future<T?>.value(null);
  }

  if (presentation == AppMenuPresentation.bottomDrawer) {
    return _showDrawerMenu(
      context: context,
      items: visibleItems,
      drawerKey: drawerKey,
      title: title,
      showCancelRow: showCancelRow,
    );
  }
  return _showPopupMenu(
    context: context,
    items: visibleItems,
    globalPosition: globalPosition,
    useRootNavigator: useRootNavigator,
  );
}

const double _popupItemHeight = 36;
const double _popupItemWithSubtitleHeight = 52;
const double _popupItemGap = 4;
const double _drawerItemMinHeight = 52;
const double _drawerItemWithSubtitleHeight = 68;
const double _menuMinWidth = 112;
const double _menuMaxWidth = 320;
const double _cancelGapHeight = 8;
const double _drawerTopSpacing = 20;
const double _drawerTitleHeight = 48;

Future<T?> _showPopupMenu<T>({
  required BuildContext context,
  required List<AppMenuItem<T>> items,
  required Offset? globalPosition,
  required bool useRootNavigator,
}) {
  if (globalPosition == null) {
    return Future<T?>.value(null);
  }

  final colors = context.appColors;
  final spacing = context.appSpacing;
  final componentTokens = Theme.of(context).appComponentTokens;
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final overlay = navigator.overlay!.context.findRenderObject() as RenderBox;
  final localPosition = overlay.globalToLocal(globalPosition);
  final position = RelativeRect.fromRect(
    Rect.fromPoints(localPosition, localPosition),
    Offset.zero & overlay.size,
  );

  final entries = <PopupMenuEntry<T>>[
    for (final item in items)
      _AppPopupMenuEntry<T>(
        key: item.key,
        item: item,
        rowHeight: item.subtitle == null
            ? _popupItemHeight
            : _popupItemWithSubtitleHeight,
        gap: _popupItemGap,
        iconSize: componentTokens.iconSizeXs,
        itemPadding: spacing.md,
      ),
  ];

  return showMenu<T>(
    context: context,
    position: position,
    useRootNavigator: useRootNavigator,
    color: colors.surfaceCard,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: context.appRadius.mdBorder,
      side: BorderSide(color: colors.divider),
    ),
    menuPadding: EdgeInsets.symmetric(
      horizontal: spacing.xs,
      vertical: spacing.xs,
    ),
    constraints: const BoxConstraints(
      minWidth: _menuMinWidth,
      maxWidth: _menuMaxWidth,
    ),
    items: entries,
  );
}

/// 弹层菜单项。
///
/// 不用 `PopupMenuItem`：它的内层 `InkWell` 写死无圆角，hover 高亮会是贴着
/// 菜单边缘的直角矩形，与外层圆角对不上。这里自建 entry，把高亮收进一个
/// 同心圆角矩形（`sm` = 外层 `md` 12 − [menuPadding] 4）。
class _AppPopupMenuEntry<T> extends PopupMenuEntry<T> {
  const _AppPopupMenuEntry({
    super.key,
    required this.item,
    required this.rowHeight,
    required this.gap,
    required this.iconSize,
    required this.itemPadding,
  });

  final AppMenuItem<T> item;
  final double rowHeight;
  final double gap;
  final double iconSize;
  final double itemPadding;

  /// 高亮行高 + 上下各半格间距；[showMenu] 只在 initialValue 对齐时读它。
  @override
  double get height => rowHeight + gap;

  bool get enabled => item.enabled;

  @override
  bool represents(T? value) => item.value == value;

  @override
  State<_AppPopupMenuEntry<T>> createState() => _AppPopupMenuEntryState<T>();
}

class _AppPopupMenuEntryState<T> extends State<_AppPopupMenuEntry<T>> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return MergeSemantics(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: widget.gap / 2),
        child: Semantics(
          role: SemanticsRole.menuItem,
          enabled: item.enabled,
          button: true,
          child: InkWell(
            onTap: item.enabled
                ? () => Navigator.pop<T>(context, item.value)
                : null,
            canRequestFocus: item.enabled,
            mouseCursor: item.enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            borderRadius: context.appRadius.smBorder,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: widget.rowHeight),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.itemPadding),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _AppMenuRow<T>(
                    item: item,
                    iconSize: widget.iconSize,
                    labelSize: AppTextSize.s12,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> _showDrawerMenu<T>({
  required BuildContext context,
  required List<AppMenuItem<T>> items,
  required Key? drawerKey,
  required String? title,
  required bool showCancelRow,
}) {
  final screenHeight = MediaQuery.sizeOf(context).height;
  final itemsHeight = items.fold<double>(0, (total, item) {
    return total +
        (item.subtitle == null
            ? _drawerItemMinHeight
            : _drawerItemWithSubtitleHeight);
  });
  final estimatedHeight =
      _drawerTopSpacing +
      (title == null ? 0 : _drawerTitleHeight) +
      itemsHeight +
      (showCancelRow ? _cancelGapHeight + _drawerItemMinHeight : 0);
  final heightFactor = (estimatedHeight / screenHeight).clamp(0.24, 0.92);

  final inlineFullscreenDrawer = AppImageFullscreenHost.showBottomDrawer<T>(
    context: context,
    drawerKey: drawerKey,
    heightFactor: heightFactor,
    ignoreTopSafeArea: true,
    contentPadding: EdgeInsets.zero,
    builder: (drawerContext, close) => _AppActionMenuDrawer<T>(
      items: items,
      title: title,
      showCancelRow: showCancelRow,
      onSelected: close,
    ),
  );
  if (inlineFullscreenDrawer != null) {
    return inlineFullscreenDrawer;
  }

  return showAppBottomDrawer<T>(
    context: context,
    drawerKey: drawerKey,
    maxHeightFactor: heightFactor,
    ignoreTopSafeArea: true,
    contentPadding: EdgeInsets.zero,
    builder: (drawerContext) => _AppActionMenuDrawer<T>(
      items: items,
      title: title,
      showCancelRow: showCancelRow,
      onSelected: (value) => Navigator.of(drawerContext).pop(value),
    ),
  );
}

class _AppActionMenuDrawer<T> extends StatelessWidget {
  const _AppActionMenuDrawer({
    required this.items,
    required this.title,
    required this.showCancelRow,
    required this.onSelected,
  });

  final List<AppMenuItem<T>> items;
  final String? title;
  final bool showCancelRow;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final componentTokens = Theme.of(context).appComponentTokens;
    final title = this.title;

    // 高度估算偏低或系统放大字体时，靠滚动兜底而不是溢出。
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              spacing.lg,
              spacing.lg,
              spacing.lg,
              title == null ? spacing.xs : spacing.sm,
            ),
            child: title == null
                ? const SizedBox.shrink()
                : Text(
                    title,
                    style: resolveAppTextStyle(
                      context,
                      size: AppTextSize.s16,
                      weight: AppTextWeight.semibold,
                      tone: AppTextTone.primary,
                    ),
                  ),
          ),
          for (final item in items)
            _AppDrawerRow<T>(
              item: item,
              iconSize: componentTokens.iconSizeSm,
              onSelected: onSelected,
            ),
          if (showCancelRow) ...[
            SizedBox(
              height: _cancelGapHeight,
              child: ColoredBox(color: context.appColors.surfacePage),
            ),
            _AppDrawerCancelRow(onTap: () => onSelected(null)),
          ],
        ],
      ),
    );
  }
}

class _AppDrawerRow<T> extends StatelessWidget {
  const _AppDrawerRow({
    required this.item,
    required this.iconSize,
    required this.onSelected,
  });

  final AppMenuItem<T> item;
  final double iconSize;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;

    return InkWell(
      key: item.key,
      onTap: item.enabled ? () => onSelected(item.value) : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _drawerItemMinHeight),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.lg,
            vertical: spacing.md,
          ),
          child: _AppMenuRow<T>(
            item: item,
            iconSize: iconSize,
            labelSize: AppTextSize.s12,
          ),
        ),
      ),
    );
  }
}

class _AppDrawerCancelRow extends StatelessWidget {
  const _AppDrawerCancelRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _drawerItemMinHeight),
        child: Center(
          child: Text(
            '取消',
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s12,
              tone: AppTextTone.secondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AppMenuRow<T> extends StatelessWidget {
  const _AppMenuRow({
    required this.item,
    required this.iconSize,
    required this.labelSize,
  });

  final AppMenuItem<T> item;
  final double iconSize;
  final AppTextSize labelSize;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final resolvedTone = item.enabled ? item.tone : AppTextTone.muted;
    final icon = item.icon;
    final isDanger = item.enabled && item.tone == AppTextTone.error;
    final iconColor = icon == null
        ? null
        : resolveAppTextToneColor(
            context,
            isDanger
                ? AppTextTone.error
                : (item.enabled ? AppTextTone.secondary : AppTextTone.muted),
          );

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize, color: iconColor),
          SizedBox(width: spacing.sm),
        ],
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: resolveAppTextStyle(
                  context,
                  size: labelSize,
                  tone: resolvedTone,
                ),
              ),
              if (item.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  item.subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s12,
                    tone: AppTextTone.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
