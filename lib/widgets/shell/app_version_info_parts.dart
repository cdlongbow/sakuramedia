import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';

/// 版本信息的一行（label + 右对齐值），版本卡片与侧栏版本弹窗共用。
class AppVersionRow extends StatelessWidget {
  const AppVersionRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s12,
            tone: AppTextTone.muted,
          ),
        ),
        SizedBox(width: context.appSpacing.sm),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s12,
              weight: AppTextWeight.medium,
              tone: AppTextTone.tertiary,
            ),
          ),
        ),
      ],
    );
  }
}

/// 「发现可用更新」提示块（客户端 / 服务端 / 插件数量），版本卡片与侧栏
/// 版本弹窗共用，避免两处维护同一段文案与样式。
class AppVersionUpdateNotice extends StatelessWidget {
  const AppVersionUpdateNotice({
    super.key,
    required this.frontendUpdateVersion,
    required this.backendUpdateVersion,
    required this.pluginUpdateCount,
  });

  final String? frontendUpdateVersion;
  final String? backendUpdateVersion;
  final int pluginUpdateCount;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (frontendUpdateVersion != null) '客户端 $frontendUpdateVersion',
      if (backendUpdateVersion != null) '服务端 $backendUpdateVersion',
      if (pluginUpdateCount > 0) '$pluginUpdateCount 个插件',
    ].join(' · ');

    return Container(
      key: const Key('sidebar-update-notice'),
      padding: EdgeInsets.all(context.appSpacing.sm),
      decoration: BoxDecoration(
        color: context.appColors.selectionSurface,
        borderRadius: context.appRadius.smBorder,
      ),
      child: Row(
        children: [
          Icon(
            Icons.system_update_rounded,
            size: context.appComponentTokens.iconSizeSm,
            color: context.appTextPalette.accent,
          ),
          SizedBox(width: context.appSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '发现可用更新',
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s12,
                    weight: AppTextWeight.medium,
                    tone: AppTextTone.accent,
                  ),
                ),
                SizedBox(height: context.appSpacing.xs),
                Text(
                  details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s10,
                    tone: AppTextTone.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
