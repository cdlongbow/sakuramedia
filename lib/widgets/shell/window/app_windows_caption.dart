import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/theme.dart';
import 'package:window_manager/window_manager.dart';

bool get usesAppWindowsCaption =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

/// Reuses the native-style controls and maximize-state listener from window_manager.
class AppWindowsCaption extends StatelessWidget {
  const AppWindowsCaption({
    super.key,
    this.standalone = false,
    this.overlay = false,
  });

  final bool standalone;

  /// 顶栏悬浮在封面之上（沉浸式详情页）时置真。
  ///
  /// 此时顶栏只有一层半透明暗色渐变、没有实心底；标题栏必须透出同一层底色，
  /// 否则右上角三个窗口按钮会糊成一块与周围割裂的纯色卡片。
  final bool overlay;

  @override
  Widget build(BuildContext context) {
    final height = context.appComponentTokens.desktopTitleBarHeight;
    return SizedBox(
      height: height,
      width: standalone ? null : height * 3,
      child: WindowCaption(
        // 沉浸顶栏的底衬恒为深色渐变（见 AppTopBar），按钮必须走深色配套的
        // 白色图标；否则浅色主题下黑色图标会压在深色封面/渐变上看不见。
        brightness: overlay ? Brightness.dark : Theme.of(context).brightness,
        backgroundColor: overlay
            ? Colors.transparent
            : context.appColors.surfaceElevated,
        title: standalone
            ? Text(
                'SakuraMedia',
                style: resolveAppTextStyle(context, size: AppTextSize.s14),
              )
            : null,
      ),
    );
  }
}
