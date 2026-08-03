import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;
import 'package:sakuramedia/core/session/session_store.dart';

/// 页面保活 handle：一组 [KeepAliveLink] + 引用计数。
///
/// 页面 `initState` 经 [RiverpodPageCache.obtain] 拿到 handle，`dispose` 时调
/// [release]。**不直接 close link**——link 的生命周期由 LRU 驱逐 / 登出清空
/// 决定（释放 provider 状态时由缓存统一 close）。
class RiverpodPageHandle {
  RiverpodPageHandle(this.key, this.links);

  final String key;
  final List<KeepAliveLink> links;
  int _refCount = 1;

  /// 当前引用计数：同一 key 被多次 [RiverpodPageCache.obtain] 会累加。
  int get refCount => _refCount;

  /// 页面 dispose 时调用：减引用计数。不减到 0 也**不** close link——
  /// link 的关闭只由缓存（驱逐 / 清空 / 登出）决定。
  void release() {
    if (_refCount > 0) {
      _refCount--;
    }
  }
}

/// Riverpod-aware 页面保活 LRU 缓存。
///
/// 与 [AppPageStateCache]（缓存的条目是对象本身）不同，本缓存保活的是
/// **provider 状态**：业务 provider 全部走默认 autoDispose，页面 mount 时经
/// [obtain] 收集一组 [KeepAliveLink] 挂进 LRU 表——link 未关闭期间对应
/// provider 不会被 autoDispose 释放（跨导航保留列表数据 / 滚动位置）。
///
/// - 命中同 key：MRU 重放（先 remove 再 put 到末尾），返回同一 handle。
/// - 驱逐：超 [maxEntries] 时踢掉最旧条目，对其中每个 link 调
///   [KeepAliveLink.close]——触发对应 provider 的 autoDispose、状态释放。
/// - 登出边沿（`hasSession` true→false）：全部 link close、全部清空。
///
/// ⚠️ link 的获取（batch 5 波 B 接线用）：riverpod 3.x 的 `ref.keepAlive()`
/// 只能在本 provider 的 `build` 内调用（返回该 provider 自己的
/// [KeepAliveLink]），页面侧的 `WidgetRef` 没有该 API——落地范式是业务
/// provider 在 `build` 首行 `final link = ref.keepAlive();` 并把 link 暴露给
/// 宿主（放进 State / 伴生 provider），页面再经 [obtain] 的 `resolveLinks`
/// 闭包收集。本批只提供基建 + 单测，不接业务页。
class RiverpodPageCache extends ChangeNotifier {
  RiverpodPageCache({this.maxEntries = 24});

  final int maxEntries;

  final LinkedHashMap<String, RiverpodPageHandle> _entries =
      LinkedHashMap<String, RiverpodPageHandle>();
  SessionStore? _boundSessionStore;
  bool _lastHasSession = false;

  int get size => _entries.length;

  /// 页面 initState 调；返回 handle，页面 dispose 时 [RiverpodPageHandle.release]。
  ///
  /// - 命中同 key：MRU 重放，返回同一 handle（引用计数 +1）。
  /// - 未命中：调 [resolveLinks] 拿一组 [KeepAliveLink] 塞进 LRU；超上限
  ///   驱逐最旧条目（对 link 逐个 close）。
  RiverpodPageHandle obtain({
    required String key,
    required List<KeepAliveLink> Function() resolveLinks,
  }) {
    final existing = _entries.remove(key);
    if (existing != null) {
      existing._refCount++;
      _entries[key] = existing;
      return existing;
    }
    final handle = RiverpodPageHandle(key, resolveLinks());
    _entries[key] = handle;
    _evictIfNeeded();
    return handle;
  }

  /// 立即释放某 key 的保活（页面主动弃权时用）；常规路径走
  /// handle.release + LRU 驱逐。
  void remove(String key) {
    final removed = _entries.remove(key);
    if (removed == null) {
      return;
    }
    for (final link in removed.links) {
      link.close();
    }
  }

  /// 全部清空：对每个 link close（触发 provider 释放）。
  void clearAll() {
    if (_entries.isEmpty) {
      return;
    }
    final values = _entries.values.toList(growable: false);
    _entries.clear();
    for (final handle in values) {
      for (final link in handle.links) {
        link.close();
      }
    }
  }

  /// 绑定会话：登出边沿（hasSession true→false）自动 [clearAll]。
  void bindSessionStore(SessionStore sessionStore) {
    if (identical(_boundSessionStore, sessionStore)) {
      return;
    }
    _boundSessionStore?.removeListener(_handleSessionChanged);
    _boundSessionStore = sessionStore;
    _lastHasSession = sessionStore.hasSession;
    _boundSessionStore?.addListener(_handleSessionChanged);
    if (!_lastHasSession) {
      clearAll();
    }
  }

  void _handleSessionChanged() {
    final sessionStore = _boundSessionStore;
    if (sessionStore == null) {
      return;
    }
    final hasSession = sessionStore.hasSession;
    if (!hasSession && _lastHasSession) {
      clearAll();
    }
    _lastHasSession = hasSession;
  }

  void _evictIfNeeded() {
    while (_entries.length > maxEntries) {
      final oldestKey = _entries.keys.first;
      final removed = _entries.remove(oldestKey);
      if (removed == null) {
        break;
      }
      for (final link in removed.links) {
        link.close();
      }
    }
  }

  @override
  void dispose() {
    _boundSessionStore?.removeListener(_handleSessionChanged);
    clearAll();
    super.dispose();
  }
}
