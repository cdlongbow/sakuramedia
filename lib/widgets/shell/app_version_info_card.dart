import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/app/app_version_info_state.dart';
import 'package:sakuramedia/app/providers/app_shell_providers.dart';
import 'package:sakuramedia/app/providers/app_update_check_provider.dart';
import 'package:sakuramedia/features/plugins/presentation/providers/plugins_provider.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/l10n/app_l10n.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_badge.dart';
import 'package:sakuramedia/widgets/shell/app_version_info_parts.dart';

/// 移动抽屉里的版本信息卡片：完整信息内联展示。
///
/// 更新检查状态与桌面侧栏页脚共用 [appUpdateCheckProvider]（每小时轮询，
/// 失败静默），watch 即触发检查。
class AppVersionInfoCard extends ConsumerWidget {
  const AppVersionInfoCard({super.key, this.cardKey});

  final Key? cardKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = appL10n(context);
    final versionInfo =
        ref.watch(appVersionInfoProvider).value ?? AppVersionInfoState.initial;
    final pluginUpdateCount =
        ref.watch(pluginsProvider).value?.updates.length ?? 0;
    final updates = ref.watch(appUpdateCheckProvider);
    final frontendVersion = versionInfo.frontendVersionLabel;
    final backendVersion = versionInfo.backendVersionLabel;
    final hasUpdates =
        updates.hasFrontendUpdate ||
        updates.hasBackendUpdate ||
        pluginUpdateCount > 0;

    return Container(
      key: cardKey ?? const Key('sidebar-version-info'),
      padding: EdgeInsets.all(context.appSpacing.md),
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(color: context.appColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.shellSystemVersion,
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s12,
                    weight: AppTextWeight.medium,
                    tone: AppTextTone.tertiary,
                  ),
                ),
              ),
              if (hasUpdates)
                AppBadge(
                  label: l10n.shellUpdateBadge,
                  tone: AppBadgeTone.primary,
                  size: AppBadgeSize.compact,
                ),
            ],
          ),
          SizedBox(height: context.appSpacing.sm),
          AppVersionRow(label: l10n.shellClientLabel, value: frontendVersion),
          SizedBox(height: context.appSpacing.xs),
          AppVersionRow(label: l10n.shellServerLabel, value: backendVersion),
          if (hasUpdates) ...[
            SizedBox(height: context.appSpacing.sm),
            Divider(height: 1, color: context.appColors.divider),
            SizedBox(height: context.appSpacing.sm),
            AppVersionUpdateNotice(
              frontendUpdateVersion: updates.frontendUpdateVersion,
              backendUpdateVersion: updates.backendUpdateVersion,
              pluginUpdateCount: pluginUpdateCount,
            ),
          ],
        ],
      ),
    );
  }
}
