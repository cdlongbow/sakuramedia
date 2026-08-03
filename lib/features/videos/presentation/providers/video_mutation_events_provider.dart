import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/shared/presentation/providers/broadcast_events_factory.dart';
import 'package:sakuramedia/features/videos/presentation/controllers/notifiers/video_mutation_change_notifier.dart';
import 'package:sakuramedia/features/videos/presentation/providers/video_mutation_broadcaster_provider.dart';

part 'video_mutation_events_provider.g.dart';

/// videos 域跨页变更事件流：把 [VideoMutationChangeNotifier] 的
/// `notifyListeners` 翻译成一条条 [VideoMutationChange]（消费方
/// `ref.listen(videoMutationEventsProvider, ...)` 后读快照做就地补丁，
/// 不 invalidate 整页重拉）。
@Riverpod(keepAlive: true)
Stream<VideoMutationChange> videoMutationEvents(Ref ref) =>
    createBroadcastEventStream(
      ref: ref,
      resolveNotifier: (r) => r.watch(videoMutationBroadcasterProvider),
      drain: (n, emit) {
        final c = n.lastChange;
        if (c != null) {
          emit(c);
        }
      },
    );
