import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/clips/presentation/controllers/clip_mutation_change_notifier.dart';
import 'package:sakuramedia/features/shared/presentation/providers/broadcast_events_factory.dart';

part 'clip_mutation_events_provider.g.dart';

/// 切片跨页变更广播源（legacy [ClipMutationChangeNotifier]）的桥。
///
/// 与 `movieSubscriptionBroadcasterProvider` 同一范式：clips / clip_collections /
/// movies 三域的 report 方与 listen 方共用**同一个**实例，保持「单一广播源」。
/// 原生装配，组合根不再 override。
@Riverpod(keepAlive: true)
ClipMutationChangeNotifier clipMutationBroadcaster(Ref ref) {
  final notifier = ClipMutationChangeNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
}

/// 切片变更事件流：把 `notifyListeners` 翻译成一条条 [ClipMutationChange]。
///
/// 消费方 `ref.listen(clipMutationEventsProvider, ...)` 后做就地补丁
/// （删除→移出网格；合集成员变化→重拉合集列表），不 invalidate 整页重拉。
@Riverpod(keepAlive: true)
Stream<ClipMutationChange> clipMutationEvents(Ref ref) =>
    createBroadcastEventStream(
      ref: ref,
      resolveNotifier: (r) => r.watch(clipMutationBroadcasterProvider),
      drain: (n, emit) {
        final c = n.lastChange;
        if (c != null) {
          emit(c);
        }
      },
    );
