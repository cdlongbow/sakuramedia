import 'package:flutter_riverpod/legacy.dart';
import 'package:sakuramedia/features/videos/presentation/controllers/notifiers/video_mutation_change_notifier.dart';

/// videos 域跨页变更广播源（原生 Riverpod 装配，非过渡桥）。
///
/// [VideoMutationChangeNotifier] 的 report/listen 全部在 videos 域内部，
/// 无需像 movies 的订阅广播那样建 override 桥——本 provider 即唯一实例来源。
/// 消费方 `ref.read(...)` 拿实例后仍走 addListener（只换注入通道，不重构内核）。
final videoMutationBroadcasterProvider =
    ChangeNotifierProvider<VideoMutationChangeNotifier>((ref) {
      return VideoMutationChangeNotifier();
    });
