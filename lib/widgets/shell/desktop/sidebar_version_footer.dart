import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/app/app_version_info_state.dart';
import 'package:sakuramedia/app/providers/app_shell_providers.dart';
import 'package:sakuramedia/app/providers/app_update_check_provider.dart';
import 'package:sakuramedia/features/configuration/presentation/providers/configuration_tab_request_provider.dart';
import 'package:sakuramedia/features/plugins/presentation/providers/plugins_provider.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/routes/app_navigation_actions.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_badge.dart';
import 'package:sakuramedia/widgets/shell/app_version_info_parts.dart';

const double _sidebarVersionUpdateDotSize = 6;

/// 桌面侧栏底部的版本信息：常态一行，点开后向上弹出轻量版本浮层。
///
/// 移动端抽屉继续使用 [AppVersionInfoCard]；更新检查状态两处共用
/// [appUpdateCheckProvider]（每小时轮询，失败静默），watch 即触发检查。
class SidebarVersionFooter extends ConsumerStatefulWidget {
  const SidebarVersionFooter({super.key = const Key('sidebar-version-info')});

  @override
  ConsumerState<SidebarVersionFooter> createState() =>
      _SidebarVersionFooterState();
}

class _SidebarVersionFooterState extends ConsumerState<SidebarVersionFooter> {
  static const double _popoverWidth = 300;
  static const double _popoverGap = 8;
  static const Duration _popoverAnimationDuration = Duration(milliseconds: 140);

  final LayerLink _layerLink = LayerLink();
  final FocusNode _popoverFocusNode = FocusNode(
    debugLabel: 'sidebar-version-popover',
  );
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removePopover();
    _popoverFocusNode.dispose();
    super.dispose();
  }

  void _togglePopover() {
    if (_overlayEntry != null) {
      _removePopover();
      return;
    }
    _showPopover();
  }

  void _showPopover() {
    _overlayEntry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_overlayEntry!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _overlayEntry != null) {
        _popoverFocusNode.requestFocus();
      }
    });
  }

  void _removePopover() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _openPlugins() {
    _removePopover();
    ref
        .read(configurationTabRequestProvider.notifier)
        .request('configuration-tab-plugins');
    context.goPrimaryRoute(desktopConfigurationPath);
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    // 浮层内不要放 Tooltip：Flutter 3.47 的 Tooltip 走 OverlayPortal，
    // 在 CompositedTransformFollower 内布局时拿不到父级 paint transform。
    final width = math.min(
      _popoverWidth,
      MediaQuery.sizeOf(overlayContext).width - overlayContext.appSpacing.xxl,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _removePopover,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.topLeft,
          followerAnchor: Alignment.bottomLeft,
          offset: const Offset(0, -_popoverGap),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: _popoverAnimationDuration,
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
                const SingleActivator(LogicalKeyboardKey.escape):
                    _removePopover,
              },
              child: Focus(
                focusNode: _popoverFocusNode,
                child: _VersionPopoverContent(
                  width: width,
                  onGoPlugins: _openPlugins,
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
        _removePopover();
      }
    });

    final versionInfo =
        ref.watch(appVersionInfoProvider).value ?? AppVersionInfoState.initial;
    final pluginUpdateCount =
        ref.watch(pluginsProvider).value?.updates.length ?? 0;
    final updates = ref.watch(appUpdateCheckProvider);
    final hasUpdates =
        updates.hasFrontendUpdate ||
        updates.hasBackendUpdate ||
        pluginUpdateCount > 0;
    final oneLine =
        '${versionInfo.frontendVersionLabel} · ${versionInfo.backendVersionLabel}';
    final tooltip = hasUpdates
        ? '${versionInfo.tooltipLabel} · 有更新'
        : versionInfo.tooltipLabel;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 300),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: context.appRadius.smBorder,
            mouseCursor: SystemMouseCursors.click,
            hoverColor: context.appColors.sidebarHoverBackground,
            onTap: _togglePopover,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.appSpacing.md,
                vertical: context.appSpacing.xs,
              ),
              child: Row(
                children: [
                  _VersionInfoIcon(hasUpdates: hasUpdates),
                  SizedBox(width: context.appSpacing.sm),
                  Expanded(
                    child: Text(
                      oneLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: resolveAppTextStyle(
                        context,
                        size: AppTextSize.s10,
                        weight: AppTextWeight.regular,
                        tone: AppTextTone.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VersionInfoIcon extends StatelessWidget {
  const _VersionInfoIcon({required this.hasUpdates});

  final bool hasUpdates;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.info_outline_rounded,
      size: context.appComponentTokens.iconSizeSm,
      color: context.appTextPalette.muted,
    );
    if (!hasUpdates) {
      return icon;
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -1,
          top: -1,
          child: Container(
            key: const Key('sidebar-version-update-dot'),
            width: _sidebarVersionUpdateDotSize,
            height: _sidebarVersionUpdateDotSize,
            decoration: BoxDecoration(
              color: context.appTextPalette.accent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _VersionPopoverContent extends ConsumerWidget {
  const _VersionPopoverContent({
    required this.width,
    required this.onGoPlugins,
  });

  final double width;
  final VoidCallback onGoPlugins;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionInfo =
        ref.watch(appVersionInfoProvider).value ?? AppVersionInfoState.initial;
    final pluginUpdateCount =
        ref.watch(pluginsProvider).value?.updates.length ?? 0;
    final updates = ref.watch(appUpdateCheckProvider);
    final hasUpdates =
        updates.hasFrontendUpdate ||
        updates.hasBackendUpdate ||
        pluginUpdateCount > 0;
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
          key: const Key('sidebar-version-popover'),
          width: width,
          padding: EdgeInsets.all(spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '系统版本',
                      style: resolveAppTextStyle(
                        context,
                        size: AppTextSize.s14,
                        weight: AppTextWeight.semibold,
                      ),
                    ),
                  ),
                  if (hasUpdates)
                    const AppBadge(
                      label: '有更新',
                      tone: AppBadgeTone.primary,
                      size: AppBadgeSize.compact,
                    ),
                ],
              ),
              SizedBox(height: spacing.md),
              AppVersionRow(
                label: '客户端',
                value: versionInfo.frontendVersionLabel,
              ),
              SizedBox(height: spacing.xs),
              AppVersionRow(
                label: '服务端',
                value: versionInfo.backendVersionLabel,
              ),
              if (hasUpdates) ...[
                SizedBox(height: spacing.sm),
                AppVersionUpdateNotice(
                  frontendUpdateVersion: updates.frontendUpdateVersion,
                  backendUpdateVersion: updates.backendUpdateVersion,
                  pluginUpdateCount: pluginUpdateCount,
                ),
              ],
              if (pluginUpdateCount > 0) ...[
                SizedBox(height: spacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    key: const Key('sidebar-version-popover-go-plugins'),
                    label: '查看插件更新',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.small,
                    onPressed: onGoPlugins,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
