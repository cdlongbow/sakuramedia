import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// 页面级 hook：把「滚到底触发下一页」的样板收敛到一处。
///
/// - [onReachBottom]：接近底部时调用。每次 rebuild 会更新到最新闭包，`useEffect`
///   不会因为闭包 identity 变化而反复重绑。
/// - [external]：若页面已有 ScrollController（例如 `AppPageFrame` 传入的），传它复用；
///   否则内部创建一个（`useScrollController`）并在 dispose 时销毁。
/// - [triggerOffset]：距 `maxScrollExtent` 多少像素时开始触发（默认 400，与
///   `PagedLoadController` 常用值一致）。
/// - [enabled]：false 时不绑 listener（例如 tab 页非活跃时避免误触发 loadMore）。
/// - [keys]：额外依赖列表——变化会重新绑定 listener（例如切 tab 后想切换目标）。
///
/// 除滚动监听外，每次构建后还会在布局完成时补查一次视口：内容不足一屏时
/// `maxScrollExtent == 0`，滚动事件永远不会发生，只靠 listener 会漏掉分页。
/// 补查严格限于「没占满屏幕」，不影响接近底部的现有触发语义。
ScrollController usePagedLoadMoreScroll({
  required VoidCallback onReachBottom,
  ScrollController? external,
  double triggerOffset = 400,
  bool enabled = true,
  List<Object?> keys = const <Object?>[],
}) {
  final internal = useScrollController();
  final controller = external ?? internal;

  final callback = useRef<VoidCallback>(onReachBottom);
  callback.value = onReachBottom;

  // 每次构建调度一次（回调是 one-shot，开销可忽略）：数据到达、翻页追加和
  // 刷新替换都会重建，因而都能覆盖；[loadMore] 自身会对重复触发短路。
  if (enabled) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.hasClients) {
        return;
      }
      if (controller.position.maxScrollExtent <= 0) {
        callback.value();
      }
    });
  }

  useEffect(() {
    if (!enabled) {
      return null;
    }
    void listener() {
      if (!controller.hasClients) return;
      final position = controller.position;
      if (position.pixels >= position.maxScrollExtent - triggerOffset) {
        callback.value();
      }
    }

    controller.addListener(listener);
    return () => controller.removeListener(listener);
  }, <Object?>[controller, triggerOffset, enabled, ...keys]);

  return controller;
}
