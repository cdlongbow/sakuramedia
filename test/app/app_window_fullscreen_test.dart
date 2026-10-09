import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/app/app_window_fullscreen.dart';
import 'package:screen_retriever/screen_retriever.dart';

/// Windows 的无边框窗口用不了 window_manager 的 `setFullScreen`（它会对无边框
/// 窗口整段跳过），所以自己把窗口铺满当前显示器并临时置顶压过任务栏；这组
/// 单测锁住调用序列、还原逻辑与显示器矩形的推断规则。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('window_manager');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final previousPlatformOverride = debugDefaultTargetPlatformOverride;
  final calls = <MethodCall>[];
  var maximized = false;
  var alwaysOnTop = false;
  var windowBounds = const Rect.fromLTWH(100, 120, 1280, 720);

  Map<String, double> boundsPayload(Rect rect) => <String, double>{
    'x': rect.left,
    'y': rect.top,
    'width': rect.width,
    'height': rect.height,
  };

  // 可控闸门：让某次原生调用悬挂，制造两次切换交错的时序。
  Completer<void>? isMaximizedGate;
  Completer<void>? setBoundsGate;

  void mockWindowManager({bool failSetBounds = false}) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'isMaximized':
          final gate = isMaximizedGate;
          if (gate != null) {
            await gate.future;
          }
          return maximized;
        case 'getBounds':
          return boundsPayload(windowBounds);
        case 'isAlwaysOnTop':
          return alwaysOnTop;
        case 'setAlwaysOnTop':
          final args = call.arguments as Map<Object?, Object?>;
          alwaysOnTop = args['isAlwaysOnTop']! as bool;
          return null;
        case 'setBounds':
          final gate = setBoundsGate;
          if (gate != null) {
            await gate.future;
          }
          if (failSetBounds) {
            throw PlatformException(code: 'set_bounds_failed');
          }
          // 像真实窗口那样记住最新 bounds，之后 getBounds 读到的是它。
          final args = call.arguments as Map<Object?, Object?>;
          windowBounds = Rect.fromLTWH(
            args['x']! as double,
            args['y']! as double,
            args['width']! as double,
            args['height']! as double,
          );
          return null;
        default:
          return null;
      }
    });
  }

  setUp(() async {
    isMaximizedGate = null;
    setBoundsGate = null;
    mockWindowManager();
    // 上一用例可能把窗口留在「应用内全屏」（快照是模块私有状态，没法直接
    // 重置）：先驱动一次退出把窗口态归零，用例之间才不会互相污染。
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await applyDesktopWindowFullscreen(false);
    calls.clear();
    maximized = false;
    alwaysOnTop = false;
    windowBounds = const Rect.fromLTWH(100, 120, 1280, 720);
    desktopWindowFullscreenActive.value = false;
    debugDesktopMonitorRectResolver = () async =>
        const Rect.fromLTWH(0, 0, 1920, 1080);
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = previousPlatformOverride;
    debugDesktopMonitorRectResolver = null;
    desktopWindowFullscreenActive.value = false;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('windows fills the monitor bounds and restores them on exit', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    await applyDesktopWindowFullscreen(true);

    expect(desktopWindowFullscreenActive.value, isTrue);
    expect(calls.map((call) => call.method), <String>[
      'isMaximized',
      'getBounds',
      'isAlwaysOnTop',
      'setBounds',
      'setAlwaysOnTop',
    ]);
    final fullscreenArgs = calls[3].arguments as Map<Object?, Object?>;
    expect(fullscreenArgs['x'], 0.0);
    expect(fullscreenArgs['y'], 0.0);
    expect(fullscreenArgs['width'], 1920.0);
    expect(fullscreenArgs['height'], 1080.0);
    // 任务栏是 topmost 窗口，必须临时置顶才盖得住。
    expect(alwaysOnTop, isTrue);

    calls.clear();
    await applyDesktopWindowFullscreen(false);

    expect(desktopWindowFullscreenActive.value, isFalse);
    expect(calls.map((call) => call.method), <String>[
      'setBounds',
      'setAlwaysOnTop',
    ]);
    final restoreArgs = calls.first.arguments as Map<Object?, Object?>;
    expect(restoreArgs['x'], 100.0);
    expect(restoreArgs['y'], 120.0);
    expect(restoreArgs['width'], 1280.0);
    expect(restoreArgs['height'], 720.0);
    expect(alwaysOnTop, isFalse);
  });

  test('windows goes back to maximized after fullscreen', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    maximized = true;

    await applyDesktopWindowFullscreen(true);

    expect(calls.map((call) => call.method), <String>[
      'isMaximized',
      'getBounds',
      'isAlwaysOnTop',
      'unmaximize',
      'setBounds',
      'setAlwaysOnTop',
    ]);

    calls.clear();
    await applyDesktopWindowFullscreen(false);

    expect(calls.map((call) => call.method), <String>[
      'maximize',
      'setAlwaysOnTop',
    ]);
    expect(alwaysOnTop, isFalse);
  });

  test('falls back to maximize when no monitor rect is available', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    debugDesktopMonitorRectResolver = () async => null;

    await applyDesktopWindowFullscreen(true);

    expect(calls.map((call) => call.method), <String>[
      'isMaximized',
      'getBounds',
      'isAlwaysOnTop',
      'maximize',
      'setAlwaysOnTop',
    ]);
    expect(desktopWindowFullscreenActive.value, isTrue);
    // 拿不到整屏矩形时只铺工作区，但依然要压过任务栏。
    expect(alwaysOnTop, isTrue);
  });

  test('restores the window when setting the bounds fails', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    mockWindowManager(failSetBounds: true);

    await applyDesktopWindowFullscreen(true);

    expect(desktopWindowFullscreenActive.value, isFalse);
    // 进全屏失败后尽力还原：两次 setBounds（一次进全屏、一次还原）。
    expect(
      calls.map((call) => call.method).where((name) => name == 'setBounds'),
      hasLength(2),
    );
    // 失败路径同样要把置顶还回去。
    expect(alwaysOnTop, isFalse);
  });

  test('a newer exit aborts an in-flight fullscreen entry', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    isMaximizedGate = Completer<void>();

    final entering = applyDesktopWindowFullscreen(true);
    await Future<void>.delayed(Duration.zero);
    final exiting = applyDesktopWindowFullscreen(false);
    isMaximizedGate!.complete();
    await Future.wait<void>(<Future<void>>[entering, exiting]);

    // 「退出」是最新意图：迟迟未落地的进入不得再把窗口铺满显示器。
    expect(desktopWindowFullscreenActive.value, isFalse);
    expect(calls.map((call) => call.method), <String>['isMaximized']);
    expect(alwaysOnTop, isFalse);

    // 窗口快照没被污染：之后的完整循环仍能还原到最初的窗口尺寸与置顶状态。
    isMaximizedGate = null;
    calls.clear();
    await applyDesktopWindowFullscreen(true);
    await applyDesktopWindowFullscreen(false);

    final restoreCall = calls.lastWhere((call) => call.method == 'setBounds');
    final restoreArgs = restoreCall.arguments as Map<Object?, Object?>;
    expect(restoreArgs['x'], 100.0);
    expect(restoreArgs['y'], 120.0);
    expect(restoreArgs['width'], 1280.0);
    expect(restoreArgs['height'], 720.0);
    expect(windowBounds, const Rect.fromLTWH(100, 120, 1280, 720));
    expect(alwaysOnTop, isFalse);
  });

  test('a newer entry survives an in-flight exit', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    // 先正常进一次全屏，留下可还原的窗口态。
    await applyDesktopWindowFullscreen(true);
    expect(desktopWindowFullscreenActive.value, isTrue);
    expect(windowBounds, const Rect.fromLTWH(0, 0, 1920, 1080));
    expect(alwaysOnTop, isTrue);

    // 退出挂在「还原窗口矩形」这一步，退出还没落地时又要进全屏。
    calls.clear();
    setBoundsGate = Completer<void>();
    final exiting = applyDesktopWindowFullscreen(false);
    final entering = applyDesktopWindowFullscreen(true);
    await Future<void>.delayed(Duration.zero);
    setBoundsGate!.complete();
    await Future.wait<void>(<Future<void>>[exiting, entering]);

    // 最后一次意图是「进入」：窗口留在整屏，旧退出的收尾不得把它翻回 false。
    expect(calls.map((call) => call.method), <String>[
      'setBounds',
      'isMaximized',
      'getBounds',
      'isAlwaysOnTop',
      'setBounds',
      'setAlwaysOnTop',
    ]);
    expect(desktopWindowFullscreenActive.value, isTrue);
    expect(windowBounds, const Rect.fromLTWH(0, 0, 1920, 1080));
    expect(alwaysOnTop, isTrue);

    setBoundsGate = null;
    await applyDesktopWindowFullscreen(false);
    expect(desktopWindowFullscreenActive.value, isFalse);
    // 这里只锁「最后意图赢」这一条：本用例人为把旧退出的还原悬挂在半路，
    // 真实平台上原生调用先来先服务，新进入不会读到还没落地的中间窗口态，
    // 几何与置顶的还原断言见前面的顺序用例。
  });

  test('macOS keeps window_manager fullscreen', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    await applyDesktopWindowFullscreen(true);

    expect(calls.map((call) => call.method), <String>['setFullScreen']);
    expect(calls.single.arguments, <String, Object?>{'isFullScreen': true});
  });

  test('mobile platforms only switch the in-app layout', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await applyDesktopWindowFullscreen(true);

    expect(calls, isEmpty);
    expect(desktopWindowFullscreenActive.value, isFalse);
  });

  test(
    'monitor rect uses the primary origin and the second screen work area',
    () {
      final primary = Display(
        id: 'primary',
        size: const Size(1920, 1080),
        visiblePosition: Offset.zero,
        visibleSize: const Size(1920, 1040),
      );
      final secondary = Display(
        id: 'secondary',
        size: const Size(1920, 1080),
        visiblePosition: const Offset(1920, 0),
        visibleSize: const Size(1920, 1040),
      );

      expect(
        desktopMonitorRectFor(
          displaySize: const Size(1920, 1080),
          primary: primary,
          current: primary,
        ),
        const Rect.fromLTWH(0, 0, 1920, 1080),
      );
      expect(
        desktopMonitorRectFor(
          displaySize: const Size(1920, 1080),
          primary: primary,
          current: secondary,
        ),
        const Rect.fromLTWH(1920, 0, 1920, 1080),
      );
    },
  );
}
