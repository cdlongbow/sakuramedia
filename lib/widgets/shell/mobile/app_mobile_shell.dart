import 'package:animate_do/animate_do.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sakuramedia/core/platform/haptic_feedback.dart';
import 'package:sakuramedia/routes/app_route_spec.dart';
import 'package:sakuramedia/theme.dart';

/// 切换 tab 时选中 icon 的「先缩小再放大」时长。
///
/// `Pulse(from: 1.0, to: 0.6)` 的序列是 `1.0 → 0.6 → 1.0`，透明度不变。
const Duration _kNavIconPulseDuration = Duration(milliseconds: 480);

class AppMobileShell extends StatefulWidget {
  const AppMobileShell({
    super.key,
    required this.currentPath,
    required this.navGroups,
    this.currentIndex,
    this.onDestinationSelected = _noopDestinationSelected,
    this.drawer,
    this.drawerEnableOpenDragGesture = false,
    required this.child,
  });

  final String currentPath;
  final List<AppNavGroup> navGroups;
  final int? currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget? drawer;
  final bool drawerEnableOpenDragGesture;
  final Widget child;

  static void _noopDestinationSelected(int _) {}

  @override
  State<AppMobileShell> createState() => _AppMobileShellState();
}

class _AppMobileShellState extends State<AppMobileShell> {
  /// 上一次构建时的选中下标。
  ///
  /// 只在「下标发生变化的那一帧」给新选中项播放 icon 动效：首次构建时为
  /// null，所有 icon 都静态，避免 App 启动时当前 tab 无端弹一下。
  int? _previousIndex;

  @override
  Widget build(BuildContext context) {
    final navItems = widget.navGroups
        .expand((group) => group.items)
        .toList(growable: false);
    final resolvedCurrentIndex =
        widget.currentIndex ??
        _resolveCurrentIndex(widget.currentPath, navItems);
    final animateIndex =
        _previousIndex != null && _previousIndex != resolvedCurrentIndex
        ? resolvedCurrentIndex
        : null;
    final animateNavIcons = !MediaQuery.disableAnimationsOf(context);

    final shell = AnnotatedRegion<SystemUiOverlayStyle>(
      value: _mobileSystemOverlayStyle(context),
      child: Scaffold(
        backgroundColor: context.appColors.surfaceCard,
        drawer: widget.drawer,
        drawerEnableOpenDragGesture:
            widget.drawer != null && widget.drawerEnableOpenDragGesture,
        drawerEdgeDragWidth: _resolveDrawerEdgeDragWidth(context),
        body: SafeArea(
          key: const Key('mobile-shell-body-safe-area'),
          bottom: false,
          child: Padding(
            key: const Key('mobile-shell-body-padding'),
            padding: AppPageInsets.compactStandard,
            child: widget.child,
          ),
        ),
        bottomNavigationBar: SafeArea(
          key: const Key('mobile-shell-bottom-safe-area'),
          top: false,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.appColors.divider)),
            ),
            child: CupertinoTabBar(
              key: const Key('mobile-bottom-navigation'),
              height: context.appComponentTokens.mobileBottomNavHeight,
              iconSize: context.appComponentTokens.iconSizeXl,
              backgroundColor: context.appColors.surfaceCard,
              activeColor: Theme.of(context).colorScheme.primary,
              inactiveColor: context.appTextPalette.secondary,
              currentIndex: resolvedCurrentIndex,
              items: navItems
                  .asMap()
                  .entries
                  .map(
                    (entry) => BottomNavigationBarItem(
                      icon: Icon(entry.value.icon),
                      activeIcon: _buildActiveIcon(
                        entry.value.activeIcon ?? entry.value.icon,
                        animate:
                            animateNavIcons && animateIndex == entry.key,
                      ),
                      label: entry.value.label,
                    ),
                  )
                  .toList(growable: false),
              onTap: (index) => _handleDestinationTap(
                context,
                navItems,
                resolvedCurrentIndex,
                index,
              ),
            ),
          ),
        ),
      ),
    );

    _previousIndex = resolvedCurrentIndex;
    return shell;
  }

  Widget _buildActiveIcon(IconData icon, {required bool animate}) {
    if (!animate) {
      return Icon(icon);
    }
    return Pulse(
      key: const Key('mobile-nav-active-icon-pulse'),
      from: 1.0,
      to: 0.6,
      duration: _kNavIconPulseDuration,
      curve: Curves.easeOut,
      child: Icon(icon),
    );
  }

  /// 左边缘拖拽区宽度。
  ///
  /// Flutter 默认是 `20 + padding.left`,而 Android 手势导航的返回手势区就压在
  /// 最外侧同一条带子上、且系统优先消费,默认值等于整条被吃掉。系统手势区宽度
  /// 因设备/ROM 而异(只在 Android Q+ 非零),运行时从 MediaQuery 读,再往内侧
  /// 补一段 app 独占的可用带——外侧归系统返回,内侧归抽屉。
  double? _resolveDrawerEdgeDragWidth(BuildContext context) {
    if (widget.drawer == null || !widget.drawerEnableOpenDragGesture) {
      return null;
    }
    return MediaQuery.systemGestureInsetsOf(context).left +
        context.appSpacing.xl;
  }

  void _handleDestinationTap(
    BuildContext context,
    List<AppNavItem> navItems,
    int currentIndex,
    int index,
  ) {
    // 只在真正切换 tab 时给触感，重复点当前 tab 不震。
    if (index != currentIndex) {
      triggerSelectionHaptic();
    }
    if (widget.onDestinationSelected !=
        AppMobileShell._noopDestinationSelected) {
      widget.onDestinationSelected(index);
      return;
    }
    // 在未接入 StatefulShellRoute 的场景下，回退到传统的 go 导航。
    final router = GoRouter.maybeOf(context);
    if (router == null || index < 0 || index >= navItems.length) {
      return;
    }
    router.go(navItems[index].path);
  }

  int _resolveCurrentIndex(String path, List<AppNavItem> navItems) {
    for (var index = 0; index < navItems.length; index += 1) {
      final item = navItems[index];
      if (path == item.path || path.startsWith('${item.path}/')) {
        return index;
      }
    }
    return 0;
  }

  SystemUiOverlayStyle _mobileSystemOverlayStyle(BuildContext context) {
    return SystemUiOverlayStyle(
      statusBarColor: context.appColors.surfaceCard,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: context.appColors.surfaceCard,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: context.appColors.divider,
    );
  }
}
