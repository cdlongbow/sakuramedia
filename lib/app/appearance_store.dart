import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakuramedia/theme/app_theme_color.dart';

/// 外观偏好：明暗模式 + 主题色。
@immutable
class AppearanceSettings {
  const AppearanceSettings({
    required this.brightness,
    required this.themeColor,
  });

  static const AppearanceSettings defaults = AppearanceSettings(
    brightness: Brightness.light,
    themeColor: AppThemeColor.burgundy,
  );

  final Brightness brightness;
  final AppThemeColor themeColor;

  AppearanceSettings copyWith({
    Brightness? brightness,
    AppThemeColor? themeColor,
  }) {
    return AppearanceSettings(
      brightness: brightness ?? this.brightness,
      themeColor: themeColor ?? this.themeColor,
    );
  }
}

abstract class AppearanceStore {
  AppearanceSettings read();
  Future<void> save(AppearanceSettings settings);
}

class SharedPreferencesAppearanceStore implements AppearanceStore {
  SharedPreferencesAppearanceStore(this._preferences);

  static const String brightnessKey = 'appearance.brightness';
  static const String themeColorKey = 'appearance.theme_color';

  final SharedPreferences _preferences;

  static Future<AppearanceStore> create() async {
    final preferences = await SharedPreferences.getInstance();
    return SharedPreferencesAppearanceStore(preferences);
  }

  @override
  AppearanceSettings read() {
    return AppearanceSettings(
      brightness: _preferences.getString(brightnessKey) == 'dark'
          ? Brightness.dark
          : Brightness.light,
      themeColor: AppThemeColor.fromId(_preferences.getString(themeColorKey)),
    );
  }

  @override
  Future<void> save(AppearanceSettings settings) async {
    try {
      await _preferences.setString(
        brightnessKey,
        settings.brightness == Brightness.dark ? 'dark' : 'light',
      );
      await _preferences.setString(themeColorKey, settings.themeColor.id);
    } catch (_) {
      // 持久化失败不阻塞切换。
    }
  }
}

class InMemoryAppearanceStore implements AppearanceStore {
  InMemoryAppearanceStore([this._settings = AppearanceSettings.defaults]);

  AppearanceSettings _settings;

  @override
  AppearanceSettings read() => _settings;

  @override
  Future<void> save(AppearanceSettings settings) async {
    _settings = settings;
  }
}
