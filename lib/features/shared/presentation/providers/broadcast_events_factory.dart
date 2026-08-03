import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 把 legacy `ChangeNotifier` 广播源翻译成 Riverpod 事件流的工厂。
///
/// 收敛各 events provider 的 ~30 行样板：在 [resolveNotifier] 返回的 notifier
/// 上挂一个 `notifyListeners` 监听器，[drain] 负责把「本次广播的快照」翻译成
/// 一条条事件推入流；provider dispose 时移除监听并关闭流。
///
/// 语义要点（与收敛前的逐份实现完全一致）：
/// - [drain] 消费的是 notifier 的**最新快照**（如 `lastChange` /
///   `consumePendingChanges`），多消费方并存时幂等、不会重复消费。
/// - 返回的 stream 由 keepAlive provider 持有；消费方
///   `ref.listen(xxxEventsProvider, ...)` 若没有监听者，Riverpod 会 pause
///   入站流（底层 `StreamSubscription.pause()`）——事件缓冲、恢复监听时补投，
///   不丢事件但会延迟。测试里必须给事件 provider 挂监听者。
Stream<E> createBroadcastEventStream<N extends ChangeNotifier, E>({
  required Ref ref,
  required N Function(Ref) resolveNotifier,
  required void Function(N notifier, void Function(E) emit) drain,
}) {
  final notifier = resolveNotifier(ref);
  final controller = StreamController<E>();
  void onChanged() => drain(notifier, controller.add);
  notifier.addListener(onChanged);
  ref.onDispose(() {
    notifier.removeListener(onChanged);
    unawaited(controller.close());
  });
  return controller.stream;
}
