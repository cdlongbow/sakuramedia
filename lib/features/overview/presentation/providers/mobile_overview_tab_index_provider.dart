import 'package:flutter_riverpod/legacy.dart';
import 'package:sakuramedia/features/overview/presentation/mobile_overview_tab_index_notifier.dart';

/// 移动首页当前 tab 序号（原生 Riverpod 装配，autoDispose）。
///
/// 原是 `mobile_routes.dart` 移动壳子树的局部 provider：随壳挂载而新建、
/// 随壳销毁而释放——autoDispose 保持同一生命周期（壳 `ref.watch` 决定左边
/// 缘侧滑，首页 reporter `ref.watch(...notifier)` 上报，双方都不在时释放）。
/// 刻意不 keepAlive：它是纯移动端 UI 手势状态，桌面/Web 永不创建。
final mobileOverviewTabIndexProvider =
    ChangeNotifierProvider.autoDispose<MobileOverviewTabIndexNotifier>((ref) {
      return MobileOverviewTabIndexNotifier();
    });
