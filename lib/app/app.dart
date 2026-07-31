import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:go_router/go_router.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:sakuramedia/app/app_page_state_cache.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/app/app_state.dart';
import 'package:sakuramedia/app/providers/app_page_state_cache_provider.dart';
import 'package:sakuramedia/app/app_version_info_controller.dart';
import 'package:sakuramedia/app/web_platform_notice.dart';
import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/network/providers/api_client_provider.dart';
import 'package:sakuramedia/core/network/sse_event_stream_client.dart';
import 'package:sakuramedia/core/session/credential_store.dart';
import 'package:sakuramedia/core/session/providers/credential_store_provider.dart';
import 'package:sakuramedia/core/session/providers/session_store_provider.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/account/data/account_api.dart';
import 'package:sakuramedia/features/account/presentation/providers/account_api_provider.dart';
import 'package:sakuramedia/features/activity/data/activity_api.dart';
import 'package:sakuramedia/features/activity/data/activity_event_stream_client.dart';
import 'package:sakuramedia/features/activity/presentation/notification_center_controller.dart';
import 'package:sakuramedia/features/activity/presentation/providers/activity_api_provider.dart';
import 'package:sakuramedia/features/actors/data/api/actors_api.dart';
import 'package:sakuramedia/features/actors/presentation/providers/actors_api_provider.dart';
import 'package:sakuramedia/features/auth/data/auth_api.dart';
import 'package:sakuramedia/features/auth/presentation/providers/auth_api_provider.dart';
import 'package:sakuramedia/features/configuration/data/api/config_api.dart';
import 'package:sakuramedia/features/configuration/presentation/providers/config_api_provider.dart';
import 'package:sakuramedia/features/configuration/presentation/providers/indexer_settings_api_provider.dart';
import 'package:sakuramedia/features/configuration/data/api/download_clients_api.dart';
import 'package:sakuramedia/features/configuration/data/api/indexer_settings_api.dart';
import 'package:sakuramedia/features/configuration/data/api/media_libraries_api.dart';
import 'package:sakuramedia/features/configuration/data/api/movie_desc_translation_settings_api.dart';
import 'package:sakuramedia/features/configuration/presentation/providers/llm_settings_provider.dart';
import 'package:sakuramedia/features/discovery/data/discovery_api.dart';
import 'package:sakuramedia/features/discovery/presentation/providers/discovery_api_provider.dart';
import 'package:sakuramedia/features/downloads/data/downloads_api.dart';
import 'package:sakuramedia/features/downloads/presentation/providers/downloads_api_provider.dart';
import 'package:sakuramedia/features/image_search/data/image_search_api.dart';
import 'package:sakuramedia/features/image_search/presentation/providers/image_search_api_provider.dart';
import 'package:sakuramedia/features/image_search/presentation/providers/image_search_draft_store_provider.dart';
import 'package:sakuramedia/features/media_import/data/media_import_api.dart';
import 'package:sakuramedia/features/media_import/presentation/providers/media_import_api_provider.dart';
import 'package:sakuramedia/features/image_search/presentation/image_search_draft_store.dart';
import 'package:sakuramedia/features/clips/data/api/clips_api.dart';
import 'package:sakuramedia/features/clips/presentation/providers/clip_mutation_events_provider.dart';
import 'package:sakuramedia/features/clips/presentation/providers/clips_api_provider.dart';
import 'package:sakuramedia/features/clip_collections/data/api/clip_collections_api.dart';
import 'package:sakuramedia/features/clip_collections/presentation/providers/clip_collections_api_provider.dart';
import 'package:sakuramedia/features/media/data/media_api.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_api_provider.dart';
import 'package:sakuramedia/features/movies/data/api/movies_api.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movies_api_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/mutation_events_provider.dart';
import 'package:sakuramedia/features/subscriptions/data/api/movie_subscriptions_api.dart';
import 'package:sakuramedia/features/subscriptions/presentation/providers/movie_subscriptions_api_provider.dart';
import 'package:sakuramedia/features/tags/data/tags_api.dart';
import 'package:sakuramedia/features/tags/presentation/providers/tags_api_provider.dart';
import 'package:sakuramedia/features/videos/data/api/videos_api.dart';
import 'package:sakuramedia/features/videos/data/api/video_collections_api.dart';
import 'package:sakuramedia/features/videos/data/api/video_imports_api.dart';
import 'package:sakuramedia/features/videos/presentation/providers/videos_api_provider.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/notifiers/movie_collection_type_change_notifier.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/notifiers/movie_subscription_change_notifier.dart';
import 'package:sakuramedia/features/clips/presentation/controllers/clip_mutation_change_notifier.dart';
import 'package:sakuramedia/features/hot_reviews/data/hot_reviews_api.dart';
import 'package:sakuramedia/features/hot_reviews/presentation/providers/hot_reviews_api_provider.dart';
import 'package:sakuramedia/features/playlists/data/api/playlists_api.dart';
import 'package:sakuramedia/features/playlists/presentation/providers/playlists_api_provider.dart';
import 'package:sakuramedia/features/rankings/data/rankings_api.dart';
import 'package:sakuramedia/features/rankings/presentation/providers/rankings_api_provider.dart';
import 'package:sakuramedia/features/status/data/status_api.dart';
import 'package:sakuramedia/features/status/presentation/providers/status_api_provider.dart';
import 'package:sakuramedia/routes/app_router.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/media/images/app_image_fullscreen.dart';

/// 允许发起拖拽滚动的指针类型集合(应用全局 [ScrollConfiguration] 使用)。
///
/// 必须为 [PointerDeviceKind] 全集 —— 尤其不能漏掉 [PointerDeviceKind.unknown]:
/// 无障碍服务 / 远程控制工具(如 Android VoiceAccess、RustDesk 经
/// `AccessibilityService.dispatchGesture` 注入的滑动手势)上报的 pointer kind
/// 即为 unknown,缺它会导致这类来源只能点击、无法滚动(Flutter 框架默认集合
/// `_kTouchLikeDeviceTypes` 同样包含 unknown,原因一致)。
const Set<PointerDeviceKind> kAppScrollDragDevices = <PointerDeviceKind>{
  PointerDeviceKind.touch,
  PointerDeviceKind.mouse,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
  PointerDeviceKind.trackpad,
  PointerDeviceKind.unknown,
};

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.platformOverride, this.sessionStore});

  final AppPlatform? platformOverride;
  final SessionStore? sessionStore;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppPlatform _platform;
  late SessionStore _activeSessionStore;
  late GoRouter _router;
  late bool _ownsSessionStore;

  @override
  void initState() {
    super.initState();
    _initializeAppState();
  }

  @override
  void didUpdateWidget(covariant MyApp oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.platformOverride == widget.platformOverride &&
        oldWidget.sessionStore == widget.sessionStore) {
      return;
    }

    _disposeAppState();
    _initializeAppState();
  }

  @override
  void dispose() {
    _disposeAppState();
    super.dispose();
  }

  void _initializeAppState() {
    _platform = resolveAppPlatform(override: widget.platformOverride);
    _ownsSessionStore = widget.sessionStore == null;
    _activeSessionStore = widget.sessionStore ?? SessionStore.inMemory();
    _router = buildAppRouter(_platform, _activeSessionStore);
  }

  void _disposeAppState() {
    _router.dispose();
    if (_ownsSessionStore) {
      _activeSessionStore.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AppPlatform 已改走 AppPlatformScope InheritedWidget（本 build 下方），
        // 不再经 provider 注入。
        ChangeNotifierProvider(create: (_) => AppShellController()),
        ChangeNotifierProvider<SessionStore>.value(value: _activeSessionStore),
        ChangeNotifierProxyProvider<SessionStore, AppPageStateCache>(
          create:
              (context) =>
                  AppPageStateCache()
                    ..bindSessionStore(context.read<SessionStore>()),
          update: (context, sessionStore, cache) {
            final activeCache = cache ?? AppPageStateCache();
            activeCache.bindSessionStore(sessionStore);
            return activeCache;
          },
        ),
        Provider<CredentialStore>(create: (_) => CredentialStore()),
        Provider<ApiClient>(
          create:
              (context) =>
                  ApiClient(sessionStore: context.read<SessionStore>()),
          dispose: (context, client) => client.dispose(),
        ),
        Provider<SseEventStreamClient>(
          create:
              (context) => createSseEventStreamClient(
                apiClient: context.read<ApiClient>(),
                sessionStore: context.read<SessionStore>(),
              ),
          dispose: (context, client) => client.dispose(),
        ),
        Provider<AuthApi>(
          create:
              (context) => AuthApi(
                apiClient: context.read<ApiClient>(),
                sessionStore: context.read<SessionStore>(),
                credentialStore: context.read<CredentialStore>(),
              ),
        ),
        Provider<AccountApi>(
          create: (context) => AccountApi(apiClient: context.read<ApiClient>()),
        ),
        Provider<ActivityEventStreamClient>(
          create:
              (context) => createActivityEventStreamClient(
                apiClient: context.read<ApiClient>(),
                sessionStore: context.read<SessionStore>(),
              ),
          dispose: (context, client) => client.dispose(),
        ),
        Provider<ActivityApi>(
          create:
              (context) => ActivityApi(
                apiClient: context.read<ApiClient>(),
                streamClient: context.read<ActivityEventStreamClient>(),
              ),
        ),
        ChangeNotifierProvider<NotificationCenterController>(
          create:
              (context) => NotificationCenterController(
                activityApi: context.read<ActivityApi>(),
              )..bindSessionStore(context.read<SessionStore>()),
        ),
        Provider<ActorsApi>(
          create: (context) => ActorsApi(apiClient: context.read<ApiClient>()),
        ),
        Provider<DownloadClientsApi>(
          create:
              (context) =>
                  DownloadClientsApi(apiClient: context.read<ApiClient>()),
        ),
        Provider<DownloadsApi>(
          create:
              (context) => DownloadsApi(
                apiClient: context.read<ApiClient>(),
                streamClient: context.read<SseEventStreamClient>(),
              ),
        ),
        Provider<IndexerSettingsApi>(
          create:
              (context) =>
                  IndexerSettingsApi(apiClient: context.read<ApiClient>()),
        ),
        Provider<MediaLibrariesApi>(
          create:
              (context) =>
                  MediaLibrariesApi(apiClient: context.read<ApiClient>()),
        ),
        Provider<MediaImportApi>(
          create:
              (context) => MediaImportApi(apiClient: context.read<ApiClient>()),
        ),
        Provider<MovieDescTranslationSettingsApi>(
          create:
              (context) => MovieDescTranslationSettingsApi(
                apiClient: context.read<ApiClient>(),
              ),
        ),
        Provider<ConfigApi>(
          create: (context) => ConfigApi(apiClient: context.read<ApiClient>()),
        ),
        Provider<StatusApi>(
          create: (context) => StatusApi(apiClient: context.read<ApiClient>()),
        ),
        Provider<DiscoveryApi>(
          create:
              (context) => DiscoveryApi(apiClient: context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<AppVersionInfoController>(
          create:
              (context) => AppVersionInfoController(
                statusApi: context.read<StatusApi>(),
              ),
        ),
        Provider<MoviesApi>(
          create: (context) => MoviesApi(apiClient: context.read<ApiClient>()),
        ),
        Provider<MovieSubscriptionsApi>(
          create:
              (context) =>
                  MovieSubscriptionsApi(apiClient: context.read<ApiClient>()),
        ),
        Provider<TagsApi>(
          create: (context) => TagsApi(apiClient: context.read<ApiClient>()),
        ),
        Provider<VideosApi>(
          create: (context) => VideosApi(apiClient: context.read<ApiClient>()),
        ),
        Provider<VideoCollectionsApi>(
          create:
              (context) =>
                  VideoCollectionsApi(apiClient: context.read<ApiClient>()),
        ),
        Provider<VideoImportsApi>(
          create:
              (context) =>
                  VideoImportsApi(apiClient: context.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (_) => MovieCollectionTypeChangeNotifier(),
        ),
        ChangeNotifierProvider(
          create: (_) => MovieSubscriptionChangeNotifier(),
        ),
        // VideoMutationChangeNotifier 与 CollectionPlaybackHandoff 已原生迁移
        // 到 Riverpod（videos / shared 的 presentation/providers/）。
        ChangeNotifierProvider(create: (_) => ClipMutationChangeNotifier()),
        Provider<PlaylistsApi>(
          create:
              (context) => PlaylistsApi(apiClient: context.read<ApiClient>()),
        ),
        Provider<RankingsApi>(
          create:
              (context) => RankingsApi(apiClient: context.read<ApiClient>()),
        ),
        Provider<HotReviewsApi>(
          create:
              (context) => HotReviewsApi(apiClient: context.read<ApiClient>()),
        ),
        Provider<MediaApi>(
          create: (context) => MediaApi(apiClient: context.read<ApiClient>()),
        ),
        Provider<ClipsApi>(
          create: (context) => ClipsApi(apiClient: context.read<ApiClient>()),
        ),
        Provider<ClipCollectionsApi>(
          create:
              (context) =>
                  ClipCollectionsApi(apiClient: context.read<ApiClient>()),
        ),
        Provider<ImageSearchApi>(
          create:
              (context) => ImageSearchApi(apiClient: context.read<ApiClient>()),
        ),
        Provider<ImageSearchDraftStore>(create: (_) => ImageSearchDraftStore()),
        // ExternalPlayerStore 已原生迁移到 Riverpod
        // （features/external_player/presentation/providers/），不再经 provider 注入。
      ],
      child: Builder(
        builder: (context) {
          return ProviderScope(
            overrides: [
              llmSettingsApiProvider.overrideWithValue(
                context.read<MovieDescTranslationSettingsApi>(),
              ),
              mediaApiProvider.overrideWithValue(context.read<MediaApi>()),
              mediaLibrariesApiProvider.overrideWithValue(
                context.read<MediaLibrariesApi>(),
              ),
              downloadsApiProvider.overrideWithValue(
                context.read<DownloadsApi>(),
              ),
              downloadClientsApiProvider.overrideWithValue(
                context.read<DownloadClientsApi>(),
              ),
              moviesApiProvider.overrideWithValue(context.read<MoviesApi>()),
              activityApiProvider.overrideWithValue(
                context.read<ActivityApi>(),
              ),
              movieSubscriptionsApiProvider.overrideWithValue(
                context.read<MovieSubscriptionsApi>(),
              ),
              // 跨页订阅广播的「单一广播源」：Provider 侧与 Riverpod 侧共用同一个
              // ChangeNotifier 实例，两侧 report 的变更彼此都能收到。
              movieSubscriptionBroadcasterProvider.overrideWithValue(
                context.read<MovieSubscriptionChangeNotifier>(),
              ),
              collectionTypeBroadcasterProvider.overrideWithValue(
                context.read<MovieCollectionTypeChangeNotifier>(),
              ),
              clipMutationBroadcasterProvider.overrideWithValue(
                context.read<ClipMutationChangeNotifier>(),
              ),
              // —— 迁移批次 1 起补齐的横切桥（真源仍在上方 MultiProvider，
              // 组合根反转时统一清偿）——
              apiClientProvider.overrideWithValue(context.read<ApiClient>()),
              sessionStoreProvider.overrideWithValue(
                context.read<SessionStore>(),
              ),
              credentialStoreProvider.overrideWithValue(
                context.read<CredentialStore>(),
              ),
              appPageStateCacheProvider.overrideWithValue(
                context.read<AppPageStateCache>(),
              ),
              statusApiProvider.overrideWithValue(context.read<StatusApi>()),
              configApiProvider.overrideWithValue(context.read<ConfigApi>()),
              indexerSettingsApiProvider.overrideWithValue(
                context.read<IndexerSettingsApi>(),
              ),
              tagsApiProvider.overrideWithValue(context.read<TagsApi>()),
              rankingsApiProvider.overrideWithValue(
                context.read<RankingsApi>(),
              ),
              hotReviewsApiProvider.overrideWithValue(
                context.read<HotReviewsApi>(),
              ),
              discoveryApiProvider.overrideWithValue(
                context.read<DiscoveryApi>(),
              ),
              actorsApiProvider.overrideWithValue(context.read<ActorsApi>()),
              accountApiProvider.overrideWithValue(context.read<AccountApi>()),
              authApiProvider.overrideWithValue(context.read<AuthApi>()),
              mediaImportApiProvider.overrideWithValue(
                context.read<MediaImportApi>(),
              ),
              videosApiProvider.overrideWithValue(context.read<VideosApi>()),
              videoCollectionsApiProvider.overrideWithValue(
                context.read<VideoCollectionsApi>(),
              ),
              videoImportsApiProvider.overrideWithValue(
                context.read<VideoImportsApi>(),
              ),
              clipsApiProvider.overrideWithValue(context.read<ClipsApi>()),
              clipCollectionsApiProvider.overrideWithValue(
                context.read<ClipCollectionsApi>(),
              ),
              playlistsApiProvider.overrideWithValue(
                context.read<PlaylistsApi>(),
              ),
              imageSearchApiProvider.overrideWithValue(
                context.read<ImageSearchApi>(),
              ),
              imageSearchDraftStoreProvider.overrideWithValue(
                context.read<ImageSearchDraftStore>(),
              ),
            ],
            child: AppPlatformScope(
              platform: _platform,
              child: OKToast(
                textStyle: kAppToastTextStyle,
                child: MaterialApp.router(
                  title: 'SakuraMedia',
                  debugShowCheckedModeBanner: false,
                  theme:
                      _platform == AppPlatform.mobile
                          ? sakuraMobileThemeData
                          : sakuraDesktopThemeData,
                  routerConfig: _router,
                  builder: (context, child) {
                    return WebPlatformNoticeHost(
                      enabled: _platform == AppPlatform.web,
                      navigatorKey: _router.routerDelegate.navigatorKey,
                      child: AppImageFullscreenHost(
                        child: ScrollConfiguration(
                          behavior: const MaterialScrollBehavior().copyWith(
                            dragDevices: kAppScrollDragDevices,
                          ),
                          child: child ?? const SizedBox.shrink(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
