import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/app/providers/riverpod_page_cache_provider.dart';
import 'package:sakuramedia/app/riverpod_page_cache.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/listing/movie_filter_state.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_summary_scope.dart';
import 'package:sakuramedia/features/tags/presentation/providers/tag_selection_provider.dart';
import 'package:sakuramedia/features/tags/presentation/providers/tag_selection_scope.dart';
import 'package:sakuramedia/features/tags/presentation/tag_movie_summary_content.dart';
import 'package:sakuramedia/features/tags/presentation/widgets/tag_browse_surface.dart';
import 'package:sakuramedia/features/tags/presentation/widgets/tag_selection_summary.dart';
import 'package:sakuramedia/routes/app_navigation_actions.dart';
import 'package:sakuramedia/routes/app_route_paths.dart';
import 'package:sakuramedia/theme.dart';

class DesktopTagsPage extends ConsumerStatefulWidget {
  const DesktopTagsPage({super.key, this.initialTagId});

  /// 从影片详情页跳入时携带的预选标签；为空表示一级导航入口。
  final int? initialTagId;

  @override
  ConsumerState<DesktopTagsPage> createState() => _DesktopTagsPageState();
}

class _DesktopTagsPageState extends ConsumerState<DesktopTagsPage> {
  late final TagSelectionScope _selectionScope = widget.initialTagId == null
      ? const TagSelectionScope.desktopRoot()
      : TagSelectionScope.desktopDetail(initialTagId: widget.initialTagId!);
  late final MovieSummaryScope _movieScope = MovieSummaryScope.tags(
    instanceKey: _selectionScope.instanceKey,
    cacheKey: _selectionScope.cacheKey,
    initialTagIds: _selectionScope.initialSelectedTagIds,
    initialTagMatch: _selectionScope.initialMatchMode,
  );
  RiverpodPageHandle? _pageCacheHandle;
  late bool _browseMode;
  List<int>? _snapshotTagIds;
  TagMatchMode? _snapshotMatchMode;

  @override
  void initState() {
    super.initState();
    _browseMode =
        widget.initialTagId == null &&
        !ref.read(tagSelectionProvider(_selectionScope)).hasSelection;
    final cacheKey = _selectionScope.cacheKey;
    if (cacheKey == null) {
      return;
    }
    _pageCacheHandle = ref
        .read(riverpodPageCacheProvider)
        .obtain(
          key: cacheKey,
          resolveLinks: () {
            final selectionLink = ref
                .read(tagSelectionProvider(_selectionScope).notifier)
                .cacheLink;
            final moviesLink = ref
                .read(movieSummaryProvider(_movieScope).notifier)
                .cacheLink;
            return [
              if (selectionLink != null) selectionLink,
              if (moviesLink != null) moviesLink,
            ];
          },
        );
  }

  @override
  void dispose() {
    _pageCacheHandle?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(tagSelectionProvider(_selectionScope));
    if (_browseMode || !selection.hasSelection) {
      return TagBrowseSurface(
        key: const Key('tags-page'),
        scope: _selectionScope,
        mobile: false,
        onConfirm: _confirmBrowse,
        onCancel: _snapshotTagIds == null ? null : _cancelBrowse,
      );
    }

    return TagMovieSummaryContent(
      key: const Key('tags-page'),
      selection: selection,
      headerLeading: TagSelectionSummary(
        scope: _selectionScope,
        mobile: false,
        onEdit: _enterBrowseFromResults,
        onRemoveTag: _removeTag,
        onClear: _clearTags,
      ),
      scope: _movieScope,
      surfaceColor: context.appColors.surfaceElevated,
      contentKey: const Key('tags-page-movies'),
      totalKey: const Key('tags-page-total'),
      sectionSpacing: context.appSpacing.lg,
      registerPageRefresh: true,
      onMovieTap: (context, movieNumber) => context.pushDesktopMovieDetail(
        movieNumber: movieNumber,
        fallbackPath: desktopTagsPath,
      ),
      bodyBuilder: (context, scrollController, sliver, _) => CustomScrollView(
        key: PageStorageKey<String>('${_selectionScope.instanceKey}:movies'),
        controller: scrollController,
        slivers: [sliver],
      ),
    );
  }

  void _confirmBrowse() {
    if (!ref.read(tagSelectionProvider(_selectionScope)).hasSelection) {
      return;
    }
    setState(() {
      _browseMode = false;
      _snapshotTagIds = null;
      _snapshotMatchMode = null;
    });
  }

  void _enterBrowseFromResults() {
    final selection = ref.read(tagSelectionProvider(_selectionScope));
    setState(() {
      _snapshotTagIds = List<int>.of(selection.selectedTagIds);
      _snapshotMatchMode = selection.matchMode;
      _browseMode = true;
    });
  }

  void _cancelBrowse() {
    final tagIds = _snapshotTagIds;
    final matchMode = _snapshotMatchMode;
    if (tagIds != null && matchMode != null) {
      ref
          .read(tagSelectionProvider(_selectionScope).notifier)
          .replaceSelection(tagIds, matchMode: matchMode);
    }
    setState(() {
      _browseMode = false;
      _snapshotTagIds = null;
      _snapshotMatchMode = null;
    });
  }

  void _removeTag(int tagId) {
    final notifier = ref.read(tagSelectionProvider(_selectionScope).notifier);
    notifier.remove(tagId);
    if (!ref.read(tagSelectionProvider(_selectionScope)).hasSelection) {
      setState(() {
        _browseMode = true;
        _snapshotTagIds = null;
        _snapshotMatchMode = null;
      });
    }
  }

  void _clearTags() {
    ref.read(tagSelectionProvider(_selectionScope).notifier).clear();
    setState(() {
      _browseMode = true;
      _snapshotTagIds = null;
      _snapshotMatchMode = null;
    });
  }
}
