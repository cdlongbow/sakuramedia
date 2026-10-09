import 'package:material_ui/material_ui.dart';
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
import 'package:sakuramedia/widgets/base/overlays/app_desktop_dialog.dart';
import 'package:sakuramedia/widgets/shell/app_version_info_parts.dart';

/// 桌面侧栏底部的版本单行页脚：常态只占一行，完整信息收进弹窗。
///
/// 移动端抽屉继续使用 [AppVersionInfoCard]；更新检查状态两处共用
/// [appUpdateCheckProvider]（每小时轮询，失败静默），watch 即触发检查。
class SidebarVersionFooter extends ConsumerWidget {
  const SidebarVersionFooter({
    super.key = const Key('sidebar-version-info'),
  });

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
    final oneLine =
        '${versionInfo.frontendVersionLabel} · ${versionInfo.backendVersionLabel}';

    return Tooltip(
      message: versionInfo.tooltipLabel,
      waitDuration: const Duration(milliseconds: 300),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: context.appRadius.smBorder,
          mouseCursor: SystemMouseCursors.click,
          hoverColor: context.appColors.sidebarHoverBackground,
          onTap: () => _showVersionDialog(
            context,
            ref,
            versionInfo: versionInfo,
            pluginUpdateCount: pluginUpdateCount,
            hasUpdates: hasUpdates,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.appSpacing.md,
              vertical: context.appSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: context.appComponentTokens.iconSizeSm,
                  color: context.appTextPalette.muted,
                ),
                SizedBox(width: context.appSpacing.sm),
                Expanded(
                  child: Text(
                    oneLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: resolveAppTextStyle(
                      context,
                      size: AppTextSize.s12,
                      weight: AppTextWeight.regular,
                      tone: AppTextTone.muted,
                    ),
                  ),
                ),
                if (hasUpdates) ...[
                  SizedBox(width: context.appSpacing.sm),
                  const AppBadge(
                    key: Key('sidebar-version-update-badge'),
                    label: '有更新',
                    tone: AppBadgeTone.primary,
                    size: AppBadgeSize.compact,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVersionDialog(
    BuildContext context,
    WidgetRef ref, {
    required AppVersionInfoState versionInfo,
    required int pluginUpdateCount,
    required bool hasUpdates,
  }) {
    final updates = ref.read(appUpdateCheckProvider);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AppDesktopDialog(
        dialogKey: const Key('sidebar-version-dialog'),
        contentKey: const Key('sidebar-version-dialog-content'),
        width: dialogContext.appLayoutTokens.dialogWidthSm,
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
                      dialogContext,
                      size: AppTextSize.s16,
                      weight: AppTextWeight.semibold,
                      tone: AppTextTone.primary,
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
            SizedBox(height: dialogContext.appSpacing.md),
            AppVersionRow(
              label: '客户端',
              value: versionInfo.frontendVersionLabel,
            ),
            SizedBox(height: dialogContext.appSpacing.xs),
            AppVersionRow(
              label: '服务端',
              value: versionInfo.backendVersionLabel,
            ),
            if (hasUpdates) ...[
              SizedBox(height: dialogContext.appSpacing.sm),
              Divider(height: 1, color: dialogContext.appColors.divider),
              SizedBox(height: dialogContext.appSpacing.sm),
              AppVersionUpdateNotice(
                frontendUpdateVersion: updates.frontendUpdateVersion,
                backendUpdateVersion: updates.backendUpdateVersion,
                pluginUpdateCount: pluginUpdateCount,
              ),
            ],
            SizedBox(height: dialogContext.appSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  key: const Key('sidebar-version-dialog-close'),
                  label: '关闭',
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.small,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                if (pluginUpdateCount > 0) ...[
                  SizedBox(width: dialogContext.appSpacing.sm),
                  AppButton(
                    key: const Key('sidebar-version-dialog-go-plugins'),
                    label: '查看插件更新',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.small,
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      ref
                          .read(configurationTabRequestProvider.notifier)
                          .request('configuration-tab-plugins');
                      context.goPrimaryRoute(desktopConfigurationPath);
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
