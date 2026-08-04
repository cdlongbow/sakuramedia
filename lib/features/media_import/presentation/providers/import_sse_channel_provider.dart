import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/activity/data/activity_stream_event.dart';
import 'package:sakuramedia/features/shared/presentation/providers/sse_channel.dart';

part 'import_sse_channel_provider.g.dart';

typedef ImportSseChannelFactory =
    SseChannel<ActivityStreamEvent> Function({
      required Stream<ActivityStreamEvent> Function({String? afterEventId})
      connect,
      required Future<String?> Function() bootstrap,
    });

/// 导入双子星共用的 SSE 状态机工厂。
///
/// 工厂 provider 让 notifier 直接单测可注入 [FakeSseChannel]，生产参数固定锁定
/// `[2,5,10,30]s`、逐事件下发、bootstrap 失败退避，以及 unsupported 放弃。
@Riverpod(keepAlive: true)
ImportSseChannelFactory importSseChannelFactory(Ref ref) {
  return ({required connect, required bootstrap}) =>
      SseChannel<ActivityStreamEvent>(
        connect: connect,
        importBackoff: true,
        giveUpOnUnsupported: true,
        mergeMode: SseMergeMode.none,
        needsBootstrapBeforeStream: true,
        abandonOnBootstrapFailure: true,
        bootstrap: bootstrap,
      );
}
