import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:sakuramedia/theme/app_component_tokens.dart';
import 'package:sakuramedia/theme/app_colors.dart';
import 'package:sakuramedia/theme/app_form_tokens.dart';
import 'package:sakuramedia/theme/app_layout_tokens.dart';
import 'package:sakuramedia/theme/app_navigation_tokens.dart';
import 'package:sakuramedia/theme/app_overlay_tokens.dart';
import 'package:sakuramedia/theme/app_radius.dart';
import 'package:sakuramedia/theme/app_shadows.dart';
import 'package:sakuramedia/theme/app_sidebar_tokens.dart';
import 'package:sakuramedia/theme/app_spacing.dart';
import 'package:sakuramedia/theme/app_theme_color.dart';
import 'package:sakuramedia/theme/app_typography.dart';

export 'package:sakuramedia/theme/app_component_tokens.dart';
export 'package:sakuramedia/theme/app_colors.dart';
export 'package:sakuramedia/theme/app_form_tokens.dart';
export 'package:sakuramedia/theme/app_layout_tokens.dart';
export 'package:sakuramedia/theme/app_navigation_tokens.dart';
export 'package:sakuramedia/theme/app_overlay_tokens.dart';
export 'package:sakuramedia/theme/app_page_insets.dart';
export 'package:sakuramedia/theme/app_radius.dart';
export 'package:sakuramedia/theme/app_shadows.dart';
export 'package:sakuramedia/theme/app_sidebar_tokens.dart';
export 'package:sakuramedia/theme/app_spacing.dart';
export 'package:sakuramedia/theme/app_theme_color.dart';
export 'package:sakuramedia/theme/app_typography.dart';
export 'package:sakuramedia/widgets/base/typography/app_text.dart';

/// oktoast 在 MaterialApp 之外用独立 overlay 树显示 toast, 拿不到 ThemeData
const TextStyle kAppToastTextStyle = TextStyle(
  fontSize: 15,
  color: Colors.white,
);

/// oktoast 的 toast 底色。
///
/// 库默认是 `0xDD000000` 的裸黑，不属于项目色板；这里统一为文字主色
/// `AppTextPalette.primary` 的中性深色带 0xDD 透明度，让 toast 与项目暖
/// 中性色体系一致，而不是库自带的纯黑。
final Color kAppToastBackgroundColor = AppTextPalette.defaults().primary
    .withValues(alpha: 0xDD / 0xFF);

/// 深色模式下 toast 保持「深底浅字」，底色抬到层级面而不是纯黑。
TextStyle appToastTextStyleFor(Brightness brightness) {
  return brightness == Brightness.dark
      ? const TextStyle(fontSize: 15, color: Color(0xFFF5F3F2))
      : kAppToastTextStyle;
}

Color appToastBackgroundColorFor(Brightness brightness) {
  return brightness == Brightness.dark
      ? const Color(0xFF3A3A3A).withValues(alpha: 0xEB / 0xFF)
      : kAppToastBackgroundColor;
}

final sakuraThemeData = sakuraDesktopThemeData;

/// 浅色 + 酒红桌面主题；测试与旧调用方的稳定入口。
final sakuraDesktopThemeData = buildSakuraDesktopThemeData();

/// 浅色 + 酒红移动主题；测试与旧调用方的稳定入口。
final sakuraMobileThemeData = buildSakuraMobileThemeData();

ThemeData buildSakuraDesktopThemeData({
  Brightness brightness = Brightness.light,
  AppThemeColor themeColor = AppThemeColor.burgundy,
}) {
  return _buildSakuraThemeData(
    brightness: brightness,
    themeColor: themeColor,
    componentTokens: const AppComponentTokens.defaults(),
    formTokens: const AppFormTokens.defaults(),
    navigationTokens: const AppNavigationTokens.defaults(),
    textScale: const AppTextScale.defaults(),
    textWeights: const AppTextWeights.defaults(),
    baseTextPalette: const AppTextPalette.defaults(),
  );
}

ThemeData buildSakuraMobileThemeData({
  Brightness brightness = Brightness.light,
  AppThemeColor themeColor = AppThemeColor.burgundy,
}) {
  return _buildSakuraThemeData(
    brightness: brightness,
    themeColor: themeColor,
    componentTokens: const AppComponentTokens.mobile(),
    formTokens: const AppFormTokens.mobile(),
    navigationTokens: const AppNavigationTokens.mobile(),
    textScale: const AppTextScale.mobile(),
    textWeights: const AppTextWeights.mobile(),
    baseTextPalette: const AppTextPalette.mobile(),
  );
}

ThemeData _buildSakuraThemeData({
  required Brightness brightness,
  required AppThemeColor themeColor,
  required AppComponentTokens componentTokens,
  required AppFormTokens formTokens,
  required AppNavigationTokens navigationTokens,
  required AppTextScale textScale,
  required AppTextWeights textWeights,
  required AppTextPalette baseTextPalette,
}) {
  final brand = themeColor.forBrightness(brightness);
  final colors = AppColors.of(themeColor: themeColor, brightness: brightness);
  final textPalette = (brightness == Brightness.dark
          ? const AppTextPalette.dark()
          : baseTextPalette)
      .copyWith(accent: brand.accent);
  final shadows = brightness == Brightness.dark
      ? const AppShadows.dark()
      : const AppShadows.defaults();
  final colorScheme = brightness == Brightness.dark
      ? _darkColorScheme(brand)
      : _lightColorScheme(brand);

  // 这里只给直接使用的 Material 内置控件兜底：关掉 InkRipple / InkSparkle，
  // 并保留 hover 8% / 按下 12% 的叠色。自研可点组件不走这套（无 hover 底色、
  // 按下整体变淡，见 `AppInteractiveSurface`）；内置控件的 MD 交互样式待清理。
  const overlayTokens = AppOverlayTokens.defaults();
  final neutralOverlay = textPalette.primary;
  final hoverOverlay = neutralOverlay.withValues(
    alpha: overlayTokens.hoverAlpha,
  );
  final pressOverlay = neutralOverlay.withValues(
    alpha: overlayTokens.pressAlpha,
  );

  Color? resolveInteractionOverlay(Set<WidgetState> states) {
    if (states.contains(WidgetState.pressed)) {
      return pressOverlay;
    }
    if (states.contains(WidgetState.hovered)) {
      return hoverOverlay;
    }
    if (states.contains(WidgetState.focused)) {
      return pressOverlay;
    }
    return null;
  }

  final interactiveButtonStyle = ButtonStyle(
    mouseCursor: WidgetStateMouseCursor.clickable,
    overlayColor: WidgetStateProperty.resolveWith(resolveInteractionOverlay),
    splashFactory: NoSplash.splashFactory,
  );

  return ThemeData(brightness: brightness, useMaterial3: true).copyWith(
    scaffoldBackgroundColor: colors.surfacePage,
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: pressOverlay,
    hoverColor: hoverOverlay,
    focusColor: pressOverlay,
    colorScheme: colorScheme,
    textTheme: textScale
        .toTextTheme(textWeights)
        .apply(
          fontFamily: !kIsWeb && defaultTargetPlatform == TargetPlatform.windows
              ? kAppWindowsFontFamily
              : null,
        ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: interactiveButtonStyle),
    filledButtonTheme: FilledButtonThemeData(style: interactiveButtonStyle),
    iconButtonTheme: IconButtonThemeData(style: interactiveButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: interactiveButtonStyle),
    popupMenuTheme: const PopupMenuThemeData(
      mouseCursor: WidgetStateMouseCursor.clickable,
    ),
    radioTheme: const RadioThemeData(
      mouseCursor: WidgetStateMouseCursor.clickable,
    ),
    textButtonTheme: TextButtonThemeData(style: interactiveButtonStyle),
    checkboxTheme: const CheckboxThemeData(
      mouseCursor: WidgetStateMouseCursor.clickable,
    ),
    extensions: <ThemeExtension<dynamic>>[
      colors,
      componentTokens,
      formTokens,
      const AppLayoutTokens.defaults(),
      navigationTokens,
      const AppOverlayTokens.defaults(),
      const AppSpacing.defaults(),
      const AppRadius.defaults(),
      const AppSidebarTokens.defaults(),
      shadows,
      textScale,
      textWeights,
      textPalette,
    ],
  );
}

ColorScheme _lightColorScheme(AppBrandColors brand) {
  return ColorScheme(
    brightness: Brightness.light,
    primary: brand.primary,
    onPrimary: brand.onPrimary,
    secondary: brand.secondary,
    onSecondary: brand.onSecondary,
    error: const Color(0xFFB3261E),
    onError: const Color(0xFFFFFFFF),
    surface: const Color(0xFFFFFFFF),
    onSurface: const Color(0xFF1F1A18),
    primaryContainer: brand.primaryContainer,
    onPrimaryContainer: brand.onPrimaryContainer,
    secondaryContainer: brand.secondaryContainer,
    onSecondaryContainer: brand.onSecondaryContainer,
    tertiary: brand.tertiary,
    onTertiary: brand.onTertiary,
    tertiaryContainer: brand.tertiaryContainer,
    onTertiaryContainer: brand.onTertiaryContainer,
    errorContainer: const Color(0xFFF9DEDC),
    onErrorContainer: const Color(0xFF410E0B),
    surfaceTint: brand.surfaceTint,
    onSurfaceVariant: const Color(0xFF707070),
    outline: const Color(0xFFD6D6D6),
    outlineVariant: const Color(0xFFE8E8E8),
    shadow: const Color(0x1A2B1816),
    scrim: const Color(0x66000000),
    inverseSurface: const Color(0xFF362F2C),
    onInverseSurface: const Color(0xFFF8EEEA),
    inversePrimary: brand.inversePrimary,
  );
}

ColorScheme _darkColorScheme(AppBrandColors brand) {
  return ColorScheme(
    brightness: Brightness.dark,
    primary: brand.primary,
    onPrimary: brand.onPrimary,
    secondary: brand.secondary,
    onSecondary: brand.onSecondary,
    error: const Color(0xFFFFB4AB),
    onError: const Color(0xFF690005),
    surface: const Color(0xFF1E1E1E),
    onSurface: const Color(0xFFECE6E4),
    primaryContainer: brand.primaryContainer,
    onPrimaryContainer: brand.onPrimaryContainer,
    secondaryContainer: brand.secondaryContainer,
    onSecondaryContainer: brand.onSecondaryContainer,
    tertiary: brand.tertiary,
    onTertiary: brand.onTertiary,
    tertiaryContainer: brand.tertiaryContainer,
    onTertiaryContainer: brand.onTertiaryContainer,
    errorContainer: const Color(0xFF93000A),
    onErrorContainer: const Color(0xFFFFDAD6),
    surfaceTint: brand.surfaceTint,
    onSurfaceVariant: const Color(0xFFA8A19E),
    outline: const Color(0xFF8D8784),
    outlineVariant: const Color(0xFF464240),
    shadow: const Color(0x66000000),
    scrim: const Color(0x99000000),
    inverseSurface: const Color(0xFFE6E0DE),
    onInverseSurface: const Color(0xFF322F2E),
    inversePrimary: brand.inversePrimary,
  );
}
