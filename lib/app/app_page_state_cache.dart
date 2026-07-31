import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:sakuramedia/app/providers/app_page_state_cache_provider.dart';
import 'package:sakuramedia/core/session/session_store.dart';

abstract interface class AppPageStateEntry {
  void dispose();
}

class AppPageStateCache extends ChangeNotifier {
  AppPageStateCache({this.maxEntries = 24});

  final int maxEntries;
  final LinkedHashMap<String, AppPageStateEntry> _entries =
      LinkedHashMap<String, AppPageStateEntry>();
  SessionStore? _boundSessionStore;
  bool _lastHasSession = false;

  int get size => _entries.length;

  T obtain<T extends AppPageStateEntry>({
    required String key,
    required T Function() create,
  }) {
    final existing = _entries.remove(key);
    if (existing != null) {
      _entries[key] = existing;
      return existing as T;
    }

    final created = create();
    _entries[key] = created;
    _evictIfNeeded();
    return created;
  }

  void remove(String key) {
    final removed = _entries.remove(key);
    if (removed == null) {
      return;
    }
    removed.dispose();
  }

  void clear() {
    if (_entries.isEmpty) {
      return;
    }
    final values = _entries.values.toList(growable: false);
    _entries.clear();
    for (final value in values) {
      value.dispose();
    }
  }

  void bindSessionStore(SessionStore sessionStore) {
    if (identical(_boundSessionStore, sessionStore)) {
      return;
    }
    _boundSessionStore?.removeListener(_handleSessionChanged);
    _boundSessionStore = sessionStore;
    _lastHasSession = sessionStore.hasSession;
    _boundSessionStore?.addListener(_handleSessionChanged);
    if (!_lastHasSession) {
      clear();
    }
  }

  void _handleSessionChanged() {
    final sessionStore = _boundSessionStore;
    if (sessionStore == null) {
      return;
    }
    final hasSession = sessionStore.hasSession;
    if (!hasSession && _lastHasSession) {
      clear();
    }
    _lastHasSession = hasSession;
  }

  void _evictIfNeeded() {
    while (_entries.length > maxEntries) {
      final oldestKey = _entries.keys.first;
      final removed = _entries.remove(oldestKey);
      removed?.dispose();
    }
  }

  @override
  void dispose() {
    _boundSessionStore?.removeListener(_handleSessionChanged);
    clear();
    super.dispose();
  }
}

/// 软查找全局页面状态缓存。
///
/// 经 Riverpod 容器读 [appPageStateCacheProvider]；树上没有 `ProviderScope`
/// （多数 widget 测试）时返回 null、页面降级为 owned state（与旧
/// `ProviderNotFoundException` 降级语义一致）；`try/catch` 兼作上游依赖
/// 异常兜底（如依赖的 sessionStore 构造失败时）。
AppPageStateCache? maybeReadAppPageStateCache(BuildContext context) {
  try {
    return ProviderScope.containerOf(
      context,
      listen: false,
    ).read(appPageStateCacheProvider);
  } on Object {
    return null;
  }
}
