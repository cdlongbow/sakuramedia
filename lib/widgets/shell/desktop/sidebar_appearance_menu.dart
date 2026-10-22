import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/app/providers/app_shell_providers.dart';
import 'package:sakuramedia/app/providers/appearance_providers.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';

/// 桌面侧栏底部的明暗模式切换 + 主题色小浮窗。
///
/// 明暗模式是单个图标的三态循环（跟随系统 → 浅色 → 深色）；主题色点调色盘
/// 向上弹出小色板，选完自动收起。复用设置页同一份 [appearanceProvider]。
class SidebarAppearanceMenu extends ConsumerStatefulWidget {
  const SidebarAppearanceMenu({super.key});

  @override
  ConsumerState<SidebarAppearanceMenu> createState() =>
      _SidebarAppearanceMenuState();
}

class _SidebarAppearanceMenuState extends ConsumerState<SidebarAppearanceMenu> {
  static const double _panelGap = 8;
  static const double _themeColorDotSize = 6;
  static const Duration _panelAnimationDuration = Duration(milliseconds: 140);

  final LayerLink _layerLink = LayerLink();
  final FocusNode _panelFocusNode = FocusNode(
    debugLabel: 'sidebar-theme-color-panel',
  );
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removePanel();
    _panelFocusNode.dispose();
    super.dispose();
  }

  void _togglePanel() {
    if (_overlayEntry != null) {
      _removePanel();
      return;
    }
    _overlayEntry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_overlayEntry!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _overlayEntry != null) {
        _panelFocusNode.requestFocus();
      }
    });
  }

  void _removePanel() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    // 浮层内不要放 Tooltip：Flutter 3.47 的 Tooltip 走 OverlayPortal，
    // 在 CompositedTransformFollower 内布局时拿不到父级 paint transform。
    final panelWidth =
        overlayContext.appSidebarTokens.expandedWidth -
        overlayContext.appSpacing.sm * 2;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _removePanel,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.topRight,
          followerAnchor: Alignment.bottomRight,
          offset: const Offset(0, -_panelGap),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: _panelAnimationDuration,
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * context.appSpacing.xs),
                  child: child,
                ),
              );
            },
            child: CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.escape): _removePanel,
              },
              child: Focus(
                focusNode: _panelFocusNode,
                child: _ThemeColorPanel(
                  width: panelWidth,
                  onSelected: _removePanel,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(appShellSidebarCollapsedProvider, (previous, next) {
      if (next) {
        _removePanel();
      }
    });

    final appearance = ref.watch(appearanceProvider);
    final controller = ref.read(appearanceProvider.notifier);
    final mode = appearance.themeMode;
    final themeColor = appearance.themeColor
        .forBrightness(Theme.of(context).brightness)
        .primary;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconButton(
            key: const Key('sidebar-appearance-mode-toggle'),
            icon: Icon(_modeIcon(mode)),
            tooltip: _modeTooltip(mode),
            semanticLabel: _modeTooltip(mode),
            iconColor: context.appTextPalette.primary,
            onPressed: () =>
                unawaited(controller.setThemeMode(_nextMode(mode))),
          ),
          SizedBox(width: context.appSpacing.sm),
          AppIconButton(
            key: const Key('sidebar-theme-color-button'),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.palette_outlined),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: _themeColorDotSize,
                    height: _themeColorDotSize,
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.appColors.borderSubtle),
                    ),
                  ),
                ),
              ],
            ),
            tooltip: '主题色',
            semanticLabel: '主题色',
            iconColor: context.appTextPalette.primary,
            onPressed: _togglePanel,
          ),
        ],
      ),
    );
  }
}

ThemeMode _nextMode(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
  };
}

IconData _modeIcon(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => Icons.contrast_rounded,
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
  };
}

String _modeTooltip(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => '跟随系统 · 点击切换浅色',
    ThemeMode.light => '浅色 · 点击切换深色',
    ThemeMode.dark => '深色 · 点击切换跟随系统',
  };
}

class _ThemeColorPanel extends ConsumerWidget {
  const _ThemeColorPanel({required this.width, required this.onSelected});

  final double width;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final controller = ref.read(appearanceProvider.notifier);
    final spacing = context.appSpacing;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: context.appRadius.lgBorder,
        boxShadow: context.appShadows.panel,
      ),
      child: Material(
        color: context.appColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: context.appRadius.lgBorder,
          side: BorderSide(color: context.appColors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          key: const Key('sidebar-theme-color-popover'),
          width: width,
          padding: EdgeInsets.all(spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '主题色',
                style: resolveAppTextStyle(
                  context,
                  size: AppTextSize.s12,
                  weight: AppTextWeight.medium,
                  tone: AppTextTone.secondary,
                ),
              ),
              SizedBox(height: spacing.sm),
              Row(
                children: [
                  for (final themeColor in AppThemeColor.values)
                    Expanded(
                      child: _ThemeColorOption(
                        themeColor: themeColor,
                        selected: appearance.themeColor.id == themeColor.id,
                        onTap: () {
                          unawaited(controller.setThemeColor(themeColor));
                          onSelected();
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeColorOption extends StatefulWidget {
  const _ThemeColorOption({
    required this.themeColor,
    required this.selected,
    required this.onTap,
  });

  final AppThemeColor themeColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ThemeColorOption> createState() => _ThemeColorOptionState();
}

class _ThemeColorOptionState extends State<_ThemeColorOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final ringSize = context.appComponentTokens.iconSize2xl;
    final swatchColor = widget.themeColor
        .forBrightness(Theme.of(context).brightness)
        .primary;
    final ringColor = widget.selected
        ? Theme.of(context).colorScheme.primary
        : (_hovered ? colors.borderStrong : Colors.transparent);

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.themeColor.label,
      child: InkWell(
        key: Key('sidebar-theme-color-${widget.themeColor.id}'),
        onTap: widget.onTap,
        onHover: (hovered) {
          if (_hovered == hovered) {
            return;
          }
          setState(() => _hovered = hovered);
        },
        mouseCursor: SystemMouseCursors.click,
        borderRadius: context.appRadius.mdBorder,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: spacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                width: ringSize,
                height: ringSize,
                padding: EdgeInsets.all(spacing.xs - 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: 2),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: swatchColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.borderSubtle),
                  ),
                ),
              ),
              SizedBox(height: spacing.xs),
              Text(
                widget.themeColor.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: resolveAppTextStyle(
                  context,
                  size: AppTextSize.s10,
                  weight: widget.selected
                      ? AppTextWeight.medium
                      : AppTextWeight.regular,
                  tone: widget.selected
                      ? AppTextTone.accent
                      : AppTextTone.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
