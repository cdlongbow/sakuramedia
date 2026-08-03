import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/features/playlists/data/dto/playlist_dto.dart';
import 'package:sakuramedia/features/playlists/presentation/providers/playlist_order_store_provider.dart';
import 'package:sakuramedia/features/playlists/presentation/providers/playlists_api_provider.dart';
import 'package:sakuramedia/features/playlists/presentation/providers/playlists_overview_scope.dart';
import 'package:sakuramedia/features/playlists/presentation/providers/playlists_overview_state.dart';
import 'package:sakuramedia/features/shared/presentation/providers/async_notifier_dispose_guard.dart';

part 'playlists_overview_provider.g.dart';

/// 播放列表概览：加载全量列表 + 后台逐个填首图，支持拖排序（可选持久化）、
/// 创建 / 编辑 / 删除的就地补丁。
///
/// autoDispose family([PlaylistsOverviewScope])：4 个消费入口（桌面/移动
/// playlists 独立页、configuration 管理 section、overview 移动骨架）按 scope
/// 定位实例，orderScopeKey=null 表不持久化顺序（configuration / mobile 独立页）。
///
/// 迁移前对应：`PlaylistsOverviewController`（5 个构造参数：3 个 API 闭包 +
/// orderStore + orderScopeKey）——本 provider 内联所有依赖（API/Store 各自
/// provider），scope 只留 orderScopeKey + includeSystem 两个业务参数。
///
/// **reorder 保持 fire-and-forget 语义**（原 controller
/// `unawaited(_savePlaylistOrder(...))`）——UI 侧无回滚需求，改成 await 会引入
/// 等待窗口。
@Riverpod(retry: kNoAsyncNotifierRetry)
class PlaylistsOverview extends _$PlaylistsOverview
    with AsyncNotifierDisposeGuardMixin<PlaylistsOverviewState> {
  @override
  Future<PlaylistsOverviewState> build(PlaylistsOverviewScope scope) async {
    attachDisposeGuard();
    final playlists = await _loadAndApplyPlaylists(scope);
    // 先把 playlists 立即渲染（coverUrls 全为 null 占位），再后台逐个 fetch
    // 首图，每张回来 patch 一次 state——渐进渲染，对齐原 controller `_loadCoverUrls`。
    unawaited(_startCoverUrlFetches(playlists));
    return PlaylistsOverviewState(
      playlists: playlists,
      coverUrls: <int, String?>{
        for (final playlist in playlists) playlist.id: null,
      },
    );
  }

  /// 保留态刷新：不切 loading；失败置 [AsyncError] 由 UI 兜底展示。
  Future<void> refresh() async {
    try {
      final playlists = await _loadAndApplyPlaylists(scope);
      if (isDisposed) return;
      state = AsyncData(
        PlaylistsOverviewState(
          playlists: playlists,
          coverUrls: <int, String?>{
            for (final playlist in playlists) playlist.id: null,
          },
        ),
      );
      unawaited(_startCoverUrlFetches(playlists));
    } catch (error, stack) {
      if (isDisposed) return;
      state = AsyncError(error, stack);
    }
  }

  /// 拖排序：本地立即改 + fire-and-forget 保存新顺序（与原 controller 一致，
  /// UI 无回滚需求）。
  void reorderPlaylists(int oldIndex, int newIndex) {
    final current = state.value;
    if (current == null) return;
    if (oldIndex < 0 ||
        oldIndex >= current.playlists.length ||
        newIndex < 0 ||
        newIndex > current.playlists.length) {
      return;
    }
    var targetIndex = newIndex;
    if (targetIndex > oldIndex) {
      targetIndex -= 1;
    }
    if (targetIndex == oldIndex) return;

    final updated = List<PlaylistDto>.from(current.playlists);
    final moved = updated.removeAt(oldIndex);
    updated.insert(targetIndex, moved);
    state = AsyncData(current.copyWith(playlists: updated));
    unawaited(_savePlaylistOrder(updated));
  }

  /// 通过 API 创建新播放列表并前置插入到本地列表。
  Future<PlaylistDto> createNewPlaylist({
    required String name,
    String? description,
  }) async {
    final playlist = await ref.read(playlistsApiProvider).createPlaylist(
          name: name,
          description: description,
        );
    if (!isDisposed) {
      insertPlaylist(playlist);
    }
    return playlist;
  }

  /// 已由外部创建：前置插入本地列表 + fire-and-forget 保存新顺序。
  void insertPlaylist(PlaylistDto playlist) {
    final current = state.value;
    if (current == null) return;
    final playlists = <PlaylistDto>[playlist, ...current.playlists];
    final coverUrls = <int, String?>{...current.coverUrls, playlist.id: null};
    state = AsyncData(
      current.copyWith(playlists: playlists, coverUrls: coverUrls),
    );
    unawaited(_savePlaylistOrder(playlists));
  }

  void replacePlaylist(PlaylistDto playlist) {
    final current = state.value;
    if (current == null) return;
    final updated = List<PlaylistDto>.from(current.playlists);
    final index = updated.indexWhere((item) => item.id == playlist.id);
    if (index >= 0) {
      updated[index] = playlist;
    } else {
      updated.insert(0, playlist);
    }
    final coverUrls = current.coverUrls.containsKey(playlist.id)
        ? current.coverUrls
        : <int, String?>{...current.coverUrls, playlist.id: null};
    state = AsyncData(
      current.copyWith(playlists: updated, coverUrls: coverUrls),
    );
    unawaited(_savePlaylistOrder(updated));
  }

  void removePlaylist(int playlistId) {
    final current = state.value;
    if (current == null) return;
    final playlists = current.playlists
        .where((playlist) => playlist.id != playlistId)
        .toList(growable: false);
    final coverUrls = Map<int, String?>.from(current.coverUrls)
      ..remove(playlistId);
    state = AsyncData(
      current.copyWith(playlists: playlists, coverUrls: coverUrls),
    );
    unawaited(_savePlaylistOrder(playlists));
  }

  Future<List<PlaylistDto>> _loadAndApplyPlaylists(
    PlaylistsOverviewScope scope,
  ) async {
    final playlists = await ref
        .read(playlistsApiProvider)
        .getPlaylists(includeSystem: scope.includeSystem);
    return _applyStoredOrder(playlists);
  }

  Future<List<PlaylistDto>> _applyStoredOrder(
    List<PlaylistDto> playlists,
  ) async {
    final scopeKey = _normalizedScopeKey;
    if (scopeKey == null) {
      return playlists;
    }
    final store = ref.read(playlistOrderStoreProvider);
    try {
      final storedOrder = await store.readPlaylistOrder(scopeKey: scopeKey);
      if (storedOrder.isEmpty) {
        return playlists;
      }
      final byId = <int, PlaylistDto>{
        for (final playlist in playlists) playlist.id: playlist,
      };
      final ordered = <PlaylistDto>[];
      final seen = <int>{};

      for (final id in storedOrder) {
        final playlist = byId[id];
        if (playlist == null || !seen.add(id)) {
          continue;
        }
        ordered.add(playlist);
      }
      for (final playlist in playlists) {
        if (!seen.add(playlist.id)) {
          continue;
        }
        ordered.add(playlist);
      }

      final normalizedOrder =
          ordered.map((playlist) => playlist.id).toList(growable: false);
      if (!listEquals(storedOrder, normalizedOrder)) {
        await store.savePlaylistOrder(
          scopeKey: scopeKey,
          playlistIds: normalizedOrder,
        );
      }
      return ordered;
    } catch (_) {
      return playlists;
    }
  }

  Future<void> _savePlaylistOrder(List<PlaylistDto> playlists) async {
    final scopeKey = _normalizedScopeKey;
    if (scopeKey == null) return;
    final store = ref.read(playlistOrderStoreProvider);
    try {
      await store.savePlaylistOrder(
        scopeKey: scopeKey,
        playlistIds: playlists.map((playlist) => playlist.id).toList(),
      );
    } catch (_) {
      // 忽略持久化失败，本地交互保持可用。
    }
  }

  String? get _normalizedScopeKey {
    final raw = scope.orderScopeKey?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw;
  }

  Future<void> _startCoverUrlFetches(List<PlaylistDto> playlists) async {
    final api = ref.read(playlistsApiProvider);
    for (final playlist in playlists) {
      if (isDisposed) return;
      if (playlist.movieCount <= 0) continue;
      String? url;
      try {
        final page = await api.getPlaylistMovies(
          playlistId: playlist.id,
          pageSize: 1,
        );
        url = page.items.firstOrNull?.coverImage?.bestAvailableUrl;
      } catch (_) {
        url = null;
      }
      if (isDisposed) return;
      final current = state.value;
      if (current == null) return;
      state = AsyncData(
        current.copyWith(
          coverUrls: <int, String?>{...current.coverUrls, playlist.id: url},
        ),
      );
    }
  }
}
