import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/interaction/app_interactive_surface.dart';

/// 开关的配色变体。
enum AppSwitchVariant {
  /// 浅色内容面（设置 / 管理列表）默认配色。
  surface,

  /// 深色媒体浮层：品牌色在黑色播放器上对比度不足，开启态改用品牌浅底
  /// + 品牌色拇指，关闭态用半透明白轨道 + 白色拇指。
  onMedia,
}

/// 紧凑型启停开关。
///
/// 用于设置/管理类列表右侧的「启用/停用」操作。尺寸来自
/// [AppComponentTokens]（桌面 36×20、移动 44×24），开启态使用品牌色，
/// 避免 Material 默认 Switch 在桌面端显得过大。
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.variant = AppSwitchVariant.surface,
  });

  /// 当前开关状态。
  final bool value;

  /// 状态变化回调；传 `null` 时开关置灰且不可点。
  final ValueChanged<bool>? onChanged;

  /// 配色变体，默认浅色内容面。
  final AppSwitchVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tokens = context.appComponentTokens;
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onChanged != null;
    final onMedia = context.appTextPalette.onMedia;
    final onMediaTrack = onMedia.withValues(
      alpha: context.appOverlayTokens.switchTrackAlpha,
    );
    final isOnMedia = variant == AppSwitchVariant.onMedia;
    final trackWidth = tokens.switchTrackWidth;
    final trackHeight = tokens.switchTrackHeight;
    final thumbDiameter = tokens.switchThumbDiameter;
    final thumbInset = (trackHeight - thumbDiameter) / 2;
    final trackColor = !enabled
        ? (isOnMedia ? onMediaTrack : colors.borderSubtle)
        : value
        ? (isOnMedia ? colorScheme.primaryContainer : colorScheme.primary)
        : (isOnMedia ? onMediaTrack : colors.borderStrong);
    final thumbColor = !enabled
        ? (isOnMedia ? onMediaTrack : colors.surfaceMuted)
        : isOnMedia
        ? (value ? colorScheme.primary : onMedia)
        : colors.surfaceCard;

    return Semantics(
      toggled: value,
      enabled: enabled,
      button: true,
      child: AppInteractiveSurface(
        enabled: enabled,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          width: trackWidth,
          height: trackHeight,
          padding: EdgeInsets.all(thumbInset),
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: context.appRadius.pillBorder,
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: thumbDiameter,
              height: thumbDiameter,
              decoration: BoxDecoration(
                color: thumbColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
