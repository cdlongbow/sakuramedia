import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/listing/movie_filter_state.dart';
import 'package:sakuramedia/features/tags/presentation/providers/tag_selection_scope.dart';
import 'package:sakuramedia/features/tags/presentation/providers/tag_selection_state.dart';
import 'package:sakuramedia/features/tags/presentation/providers/tags_api_provider.dart';

part 'tag_selection_provider.g.dart';

/// 标签云及选择草稿。
///
/// 使用同步 Notifier 保留旧控制器的复合态（旧数据 + loading/error），根页面按
/// scope 的 cacheKey 交给 RiverpodPageCache 限量保活；详情预选页则 autoDispose。
@riverpod
class TagSelection extends _$TagSelection {
  KeepAliveLink? _cacheLink;
  bool _disposed = false;

  KeepAliveLink? get cacheLink => _cacheLink;

  @override
  TagSelectionState build(TagSelectionScope scope) {
    if (scope.cacheKey != null) {
      _cacheLink ??= ref.keepAlive();
    }
    ref.onDispose(() => _disposed = true);
    final initial = TagSelectionState(
      selectedTagIds: scope.initialSelectedTagIds,
      matchMode: scope.initialMatchMode,
      popularLimit: scope.popularLimit,
    );
    Future<void>.microtask(load);
    return initial;
  }

  Future<void> load() async {
    if (state.isLoading) {
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final tags = await ref.read(tagsApiProvider).getTags();
      if (_disposed) {
        return;
      }
      state = state.copyWith(
        allTags: tags,
        isLoading: false,
        hasLoadedOnce: true,
        errorMessage: null,
      );
    } catch (error) {
      if (_disposed) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: apiErrorMessage(error, fallback: '标签加载失败，请稍后重试'),
      );
    }
  }

  Future<void> retry() => load();

  void setQuery(String value) {
    if (state.searchQuery == value) {
      return;
    }
    state = state.copyWith(searchQuery: value);
  }

  void toggleExpanded() => state = state.copyWith(expanded: !state.expanded);

  void setMatchMode(TagMatchMode mode) {
    if (state.matchMode != mode) {
      state = state.copyWith(matchMode: mode);
    }
  }

  void toggle(int tagId) {
    final next = List<int>.of(state.selectedTagIds);
    if (!next.remove(tagId)) {
      next.add(tagId);
    }
    state = state.copyWith(selectedTagIds: next);
  }

  void remove(int tagId) {
    final next = List<int>.of(state.selectedTagIds)..remove(tagId);
    if (next.length != state.selectedTagIds.length) {
      state = state.copyWith(selectedTagIds: next);
    }
  }

  void clear() {
    if (state.hasSelection) {
      state = state.copyWith(selectedTagIds: const <int>[]);
    }
  }
}
