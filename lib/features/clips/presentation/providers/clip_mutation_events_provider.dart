import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/clips/presentation/controllers/clip_mutation_change_notifier.dart';

part 'clip_mutation_events_provider.g.dart';

/// 切片跨页变更广播源（legacy [ClipMutationChangeNotifier]）的桥。
///
/// 与 `movieSubscriptionBroadcasterProvider` 同一范式：过渡期 Provider 侧与
/// Riverpod 侧共用**同一个**实例，保持「单一广播源」（clips / clip_collections /
/// movies 三域的 report 方与 listen 方彼此可见）。实例由组合根 override 注入。
@Riverpod(keepAlive: true)
ClipMutationChangeNotifier clipMutationBroadcaster(Ref ref) {
  throw UnimplementedError(
    'Override clipMutationBroadcasterProvider at the app root',
  );
}

/// 切片变更事件流：把 `notifyListeners` 翻译成一条条 [ClipMutationChange]。
///
/// 消费方 `ref.listen(clipMutationEventsProvider, ...)` 后做就地补丁
/// （删除→移出网格；合集成员变化→重拉合集列表），不 invalidate 整页重拉。
@Riverpod(keepAlive: true)
Stream<ClipMutationChange> clipMutationEvents(Ref ref) {
  final notifier = ref.watch(clipMutationBroadcasterProvider);
  final controller = StreamController<ClipMutationChange>();
  void onChanged() {
    final change = notifier.lastChange;
    if (change != null) {
      controller.add(change);
    }
  }

  notifier.addListener(onChanged);
  ref.onDispose(() {
    notifier.removeListener(onChanged);
    unawaited(controller.close());
  });
  return controller.stream;
}
