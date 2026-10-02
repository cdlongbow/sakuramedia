import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/interaction/app_interactive_surface.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

enum AppButtonSize { large, medium, small, xSmall, xxSmall, xxxSmall }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.labelKey,
    this.variant = AppButtonVariant.secondary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isSelected = false,
    this.borderRadius,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.disabledOpacity = 0.56,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Widget? trailingIcon;
  final Key? labelKey;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isSelected;

  /// 覆盖默认圆角（默认 [AppRadius.smBorder]）；品牌主 CTA 可用 pill 圆角。
  final BorderRadius? borderRadius;

  /// 覆盖禁用态背景/文字色（默认灰底 + 主题前景色）；仅在确有品牌禁用样式时使用。
  final Color? disabledBackgroundColor;
  final Color? disabledForegroundColor;
  final double disabledOpacity;

  bool get _isEnabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final componentTokens = context.appComponentTokens;
    final (height, horizontal, gap, iconSize, textSize) = switch (size) {
      AppButtonSize.large => (
        componentTokens.buttonHeightLg,
        componentTokens.buttonHorizontalPaddingMd,
        componentTokens.buttonGapMd,
        componentTokens.iconSizeSm,
        AppTextSize.s14,
      ),
      AppButtonSize.medium => (
        componentTokens.buttonHeightMd,
        componentTokens.buttonHorizontalPaddingMd,
        componentTokens.buttonGapMd,
        componentTokens.iconSizeSm,
        AppTextSize.s14,
      ),
      AppButtonSize.small => (
        componentTokens.buttonHeightSm,
        componentTokens.buttonHorizontalPaddingSm,
        componentTokens.buttonGapSm,
        componentTokens.iconSizeSm,
        AppTextSize.s14,
      ),
      AppButtonSize.xSmall => (
        componentTokens.buttonHeightXs,
        componentTokens.buttonHorizontalPaddingXs,
        componentTokens.buttonGapXs,
        componentTokens.iconSizeXs,
        AppTextSize.s12,
      ),
      AppButtonSize.xxSmall => (
        componentTokens.buttonHeight2xs,
        componentTokens.buttonHorizontalPadding2xs,
        componentTokens.buttonGap2xs,
        componentTokens.iconSize2xs,
        AppTextSize.s10,
      ),
      AppButtonSize.xxxSmall => (
        componentTokens.buttonHeight3xs,
        componentTokens.buttonHorizontalPadding3xs,
        componentTokens.buttonGap3xs,
        componentTokens.iconSize3xs,
        AppTextSize.s10,
      ),
    };
    final borderRadius = this.borderRadius ?? context.appRadius.smBorder;
    final isSecondarySelected =
        variant == AppButtonVariant.secondary && isSelected;
    final isGhostSelected = variant == AppButtonVariant.ghost && isSelected;

    final backgroundColor = switch (variant) {
      AppButtonVariant.primary => theme.colorScheme.primary,
      AppButtonVariant.secondary =>
        isSecondarySelected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
      AppButtonVariant.ghost =>
        isGhostSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
      AppButtonVariant.danger => colors.errorSurface,
    };

    final borderColor = switch (variant) {
      AppButtonVariant.primary => theme.colorScheme.primary,
      AppButtonVariant.secondary =>
        isSecondarySelected ? theme.colorScheme.primary : Colors.transparent,
      AppButtonVariant.ghost =>
        isGhostSelected ? theme.colorScheme.primary : Colors.transparent,
      AppButtonVariant.danger => context.appTextPalette.error.withValues(
        alpha: 0.2,
      ),
    };

    final disabledColor = colors.borderSubtle;
    final effectiveDisabledBackground =
        disabledBackgroundColor ?? disabledColor;
    final tone = switch (variant) {
      AppButtonVariant.primary => AppTextTone.onMedia,
      AppButtonVariant.secondary =>
        isSecondarySelected ? AppTextTone.accent : AppTextTone.primary,
      AppButtonVariant.ghost => AppTextTone.accent,
      AppButtonVariant.danger => AppTextTone.error,
    };
    final foregroundColor = resolveAppTextToneColor(context, tone);
    final effectiveForeground = _isEnabled
        ? foregroundColor
        : (disabledForegroundColor ?? foregroundColor);
    final labelStyle = resolveAppTextStyle(context, size: textSize, tone: tone)
        .copyWith(
          color: effectiveForeground,
          height: 1,
          leadingDistribution: TextLeadingDistribution.even,
        );

    return Opacity(
      opacity: _isEnabled ? 1 : disabledOpacity,
      child: AppInteractiveSurface(
        enabled: _isEnabled,
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: height,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          decoration: BoxDecoration(
            color: _isEnabled ? backgroundColor : effectiveDisabledBackground,
            borderRadius: borderRadius,
            border: Border.all(
              color: _isEnabled ? borderColor : effectiveDisabledBackground,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: CircularProgressIndicator.adaptive(
                    backgroundColor: switch (Theme.of(context).platform) {
                      TargetPlatform.iOS ||
                      TargetPlatform.macOS => effectiveForeground,
                      _ => null,
                    },
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      effectiveForeground,
                    ),
                  ),
                )
              else if (icon != null)
                IconTheme(
                  data: IconThemeData(
                    size: iconSize,
                    color: effectiveForeground,
                  ),
                  child: icon!,
                ),
              if (isLoading || icon != null) SizedBox(width: gap),
              Flexible(
                child: Text(
                  key: labelKey,
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ),
              if (trailingIcon != null) ...[
                SizedBox(width: gap),
                IconTheme(
                  data: IconThemeData(
                    size: iconSize,
                    color: effectiveForeground,
                  ),
                  child: trailingIcon!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
