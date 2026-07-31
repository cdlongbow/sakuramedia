import 'package:flutter/foundation.dart';

/// 移动端首页(概览)当前 tab 序号,供上层壳读取。
///
/// 存在的唯一理由:壳层要决定「要不要放开左边缘侧滑打开抽屉」,而这个决定依赖
/// 首页停在哪个 tab——`Scaffold` 的边缘拖拽区在 Stack 顶层,拖拽区覆盖多宽,
/// 下面的 `TabBarView` 就有多宽收不到手势。只有停在第一个 tab 时右滑本就无处
/// 可去(已到头),让给抽屉才不会剥夺「右滑切回上一个 tab」。
///
/// 首页在路由树里被壳包着,拿不到向上的通道,因此走这个 notifier 上报。
///
/// **作用域是移动壳子树,不是 app 全局**:由 `mobileOverviewTabIndexProvider`
/// (autoDispose)承载——壳与首页 reporter `ref.watch` 时创建,双方都不在时
/// 自动释放,随壳挂载/销毁的生命周期语义与旧局部 provider 一致。因此壳侧与
/// 首页侧都可以按「必然存在」直接 `watch` / `read`,不需要可选兜底。
class MobileOverviewTabIndexNotifier extends ValueNotifier<int> {
  MobileOverviewTabIndexNotifier() : super(0);
}
