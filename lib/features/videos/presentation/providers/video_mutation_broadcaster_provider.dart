import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/videos/presentation/controllers/notifiers/video_mutation_change_notifier.dart';

part 'video_mutation_broadcaster_provider.g.dart';

/// videos 域跨页变更广播源（legacy [VideoMutationChangeNotifier] 桥）。
///
/// 与 clips 的 `clipMutationBroadcasterProvider` 同构：clip / video / movie
/// 三域广播源现在都用 `@Riverpod(keepAlive: true)` 原生装配（本文件是最后一个
/// 从 legacy `ChangeNotifierProvider` 迁过来的样板，也是压轴批 8「三大广播源
/// 本体 Notifier 化」的探路：先把 broadcaster provider 装配统一，本体真正
/// Notifier 化留批 8）。
///
/// 消费方 `ref.read(...)` 拿实例后仍走 addListener（未收敛的消费点）或
/// `ref.listen(videoMutationEventsProvider, ...)`（已单轨化的消费点）。
@Riverpod(keepAlive: true)
VideoMutationChangeNotifier videoMutationBroadcaster(Ref ref) {
  final notifier = VideoMutationChangeNotifier();
  ref.onDispose(notifier.dispose);
  return notifier;
}
