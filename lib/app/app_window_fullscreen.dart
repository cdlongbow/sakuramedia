import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

/// 桌面窗口是否已进入「应用内全屏」的系统窗口态（应用内布局切换之外的另一半）。
///
/// Windows 上的全屏是我们自己把窗口铺满当前显示器（见
/// [applyDesktopWindowFullscreen]），window_manager 并不知道，所以这里广播
/// 出去，给窗口外壳用来关掉拖拽窗口边缘改尺寸的热区。
final ValueNotifier<bool> desktopWindowFullscreenActive = ValueNotifier<bool>(
  false,
);

/// 解析整屏矩形；拿不到时返回 null。
typedef DesktopMonitorRectResolver = Future<Rect?> Function();

/// 测试注入点：替换 [resolveDesktopMonitorRect] 的默认实现，避免依赖
/// screen_retriever 的 method channel 与 dart:ui 的 Display。
@visibleForTesting
DesktopMonitorRectResolver? debugDesktopMonitorRectResolver;

/// 进全屏前的窗口态，退出时按它还原。
class _PreFullscreenWindowState {
  const _PreFullscreenWindowState({
    required this.bounds,
    required this.maximized,
    required this.alwaysOnTop,
  });

  final Rect bounds;
  final bool maximized;
  final bool alwaysOnTop;
}

_PreFullscreenWindowState? _preFullscreenWindowState;

/// 切换代际：每次调用自增，最后一次调用赢。
///
/// 进全屏要跨多个 await（读最大化态 / 读 bounds / 铺满显示器），调用方
/// （播放器全屏按钮、Esc、页面 dispose）都是 fire-and-forget，快速双击、
/// 退出后再进、进全屏后立刻离开页面都可能让两次切换交错。旧代际在每个
/// await 之后发现已有更新意图就放弃后续原生调用与状态写入，否则「进入」
/// 的迟到落地会盖掉已经生效的「退出」，把窗口留在整屏尺寸。
int _fullscreenTransitionToken = 0;

/// 切换桌面窗口的系统全屏，供播放器「应用内全屏」调用。
///
/// - macOS：直接走 window_manager 的 `setFullScreen`。
/// - Windows：窗口是无边框的（启动时调过 `setAsFrameless()`），而
///   window_manager 的 `setFullScreen` 对无边框窗口是空操作，所以这里自己把
///   窗口 bounds 设成当前显示器的整屏矩形，并临时把窗口置顶：任务栏自身是
///   topmost 窗口，无边框窗口即使铺满整屏也会被它压在下面。退出时还原原来的
///   置顶状态。
/// - 移动端 / 测试环境：没有窗口插件，异常吞掉，调用方只关心应用内布局态。
Future<void> applyDesktopWindowFullscreen(bool enabled) async {
  if (kIsWeb) {
    return;
  }
  final platform = defaultTargetPlatform;
  final isWindows = platform == TargetPlatform.windows;
  if (!isWindows && platform != TargetPlatform.macOS) {
    return;
  }
  if (!isWindows) {
    try {
      await windowManager.setFullScreen(enabled);
    } catch (_) {
      // 测试环境没有窗口插件：忽略，应用内布局态照常切换。
    }
    return;
  }

  final token = ++_fullscreenTransitionToken;
  if (enabled) {
    // 先关掉 resize 热区，避免铺满屏幕的瞬间还能从屏幕边缘拖窗口。
    desktopWindowFullscreenActive.value = true;
    _PreFullscreenWindowState? captured;
    try {
      final maximized = await windowManager.isMaximized();
      if (token != _fullscreenTransitionToken) return;
      final bounds = await windowManager.getBounds();
      if (token != _fullscreenTransitionToken) return;
      final alwaysOnTop = await windowManager.isAlwaysOnTop();
      if (token != _fullscreenTransitionToken) return;
      captured = _PreFullscreenWindowState(
        bounds: bounds,
        maximized: maximized,
        alwaysOnTop: alwaysOnTop,
      );
      _preFullscreenWindowState = captured;
      if (maximized) {
        await windowManager.unmaximize();
        if (token != _fullscreenTransitionToken) return;
      }
      final rect = await resolveDesktopMonitorRect();
      if (token != _fullscreenTransitionToken) return;
      if (rect == null) {
        // 拿不到整屏矩形时退回最大化：至少铺满工作区。
        await windowManager.maximize();
      } else {
        await windowManager.setBounds(rect);
      }
      if (token != _fullscreenTransitionToken) return;
      // 任务栏是 topmost 窗口，铺满整屏仍会被它压住：临时置顶盖过它。
      await windowManager.setAlwaysOnTop(true);
    } catch (_) {
      if (token != _fullscreenTransitionToken) {
        // 已有更新意图：窗口态交给它，不用旧快照把窗口拽回去。
        return;
      }
      // 原生调用失败：把窗口态还回去，应用内布局态照常切换。
      desktopWindowFullscreenActive.value = false;
      if (captured == null) {
        // 连窗口态都没读到，窗口没被改过：清掉旧快照，避免之后的退出
        // 按上一次全屏的矩形把窗口挪走。
        _preFullscreenWindowState = null;
      } else {
        await _restoreWindowStateQuietly(captured, token: token);
        if (token == _fullscreenTransitionToken) {
          // 已经还原过了：快照用完即弃，之后的退出不该再按它动窗口。
          // 还原期间若有更新意图，快照可能已属于它，不能替它清掉。
          _preFullscreenWindowState = null;
        }
      }
    }
    return;
  }
  try {
    await _restoreWindowStateQuietly(_preFullscreenWindowState, token: token);
    if (token == _fullscreenTransitionToken) {
      _preFullscreenWindowState = null;
    }
  } finally {
    if (token == _fullscreenTransitionToken) {
      desktopWindowFullscreenActive.value = false;
    }
  }
}

Future<void> _restoreWindowStateQuietly(
  _PreFullscreenWindowState? state, {
  required int token,
}) async {
  if (state == null) {
    return;
  }
  if (token == _fullscreenTransitionToken) {
    try {
      if (state.maximized) {
        await windowManager.maximize();
      } else {
        await windowManager.setBounds(state.bounds);
      }
    } catch (_) {
      // 没有窗口插件 / 还原失败：忽略，应用内布局态照常切换。
    }
  }
  if (token == _fullscreenTransitionToken) {
    try {
      // 置顶单独还原：窗口矩形还原失败也不能把窗口留在 topmost。
      await windowManager.setAlwaysOnTop(state.alwaysOnTop);
    } catch (_) {
      // 同上。
    }
  }
}

/// 当前窗口所在显示器的整屏矩形（逻辑像素），拿不到返回 null。
Future<Rect?> resolveDesktopMonitorRect() async {
  final override = debugDesktopMonitorRectResolver;
  if (override != null) {
    return override();
  }
  try {
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view == null) {
      return null;
    }
    // dart:ui 报的是当前视图所在显示器的物理尺寸，除以 DPR 得逻辑尺寸；
    // 这是唯一能拿到「含任务栏的整屏高度」的来源。
    final displaySize = view.display.size / view.display.devicePixelRatio;
    final center = (await windowManager.getBounds()).center;
    final primary = await screenRetriever.getPrimaryDisplay();
    final displays = await screenRetriever.getAllDisplays();
    final current = displays.firstWhere(
      (display) => desktopWorkArea(display).contains(center),
      orElse: () => primary,
    );
    return desktopMonitorRectFor(
      displaySize: displaySize,
      primary: primary,
      current: current,
    );
  } catch (_) {
    return null;
  }
}

/// 显示器的可用区（不含任务栏），逻辑像素。
@visibleForTesting
Rect desktopWorkArea(Display display) {
  final position = display.visiblePosition ?? Offset.zero;
  final size = display.visibleSize ?? display.size;
  return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
}

/// 整屏矩形：尺寸用 [displaySize]（含任务栏），原点按「主屏恒为 (0,0)、
/// 其它屏取工作区原点」推断——screen_retriever 只给工作区原点，任务栏在
/// 副屏顶部/左侧时会差一个任务栏厚度，先接受这个极端误差。
@visibleForTesting
Rect desktopMonitorRectFor({
  required Size displaySize,
  required Display primary,
  required Display current,
}) {
  final origin = desktopWorkArea(current) == desktopWorkArea(primary)
      ? Offset.zero
      : current.visiblePosition ?? Offset.zero;
  return Rect.fromLTWH(
    origin.dx,
    origin.dy,
    displaySize.width,
    displaySize.height,
  );
}
