import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_switch.dart';

/// 播放器控制条上的「画质增强」开关。
///
/// 桌面控制条空间充足，展示「画质增强」标签 + 开关；移动控制条宽度紧张，
/// 只保留开关本体（触控目标仍由外层容器保证），避免挤出控制条。
///
/// 状态用 [enabledListenable] 驱动自身重建：控制条由 media_kit 的主题数据
/// 提供，而该主题的 `updateShouldNotify` 判断写反，直接传 bool 不会触发重建。
class MoviePlayerQualityButton extends StatelessWidget {
  const MoviePlayerQualityButton({
    super.key,
    required this.enabledListenable,
    required this.onPressed,
    this.label,
  });

  final ValueListenable<bool> enabledListenable;
  final VoidCallback onPressed;

  /// 为 `null` 时只渲染开关本体。
  final String? label;

  @override
  Widget build(BuildContext context) {
    final overlayTokens = context.appOverlayTokens;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          constraints: BoxConstraints(
            minWidth: overlayTokens.controlMinWidth,
            minHeight: overlayTokens.controlMinHeight,
          ),
          padding: EdgeInsets.symmetric(
            // 只放开关本体时不留横向内边距，宽度与既有文字按钮一致（48）。
            horizontal: label == null
                ? 0
                : overlayTokens.controlHorizontalPadding,
            vertical: overlayTokens.controlVerticalPadding,
          ),
          child: ValueListenableBuilder<bool>(
            valueListenable: enabledListenable,
            builder: (context, enabled, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label != null) ...[
                    Text(
                      label!,
                      key: const Key('movie-player-quality-button-label'),
                      style: resolveAppTextStyle(
                        context,
                        size: AppTextSize.s14,
                        tone: AppTextTone.onMedia,
                      ),
                    ),
                    SizedBox(width: context.appSpacing.sm),
                  ],
                  AppSwitch(
                    key: const Key('movie-player-quality-button'),
                    value: enabled,
                    variant: AppSwitchVariant.onMedia,
                    onChanged: (_) => onPressed(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
