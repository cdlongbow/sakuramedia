import 'package:material_ui/material_ui.dart';

/// 一套主题色的品牌锚点（明/暗各一组）。
///
/// 中性面、边框、文字和状态色由 [AppColors] / [AppTextPalette] 的明暗规格
/// 统一提供；这里只定义随主题色变化的槽位。新增主题色 = 增加一个
/// [AppThemeColor] 常量并加入 [AppThemeColor.values]。
@immutable
class AppThemeColor {
  const AppThemeColor({
    required this.id,
    required this.label,
    required this.light,
    required this.dark,
  });

  final String id;
  final String label;
  final AppBrandColors light;
  final AppBrandColors dark;

  static const String burgundyId = 'burgundy';

  static const AppThemeColor burgundy = AppThemeColor(
    id: burgundyId,
    label: '酒红',
    light: AppBrandColors(
      primary: Color(0xFF6B2D2A),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFE8D8D3),
      onPrimaryContainer: Color(0xFF2F1412),
      secondary: Color(0xFF8B5E57),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFF2E6E1),
      onSecondaryContainer: Color(0xFF2B201E),
      tertiary: Color(0xFF6C584C),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFE8DDD6),
      onTertiaryContainer: Color(0xFF251C17),
      surfaceTint: Color(0xFF6B2D2A),
      inversePrimary: Color(0xFFFFB4A9),
      selectionSurface: Color(0xFFF7ECEB),
      selectionBorder: Color(0xFF6B2D2A),
      selectedPlotBorder: Color(0xFF6B2D2A),
      accent: Color(0xFF6B2D2A),
    ),
    dark: AppBrandColors(
      primary: Color(0xFFE9A29B),
      onPrimary: Color(0xFF4A1310),
      primaryContainer: Color(0xFF5C2A26),
      onPrimaryContainer: Color(0xFFFFDAD5),
      secondary: Color(0xFFE5BBB3),
      onSecondary: Color(0xFF442925),
      secondaryContainer: Color(0xFF5D3A35),
      onSecondaryContainer: Color(0xFFFFDCD5),
      tertiary: Color(0xFFD8C2B6),
      onTertiary: Color(0xFF3B2A22),
      tertiaryContainer: Color(0xFF52443B),
      onTertiaryContainer: Color(0xFFF5DFD3),
      surfaceTint: Color(0xFFE9A29B),
      inversePrimary: Color(0xFFA6534D),
      selectionSurface: Color(0xFF3A2422),
      selectionBorder: Color(0xFFE9A29B),
      selectedPlotBorder: Color(0xFFE9A29B),
      accent: Color(0xFFE9A29B),
    ),
  );

  static const List<AppThemeColor> values = <AppThemeColor>[burgundy];

  static AppThemeColor fromId(String? id) {
    for (final color in values) {
      if (color.id == id) {
        return color;
      }
    }
    return burgundy;
  }

  AppBrandColors forBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}

/// 主题色在某一明暗模式下的全部品牌槽位。
@immutable
class AppBrandColors {
  const AppBrandColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.surfaceTint,
    required this.inversePrimary,
    required this.selectionSurface,
    required this.selectionBorder,
    required this.selectedPlotBorder,
    required this.accent,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color surfaceTint;
  final Color inversePrimary;
  final Color selectionSurface;
  final Color selectionBorder;
  final Color selectedPlotBorder;
  final Color accent;
}
