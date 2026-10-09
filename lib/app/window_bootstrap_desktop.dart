import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/app/app_window_fullscreen.dart';
import 'package:sakuramedia/app/appearance_store.dart';
import 'package:sakuramedia/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

const Size _defaultWindowSize = Size(1280, 720);
const Size _minimumWindowSize = Size(1280, 720);

const String _prefsWidthKey = 'desktop_window:width';
const String _prefsHeightKey = 'desktop_window:height';
const String _prefsMaximizedKey = 'desktop_window:maximized';

const MethodChannel _windowAppearanceChannel = MethodChannel(
  'sakuramedia/window_appearance',
);

Future<void> bootstrapDesktopWindow() async {
  await windowManager.ensureInitialized();
  final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
  final isWindows = defaultTargetPlatform == TargetPlatform.windows;

  final restored = await _readPersistedWindowState();
  final appearance = await _readPersistedAppearance();
  final effective = effectiveBrightness(
    appearance,
    WidgetsBinding.instance.platformDispatcher.platformBrightness,
  );
  final initialColors = AppColors.of(
    themeColor: appearance.themeColor,
    brightness: effective,
  );

  final windowOptions = WindowOptions(
    size: restored.size,
    minimumSize: _minimumWindowSize,
    center: true,
    // macOS 走系统毛玻璃（透明窗口）；其它桌面是无边框不透明窗口：内容铺满
    // 整窗，窗口底色只在重绘间隙露出来，取内容面色。
    backgroundColor: isMacOS
        ? Colors.transparent
        : initialColors.surfaceElevated,
    skipTaskbar: false,
    titleBarStyle: isMacOS || isWindows
        ? TitleBarStyle.hidden
        : TitleBarStyle.normal,
    // macOS 红绿灯改为 Flutter 自绘（AppMacTrafficLights），隐藏系统按钮，
    // 避免与自绘圆点重复；其他平台保持原样。
    windowButtonVisibility: !isMacOS,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    if (isWindows) {
      // 无边框：客户区铺满整窗、没有系统留的 resize 带；改尺寸热区由
      // AppWindowsFrame 的透明边缘补回，全屏见 app_window_fullscreen.dart。
      await windowManager.setAsFrameless();
      // 无边框窗口默认没有系统阴影，用 DWM 的 1px 扩展边把阴影找回来。
      await windowManager.setHasShadow(true);
    }
    if (isMacOS) {
      await _applyMacAppearance(effective);
    }
    if (restored.maximized) {
      await windowManager.maximize();
    }
    await windowManager.show();
    await windowManager.focus();
  });

  windowManager.addListener(_DesktopWindowStatePersistor());
}

/// 切换明暗时同步桌面窗口外观（macOS 毛玻璃外观 / 其它平台窗口底色）。
Future<void> applyDesktopWindowBrightness(Brightness brightness) async {
  if (resolveAppPlatform() != AppPlatform.desktop) {
    return;
  }
  try {
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
        await _applyMacAppearance(brightness);
      case _:
        await windowManager.setBackgroundColor(
          AppColors.of(
            themeColor: AppThemeColor.burgundy,
            brightness: brightness,
          ).surfaceElevated,
        );
    }
  } catch (_) {
    // 原生外观更新失败不影响应用内主题切换。
  }
}

Future<void> _applyMacAppearance(Brightness brightness) async {
  try {
    await _windowAppearanceChannel.invokeMethod<void>(
      'setAppearance',
      <String, Object?>{'dark': brightness == Brightness.dark},
    );
  } catch (_) {
    // 旧版本原生侧没有该通道时保持系统外观。
  }
}

class _PersistedWindowState {
  const _PersistedWindowState({required this.size, required this.maximized});
  final Size size;
  final bool maximized;
}

Future<AppearanceSettings> _readPersistedAppearance() async {
  try {
    final preferences = await SharedPreferences.getInstance();
    return SharedPreferencesAppearanceStore(preferences).read();
  } catch (_) {
    return AppearanceSettings.defaults;
  }
}

Future<_PersistedWindowState> _readPersistedWindowState() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final width = prefs.getDouble(_prefsWidthKey);
    final height = prefs.getDouble(_prefsHeightKey);
    final maximized = prefs.getBool(_prefsMaximizedKey) ?? false;
    if (width == null || height == null) {
      return _PersistedWindowState(
        size: _defaultWindowSize,
        maximized: maximized,
      );
    }
    return _PersistedWindowState(
      size: Size(
        width.clamp(_minimumWindowSize.width, 10000),
        height.clamp(_minimumWindowSize.height, 10000),
      ),
      maximized: maximized,
    );
  } catch (_) {
    return const _PersistedWindowState(
      size: _defaultWindowSize,
      maximized: false,
    );
  }
}

class _DesktopWindowStatePersistor extends WindowListener {
  @override
  Future<void> onWindowResized() async {
    // 应用内全屏是自己把窗口铺满显示器，不是用户想要的窗口尺寸：别把整屏
    // 矩形写进 prefs（退出时的还原本也不需要写，prefs 里已有进入前的值）。
    if (desktopWindowFullscreenActive.value) return;
    if (await windowManager.isMaximized()) return;
    final size = await windowManager.getSize();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefsWidthKey, size.width);
      await prefs.setDouble(_prefsHeightKey, size.height);
    } catch (_) {
      // 持久化失败不影响窗口运行,忽略
    }
  }

  @override
  Future<void> onWindowMaximize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsMaximizedKey, true);
    } catch (_) {
      // 忽略
    }
  }

  @override
  Future<void> onWindowUnmaximize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsMaximizedKey, false);
    } catch (_) {
      // 忽略
    }
  }
}
