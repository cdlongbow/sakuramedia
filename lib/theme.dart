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

final sakuraThemeData = sakuraDesktopThemeData;

const _desktopTextScale = AppTextScale.defaults();
const _desktopTextWeights = AppTextWeights.defaults();
const _desktopTextPalette = AppTextPalette.defaults();
const _mobileTextScale = AppTextScale.mobile();
const _mobileTextWeights = AppTextWeights.mobile();
const _mobileTextPalette = AppTextPalette.mobile();

final sakuraDesktopThemeData = _buildSakuraThemeData(
  componentTokens: const AppComponentTokens.defaults(),
  formTokens: const AppFormTokens.defaults(),
  navigationTokens: const AppNavigationTokens.defaults(),
  textScale: _desktopTextScale,
  textWeights: _desktopTextWeights,
  textPalette: _desktopTextPalette,
);

final sakuraMobileThemeData = _buildSakuraThemeData(
  componentTokens: const AppComponentTokens.mobile(),
  formTokens: const AppFormTokens.mobile(),
  navigationTokens: const AppNavigationTokens.mobile(),
  textScale: _mobileTextScale,
  textWeights: _mobileTextWeights,
  textPalette: _mobileTextPalette,
);

ThemeData _buildSakuraThemeData({
  required AppComponentTokens componentTokens,
  required AppFormTokens formTokens,
  required AppNavigationTokens navigationTokens,
  required AppTextScale textScale,
  required AppTextWeights textWeights,
  required AppTextPalette textPalette,
}) {
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

  return ThemeData(brightness: Brightness.light, useMaterial3: true).copyWith(
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: pressOverlay,
    hoverColor: hoverOverlay,
    focusColor: pressOverlay,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF6B2D2A),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF8B5E57),
      onSecondary: Color(0xFFFFFFFF),
      error: Color(0xFFB3261E),
      onError: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1F1A18),
      primaryContainer: Color(0xFFE8D8D3),
      onPrimaryContainer: Color(0xFF2F1412),
      secondaryContainer: Color(0xFFF2E6E1),
      onSecondaryContainer: Color(0xFF2B201E),
      tertiary: Color(0xFF6C584C),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFE8DDD6),
      onTertiaryContainer: Color(0xFF251C17),
      errorContainer: Color(0xFFF9DEDC),
      onErrorContainer: Color(0xFF410E0B),
      surfaceTint: Color(0xFF6B2D2A),
      onSurfaceVariant: Color(0xFF707070),
      outline: Color(0xFFD6D6D6),
      outlineVariant: Color(0xFFE8E8E8),
      shadow: Color(0x1A2B1816),
      scrim: Color(0x66000000),
      inverseSurface: Color(0xFF362F2C),
      onInverseSurface: Color(0xFFF8EEEA),
      inversePrimary: Color(0xFFFFB4A9),
    ),
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
      const AppColors.defaults(),
      componentTokens,
      formTokens,
      const AppLayoutTokens.defaults(),
      navigationTokens,
      const AppOverlayTokens.defaults(),
      const AppSpacing.defaults(),
      const AppRadius.defaults(),
      const AppSidebarTokens.defaults(),
      const AppShadows.defaults(),
      textScale,
      textWeights,
      textPalette,
    ],
  );
}
