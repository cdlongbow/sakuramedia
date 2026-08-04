import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/app/page_cache_keys.dart';
import 'package:sakuramedia/app/providers/riverpod_page_cache_provider.dart';
import 'package:sakuramedia/app/riverpod_page_cache.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/external_player/presentation/external_player_availability.dart';
import 'package:sakuramedia/features/image_search/presentation/desktop_image_search_launcher.dart';
import 'package:sakuramedia/features/media/data/media_play_url_dto.dart';
import 'package:sakuramedia/features/media/data/media_storage_descriptor.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_detail_dto.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_detail_action_copy.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_detail_action_menu.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_detail_action_support.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/detail/movie_clip_section_mixin.dart';
import 'package:sakuramedia/features/movies/presentation/pages/shared/movie_detail_behavior_mixin.dart';
import 'package:sakuramedia/features/movies/presentation/pages/shared/movie_detail_page_content.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_clips_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_detail_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/mutation_events_provider.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_plot_image_actions.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_playback_options.dart';
import 'package:sakuramedia/features/playlists/presentation/widgets/movie_playlist_picker_dialog.dart';
import 'package:sakuramedia/routes/app_navigation_actions.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/interaction/refresh/app_page_refresh_scope.dart';
import 'package:sakuramedia/widgets/base/overlays/app_desktop_dialog.dart';
import 'package:sakuramedia/widgets/base/feedback/app_confirm_dialog.dart';
import 'package:sakuramedia/widgets/base/media/images/app_image_action_menu.dart';
import 'package:sakuramedia/widgets/domain/media/preview/media_preview_dialog.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_detail_inspector_dialog.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_plot_preview_overlay.dart';

class DesktopMovieDetailPage extends ConsumerStatefulWidget {
  const DesktopMovieDetailPage({super.key, required this.movieNumber});

  final String movieNumber;

  @override
  ConsumerState<DesktopMovieDetailPage> createState() =>
      _DesktopMovieDetailPageState();
}

class _DesktopMovieDetailPageState extends ConsumerState<DesktopMovieDetailPage>
    with MovieClipSectionMixin, MovieDetailBehaviorMixin {
  late final MovieSubscriptionEvents _subscriptionChangeNotifier;
  RiverpodPageHandle? _pageCacheHandle;

  @override
  String get movieNumber => widget.movieNumber;

  @override
  MovieSubscriptionEvents get subscriptionChangeNotifier =>
      _subscriptionChangeNotifier;

  @override
  void initState() {
    super.initState();
    _subscriptionChangeNotifier = resolveMovieSubscriptionNotifier(context);
    // 挂 keepAlive link 到 RiverpodPageCache：详情 + 切片 provider 的
    // cacheLink 一并托管，跨导航保活；LRU 驱逐时统一 close。
    _pageCacheHandle = ref
        .read(riverpodPageCacheProvider)
        .obtain(
          key: desktopMovieDetailPageCacheKey(widget.movieNumber),
          resolveLinks: () {
            final links = <KeepAliveLink>[];
            final detailLink = ref
                .read(movieDetailProvider(widget.movieNumber).notifier)
                .cacheLink;
            final clipsLink = ref
                .read(movieClipsProvider(widget.movieNumber).notifier)
                .cacheLink;
            if (detailLink != null) links.add(detailLink);
            if (clipsLink != null) links.add(clipsLink);
            return links;
          },
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref.read(movieDetailProvider(widget.movieNumber).notifier).load(),
      );
      unawaited(
        ref.read(movieClipsProvider(widget.movieNumber).notifier).load(),
      );
      loadMovieCollectionStatus();
    });
  }

  @override
  void dispose() {
    _pageCacheHandle?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(movieDetailProvider(widget.movieNumber));
    final clipsState = ref.watch(movieClipsProvider(widget.movieNumber));
    return AppPageRefreshScope(
      onRefresh: () =>
          ref.read(movieDetailProvider(widget.movieNumber).notifier).refresh(),
      child: Builder(
        builder: (context) {
          if (detailState.isLoading) {
            return const MovieDetailLoadingSkeleton();
          }

          if (detailState.errorMessage != null || detailState.movie == null) {
            return MovieDetailErrorState(
              message: detailState.errorMessage ?? '影片详情暂时无法加载，请稍后重试',
              onRetry: () => ref
                  .read(movieDetailProvider(widget.movieNumber).notifier)
                  .load(),
            );
          }

          final movie = detailState.movie!;
          final mediaItems = resolveMediaItems(movie);
          final isSubscribed = isSubscribedOverride ?? movie.isSubscribed;
          final isCollection = isCollectionOverride ?? movie.isCollection;
          final isActionControlsLocked = isMovieActionLocked;
          final sourceOptions = resolveMoviePlaybackSourceOptions(
            mediaItems: mediaItems,
            storageDescriptors: detailState.storageDescriptors,
          );
          final effectivePlaySource =
              playSource ?? sourceOptions.defaultSource;
          // 详情页下方媒体列表按当前播放源过滤,避免用户切了"本地"却仍能点到
          // 115 媒体、播放失败时收到"115 网盘媒体"文案的歧义。
          final visibleMediaItems = filterMediaItemsByPlaybackSource(
            mediaItems: mediaItems,
            storageDescriptors: detailState.storageDescriptors,
            source: effectivePlaySource,
          );
          final selectedMedia =
              visibleMediaItems
                  .where((item) => item.mediaId == selectedMediaId)
                  .firstOrNull ??
              (visibleMediaItems.isNotEmpty ? visibleMediaItems.first : null);
          final mergedPlaybackAvailable =
              isExternalPlayerReady(context) &&
              effectivePlaySource == MoviePlayUrlSource.local &&
              sourceOptions.localCount >= 2;
          return MovieDetailPageContent(
                movie: movie,
                mediaItemsOverride: visibleMediaItems,
                storageDescriptors: detailState.storageDescriptors,
                selectedPreviewKey: detailState.selectedPreviewKey,
                selectedPreviewUrl: detailState.selectedPreviewUrl,
                isCollection: isCollection,
                isSubscribed: isSubscribed,
                isCollectionUpdating: isCollectionUpdating,
                isSubscriptionUpdating: isSubscriptionUpdating,
                isMoreActionsUpdating: activeMovieAction != null,
                selectedMediaId: selectedMedia?.mediaId,
                statItems: buildMovieDetailStatItems(context, movie),
                similarMovies: detailState.similarMovies,
                isSimilarMoviesLoading: detailState.isSimilarMoviesLoading,
                similarMoviesErrorMessage:
                    detailState.similarMoviesErrorMessage,
                onRetrySimilarMovies: () => ref
                    .read(movieDetailProvider(widget.movieNumber).notifier)
                    .retryLoadSimilarMovies(),
                onSimilarMovieTap:
                    (similarMovie) => context.pushDesktopMovieDetail(
                      movieNumber: similarMovie.movieNumber,
                      fallbackPath: buildDesktopMovieDetailRoutePath(
                        widget.movieNumber,
                      ),
                    ),
                onSubscriptionTap:
                    isActionControlsLocked
                        ? null
                        : () => toggleMovieSubscription(
                          isSubscribed: isSubscribed,
                        ),
                onMoreActionsTap:
                    isActionControlsLocked
                        ? null
                        : (globalPosition) => _showMovieActionMenu(
                          globalPosition,
                          movie,
                          isSubscribed,
                          selectedMedia,
                        ),
                onPlayTap:
                    selectedMedia != null && selectedMedia.hasPlayableUrl
                        ? () => context.pushDesktopMoviePlayer(
                          movieNumber: widget.movieNumber,
                          fallbackPath: buildDesktopMovieDetailRoutePath(
                            widget.movieNumber,
                          ),
                          mediaId: selectedMedia.mediaId,
                        )
                        : null,
                sourceOptions: sourceOptions,
                selectedPlaySource: effectivePlaySource,
                onPlaySourceChanged: _handlePlaySourceChanged,
                mergedPlaybackAvailable: mergedPlaybackAvailable,
                onPlaylistTap:
                    () => showMoviePlaylistPickerDialog(
                      context,
                      movieNumber: widget.movieNumber,
                      initialPlaylists: movie.playlists,
                      presentation: MoviePlaylistPickerPresentation.dialog,
                    ),
                onCollectionToggle:
                    isActionControlsLocked
                        ? null
                        : () => toggleMovieCollectionType(
                          isCollection: isCollection,
                        ),
                onMediaSelect:
                    (item) => setState(() {
                      selectedMediaId = item.mediaId;
                    }),
                isDeletingSelectedMedia:
                    selectedMedia != null &&
                    deletingMediaId == selectedMedia.mediaId,
                onDeleteSelectedMedia:
                    selectedMedia == null ? null : deleteSelectedMedia,
                onOpenMediaPointPreview: openMediaPointPreview,
                onRequestMediaPointMenu: showMediaPointActions,
                onActorTap:
                    (actor) => context.pushDesktopActorDetail(
                      actorId: actor.id,
                      fallbackPath: buildDesktopMovieDetailRoutePath(
                        widget.movieNumber,
                      ),
                    ),
                onSeriesTap:
                    movie.seriesId == null
                        ? null
                        : () => context.pushDesktopMovieSeries(
                          seriesId: movie.seriesId!,
                          seriesName: movie.seriesName,
                          fallbackPath: buildDesktopMovieDetailRoutePath(
                            widget.movieNumber,
                          ),
                        ),
                onTagTap: (tag) => context.pushDesktopTags(tagId: tag.tagId),
                onRequestPlotImageMenu:
                    (menuContext, index, globalPosition) =>
                        showMoviePlotImageActionMenu(
                          context: menuContext,
                          hostContext: context,
                          plotImages: movie.plotImages,
                          movieNumber: widget.movieNumber,
                          index: index,
                          globalPosition: globalPosition,
                        ),
                onOpenPlotPreview:
                    (index) => showMoviePlotPreviewOverlay(
                      context: context,
                      plotImages: movie.plotImages,
                      initialIndex: index,
                      onRequestImageMenu:
                          (menuContext, previewIndex, globalPosition) =>
                              showMoviePlotImageActionMenu(
                                context: menuContext,
                                hostContext: context,
                                plotImages: movie.plotImages,
                                movieNumber: widget.movieNumber,
                                index: previewIndex,
                                globalPosition: globalPosition,
                                closeCurrentRouteOnSearch: true,
                              ),
                    ),
                onInspectorTap: () => openInspector(movie, selectedMedia),
                clips: clipsState.clips,
                isClipsLoading: clipsState.isLoading,
                clipsErrorMessage: clipsState.errorMessage,
                onRetryClips: () => ref
                    .read(movieClipsProvider(widget.movieNumber).notifier)
                    .retry(),
                onPlayClip: playMovieClip,
                onRenameClip: renameMovieClip,
                onDeleteClip: deleteMovieClip,
                onAddClipToCollection: addMovieClipToCollection,
              );
        },
      ),
    );
  }

  @override
  Future<bool?> confirmDeleteMedia(MovieMediaItemDto mediaItem) {
    final storage = resolveMediaStorageDescriptor(
      mediaItem.libraryId,
      ref.read(movieDetailProvider(widget.movieNumber)).storageDescriptors,
    );
    return showAppConfirmDialog(
      context,
      title: '删除媒体文件',
      message: mediaDeleteMessage(
        mediaItem,
        isCloud115: storage.isCloud115,
        isLocal: storage.isLocal,
      ),
      confirmLabel: '删除',
      danger: true,
      dialogKey: const Key('movie-media-delete-confirm-dialog'),
      confirmKey: const Key('movie-media-delete-confirm'),
      cancelKey: const Key('movie-media-delete-cancel'),
      extraContent: Text(
        mediaStorageLabel(storage),
        key: const Key('movie-media-delete-path'),
        style: resolveAppTextStyle(
          context,
          size: AppTextSize.s12,
          tone: AppTextTone.muted,
        ),
      ),
    );
  }

  Future<void> _showMovieActionMenu(
    Offset globalPosition,
    MovieDetailDto movie,
    bool isSubscribed,
    MovieMediaItemDto? selectedMedia,
  ) async {
    final action = await showMovieDetailDesktopActionMenu(
      context: context,
      globalPosition: globalPosition,
      actions: buildMovieDetailActionDescriptors(
        movie: movie,
        isSubscribed: isSubscribed,
      ),
    );
    if (!mounted || action == null) {
      return;
    }

    if (action == MovieDetailActionType.openInspector) {
      await openInspector(movie, selectedMedia);
      return;
    }

    if (action == MovieDetailActionType.refreshMetadata) {
      await _confirmRefreshMetadata();
      return;
    }

    await executeMovieAction(action);
  }

  @override
  Future<void> openInspector(
    MovieDetailDto movie,
    MovieMediaItemDto? selectedMedia,
  ) {
    return showMovieDetailInspectorDialog(
      context: context,
      movieNumber: movie.movieNumber,
      selectedMedia: selectedMedia,
    );
  }

  Future<void> _confirmRefreshMetadata() {
    var isSubmitting = false;

    return showDialog<void>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              Future<void> handleConfirm() async {
                if (isSubmitting) {
                  return;
                }
                setDialogState(() {
                  isSubmitting = true;
                });
                final succeeded = await executeMovieAction(
                  MovieDetailActionType.refreshMetadata,
                );
                if (!dialogContext.mounted) {
                  return;
                }
                if (succeeded) {
                  Navigator.of(dialogContext).pop();
                  return;
                }
                setDialogState(() {
                  isSubmitting = false;
                });
              }

              return AppDesktopDialog(
                dialogKey: const Key('movie-detail-refresh-metadata-dialog'),
                width: dialogContext.appLayoutTokens.dialogWidthSm,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MovieDetailRefreshConfirmationCopy.title,
                      style: resolveAppTextStyle(
                        dialogContext,
                        size: AppTextSize.s18,
                      ),
                    ),
                    SizedBox(height: dialogContext.appSpacing.lg),
                    Text(MovieDetailRefreshConfirmationCopy.description),
                    SizedBox(height: dialogContext.appSpacing.sm),
                    Text(
                      MovieDetailRefreshConfirmationCopy.hint,
                      style: resolveAppTextStyle(
                        dialogContext,
                        size: AppTextSize.s12,
                        tone: AppTextTone.muted,
                      ),
                    ),
                    SizedBox(height: dialogContext.appSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            key: const Key(
                              'movie-detail-refresh-metadata-cancel',
                            ),
                            onPressed:
                                isSubmitting
                                    ? null
                                    : () => Navigator.of(dialogContext).pop(),
                            label:
                                MovieDetailRefreshConfirmationCopy.cancelLabel,
                          ),
                        ),
                        SizedBox(width: dialogContext.appSpacing.md),
                        Expanded(
                          child: AppButton(
                            key: const Key(
                              'movie-detail-refresh-metadata-confirm',
                            ),
                            onPressed: isSubmitting ? null : handleConfirm,
                            label:
                                MovieDetailRefreshConfirmationCopy.confirmLabel,
                            variant: AppButtonVariant.primary,
                            isLoading: isSubmitting,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  @override
  Future<bool> executeMovieAction(MovieDetailActionType action) {
    if (action == MovieDetailActionType.toggleSubscription) {
      return toggleMovieSubscription(
        isSubscribed: isSubscribedOverride ??
            ref.read(movieDetailProvider(widget.movieNumber)).movie?.isSubscribed ??
            false,
      );
    }

    return executeMovieDetailRemoteAction(
      context: context,
      ref: ref,
      action: action,
      movieNumber: widget.movieNumber,
      isLocked: isMovieActionLocked,
      selectedMediaId: selectedMediaId,
      onActiveActionChanged: (nextAction) {
        if (!mounted) {
          return;
        }
        setState(() {
          activeMovieAction = nextAction;
        });
      },
      onMovieApplied: (result) {
        if (!mounted) {
          return;
        }
        setState(() {
          selectedMediaId = result.selectedMediaId;
          isSubscribedOverride = result.isSubscribedOverride;
          isCollectionOverride = result.isCollectionOverride;
        });
      },
    );
  }

  /// 切换播放源：选中该源下第一个可播放媒体。桌面无外部播放器，不涉及合并模式。
  void _handlePlaySourceChanged(MoviePlayUrlSource source) {
    final detailState = ref.read(movieDetailProvider(widget.movieNumber));
    final movie = detailState.movie;
    if (movie == null) {
      return;
    }
    setState(() {
      playSource = source;
      final target = resolveFirstPlayableMediaId(
        mediaItems: resolveMediaItems(movie),
        storageDescriptors: detailState.storageDescriptors,
        source: source,
      );
      if (target != null) {
        selectedMediaId = target;
      }
    });
  }

  @override
  Future<void> openMediaPointPreview(
    MovieMediaItemDto mediaItem,
    MovieMediaPointDto point,
  ) async {
    final action = await showMediaPreviewOverlay(
      context: context,
      presentation: MediaPreviewPresentation.dialog,
      builder:
          (_) => MediaPreviewDialog(
            item: _buildMediaPointPreviewItem(mediaItem, point),
            availableActions: <MediaPreviewAction>{
              if (resolvePointImageUrl(point).isNotEmpty)
                MediaPreviewAction.searchSimilar,
              if (mediaItem.hasPlayableUrl) MediaPreviewAction.play,
            },
            onPointRemoved:
                () => applyPointListOverride(
                  mediaItem.mediaId,
                  mediaItem.points
                      .where((candidate) => candidate.pointId != point.pointId)
                      .toList(growable: false),
                ),
            closeOnPointRemoved: true,
          ),
    );
    if (!mounted || action == null) {
      return;
    }
    switch (action) {
      case MediaPreviewAction.searchSimilar:
        await searchSimilarFromPoint(point);
      case MediaPreviewAction.play:
        openPlayerForPoint(mediaItem, point);
      case MediaPreviewAction.openMovieDetail:
        return;
    }
  }

  @override
  Future<void> showMediaPointActions(
    BuildContext menuContext,
    MovieMediaItemDto mediaItem,
    MovieMediaPointDto point,
    Offset globalPosition,
  ) async {
    final hasImage = resolvePointImageUrl(point).isNotEmpty;
    final currentPoint = findCurrentPoint(mediaItem.mediaId, point.pointId);
    final action = await showAppImageActionMenu(
      context: menuContext,
      globalPosition: globalPosition,
      actions: <AppImageActionDescriptor>[
        AppImageActionDescriptor(
          type: AppImageActionType.searchSimilar,
          label: '相似图片',
          icon: Icons.image_search_outlined,
          enabled: hasImage,
        ),
        AppImageActionDescriptor(
          type: AppImageActionType.saveToLocal,
          label: '保存到本地',
          icon: Icons.download_outlined,
          enabled: hasImage,
        ),
        AppImageActionDescriptor(
          type: AppImageActionType.toggleMark,
          label: currentPoint == null ? '添加标记' : '删除标记',
          icon:
              currentPoint == null
                  ? Icons.bookmark_add_outlined
                  : Icons.bookmark_remove_outlined,
          enabled:
              mediaItem.mediaId > 0 &&
              (currentPoint != null || point.thumbnailId > 0),
        ),
        AppImageActionDescriptor(
          type: AppImageActionType.play,
          label: '播放',
          icon: Icons.play_circle_outline_rounded,
          enabled: mediaItem.mediaId > 0 && mediaItem.hasPlayableUrl,
        ),
      ],
    );
    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case AppImageActionType.searchSimilar:
        await searchSimilarFromPoint(point);
        break;
      case AppImageActionType.saveToLocal:
        await savePointImageToLocal(point);
        break;
      case AppImageActionType.toggleMark:
        await toggleMediaPoint(mediaItem, point, currentPoint);
        break;
      case AppImageActionType.play:
        openPlayerForPoint(mediaItem, point);
        break;
      case AppImageActionType.movieDetail:
        break;
    }
  }

  MediaPreviewItem _buildMediaPointPreviewItem(
    MovieMediaItemDto mediaItem,
    MovieMediaPointDto point,
  ) {
    return MediaPreviewItem(
      imageUrl: resolvePointImageUrl(point),
      fileName: buildPointFileName(point),
      mediaId: mediaItem.mediaId,
      movieNumber: widget.movieNumber,
      thumbnailId: point.thumbnailId,
      offsetSeconds: point.offsetSeconds,
    );
  }

  @override
  Future<bool> searchSimilarFromPoint(MovieMediaPointDto point) async {
    final imageUrl = resolvePointImageUrl(point);
    if (imageUrl.isEmpty) {
      return false;
    }
    try {
      await launchDesktopImageSearchFromUrl(
        context,
        imageUrl: imageUrl,
        fallbackPath: buildDesktopMovieDetailRoutePath(widget.movieNumber),
        fileName: buildPointFileName(point),
        currentMovieNumber: widget.movieNumber,
      );
      return true;
    } catch (error) {
      if (mounted) {
        showToast(apiErrorMessage(error, fallback: '读取图片失败，请稍后重试'));
      }
      return false;
    }
  }

  @override
  void openPlayerForPoint(
    MovieMediaItemDto mediaItem,
    MovieMediaPointDto point,
  ) {
    context.pushDesktopMoviePlayer(
      movieNumber: widget.movieNumber,
      fallbackPath: buildDesktopMovieDetailRoutePath(widget.movieNumber),
      mediaId: mediaItem.mediaId,
      positionSeconds: point.offsetSeconds,
    );
  }
}
