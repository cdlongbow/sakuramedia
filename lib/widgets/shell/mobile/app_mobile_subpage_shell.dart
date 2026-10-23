import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/interaction/app_interactive_surface.dart';
import 'package:sakuramedia/widgets/base/layout/glass/app_glass_surface.dart';
import 'package:sakuramedia/widgets/shell/mobile/mobile_system_overlay.dart';

/// 让子页面把「真实标题」报给外层返回栏的信箱。
///
/// 路由层只知道静态标题（「合集」「播放列表详情」…），真正的名字要等页面把数据
/// 拉回来才有。页面拿到后 `AppMobileSubpageTitle.read(context)?.value = name`，
/// 返回栏立刻换成它，页面内部就不必再写一遍标题——省掉「静态标题 + 页内大标题」
/// 两层重复，也把列表往上提了一整块。
///
/// 没有报的子页保持路由传进来的静态标题，行为不变。
class AppMobileSubpageTitle extends InheritedWidget {
  const AppMobileSubpageTitle({
    super.key,
    required this.notifier,
    required super.child,
  });

  final ValueNotifier<String?> notifier;

  /// 不建立依赖关系的读取——在 `initState` / 回调里写标题时用这个，避免把页面
  /// 挂到 InheritedWidget 的重建链上。
  static ValueNotifier<String?>? read(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<AppMobileSubpageTitle>()
        ?.notifier;
  }

  @override
  bool updateShouldNotify(AppMobileSubpageTitle oldWidget) =>
      notifier != oldWidget.notifier;
}

class AppMobileSubpageShell extends StatefulWidget {
  const AppMobileSubpageShell({
    super.key,
    required this.title,
    required this.defaultLocation,
    required this.child,
    this.currentPath,
    this.bodyPadding = AppPageInsets.compactStandard,
    this.immersive = false,
  });

  final String title;
  final String defaultLocation;
  final Widget child;
  final String? currentPath;
  final EdgeInsetsGeometry bodyPadding;

  /// 沉浸详情：透明底 + 返回栏悬浮在内容之上（影片详情用）。
  final bool immersive;

  @override
  State<AppMobileSubpageShell> createState() => _AppMobileSubpageShellState();
}

class _AppMobileSubpageShellState extends State<AppMobileSubpageShell> {
  /// 子页面报上来的真实标题；为 null 时用路由给的静态标题。
  final ValueNotifier<String?> _titleOverride = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _titleOverride.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    final navigator = Navigator.maybeOf(context);
    final immersive = widget.immersive;
    final content = PopScope<void>(
      canPop: _canPop(router, navigator),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        _goToDefault(router, widget.defaultLocation);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        key: const Key('mobile-subpage-system-overlay'),
        value: immersive
            ? const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: Brightness.light,
              )
            : resolveMobileSystemOverlayStyle(context),
        child: ColoredBox(
          key: const Key('mobile-subpage-root-surface'),
          color: immersive ? Colors.transparent : context.appColors.surfaceCard,
          child: SafeArea(
            key: const Key('mobile-subpage-safe-area'),
            // 沉浸时顶边不留安全区：封面从状态栏下开始铺。
            top: !immersive,
            // 底边一律不留：内容铺到屏幕物理底边（沉浸页的封面背景因此盖住
            // home indicator 区，非沉浸页由外壳底色兜底）。底部安全区改由内容
            // 层自己留——滚动页在滚动末尾补 `MediaQuery.paddingOf().bottom`
            //（`AppAdaptiveRefreshScrollView` / `BoxScrollView` 已统一处理），
            // 贴底操作条自带 `SafeArea(top: false)`。新加子页面时别忘了这一条。
            bottom: false,
            child: Scaffold(
              backgroundColor: immersive
                  ? Colors.transparent
                  : context.appColors.surfaceCard,
              extendBodyBehindAppBar: immersive,
              appBar: AppBar(
                key: const Key('mobile-subpage-topbar'),
                backgroundColor: immersive
                    ? Colors.transparent
                    : context.appColors.surfaceCard,
                elevation: 0,
                scrolledUnderElevation: 0,
                flexibleSpace: immersive
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              context.appColors.mediaOverlayStrong.withValues(
                                alpha: 0.55,
                              ),
                              context.appColors.mediaOverlayStrong.withValues(
                                alpha: 0,
                              ),
                            ],
                          ),
                        ),
                      )
                    : null,
                leadingWidth:
                    context.appComponentTokens.mobileSubpageLeadingWidth,
                titleSpacing: 0, // 默认 16
                leading: immersive
                    ? Center(
                        child: Tooltip(
                          message: '返回',
                          child: AppInteractiveSurface(
                            key: const Key('mobile-subpage-back-button'),
                            onTap: () => _handleBack(context),
                            semanticLabel: '返回',
                            child: AppGlassSurface(
                              tone: AppGlassTone.chrome,
                              borderRadius: context.appRadius.pillBorder,
                              child: SizedBox.square(
                                dimension:
                                    context.appComponentTokens.buttonHeightSm,
                                child: Center(
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: context.appComponentTokens.iconSizeSm,
                                    color: context.appTextPalette.onMedia,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : IconButton(
                        iconSize: context.appComponentTokens.iconSizeSm,
                        key: const Key('mobile-subpage-back-button'),
                        onPressed: () => _handleBack(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        tooltip: '返回',
                      ),
                title: immersive
                    // 沉浸页不占标题位：封面直通状态栏，顶栏只留返回键和渐变。
                    ? null
                    : ValueListenableBuilder<String?>(
                        valueListenable: _titleOverride,
                        builder: (context, override, _) {
                          final resolved =
                              (override != null && override.trim().isNotEmpty)
                              ? override
                              : widget.title;
                          return Text(
                            resolved,
                            key: const Key('mobile-subpage-title'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: resolveAppTextStyle(
                              context,
                              size: AppTextSize.s14,
                              weight: AppTextWeight.medium,
                              tone: AppTextTone.primary,
                            ),
                          );
                        },
                      ),
              ),
              body: Padding(
                key: const Key('mobile-subpage-body-padding'),
                padding: widget.bodyPadding,
                child: AppMobileSubpageTitle(
                  notifier: _titleOverride,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return content;
  }

  void _handleBack(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    final navigator = Navigator.maybeOf(context);
    if (_canPop(router, navigator)) {
      if (router != null && router.canPop()) {
        router.pop();
        return;
      }
      navigator?.pop();
      return;
    }
    final activePath =
        widget.currentPath ??
        (router != null ? GoRouterState.of(context).uri.path : null);
    if (activePath != widget.defaultLocation) {
      _goToDefault(router, widget.defaultLocation);
    }
  }

  bool _canPop(GoRouter? router, NavigatorState? navigator) {
    return router?.canPop() ?? navigator?.canPop() ?? false;
  }

  void _goToDefault(GoRouter? router, String location) {
    // 子页面优先交给路由系统处理；在纯组件宿主下没有 GoRouter 时保持静默。
    router?.go(location);
  }
}
