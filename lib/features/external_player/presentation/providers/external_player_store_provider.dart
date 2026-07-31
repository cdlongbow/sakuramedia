import 'package:flutter_riverpod/legacy.dart';
import 'package:sakuramedia/features/external_player/data/external_player_store.dart';

/// 全局外部播放器偏好的唯一实例（原生 Riverpod 装配，非过渡桥）。
///
/// [ExternalPlayerStore] 仍是 ChangeNotifier（迁移只换注入通道，不重构内核），
/// 用 legacy [ChangeNotifierProvider] 承载：`ref.watch` 会在 notifyListeners
/// 时重建，语义与旧 `context.watch<ExternalPlayerStore>()` 一致。
/// keepAlive（默认非 autoDispose）对应旧 MultiProvider 的「永不释放」。
///
/// 创建即触发 `load()`（与旧组合根 `ExternalPlayerStore()..load()` 一致）；
/// dispose 由 ChangeNotifierProvider 自动配对。
final externalPlayerStoreProvider = ChangeNotifierProvider<ExternalPlayerStore>(
  (ref) {
    return ExternalPlayerStore()..load();
  },
);
