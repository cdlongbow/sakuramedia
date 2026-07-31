import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:sakuramedia/app/app_page_state_cache.dart';
import 'package:sakuramedia/app/providers/app_page_state_cache_provider.dart';
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
import 'package:sakuramedia/features/activity/presentation/providers/activity_api_provider.dart';
import 'package:sakuramedia/features/actors/data/api/actors_api.dart';
import 'package:sakuramedia/features/actors/presentation/providers/actors_api_provider.dart';
import 'package:sakuramedia/features/auth/data/auth_api.dart';
import 'package:sakuramedia/features/auth/presentation/providers/auth_api_provider.dart';
import 'package:sakuramedia/features/clip_collections/data/api/clip_collections_api.dart';
import 'package:sakuramedia/features/clip_collections/presentation/providers/clip_collections_api_provider.dart';
import 'package:sakuramedia/features/clips/data/api/clips_api.dart';
import 'package:sakuramedia/features/clips/presentation/providers/clips_api_provider.dart';
import 'package:sakuramedia/features/configuration/data/api/config_api.dart';
import 'package:sakuramedia/features/configuration/data/api/download_clients_api.dart';
import 'package:sakuramedia/features/configuration/data/api/indexer_settings_api.dart';
import 'package:sakuramedia/features/configuration/data/api/media_libraries_api.dart';
import 'package:sakuramedia/features/configuration/data/api/movie_desc_translation_settings_api.dart';
import 'package:sakuramedia/features/configuration/presentation/providers/config_api_provider.dart';
import 'package:sakuramedia/features/configuration/presentation/providers/indexer_settings_api_provider.dart';
import 'package:sakuramedia/features/configuration/presentation/providers/llm_settings_provider.dart';
import 'package:sakuramedia/features/discovery/data/discovery_api.dart';
import 'package:sakuramedia/features/discovery/presentation/providers/discovery_api_provider.dart';
import 'package:sakuramedia/features/downloads/data/downloads_api.dart';
import 'package:sakuramedia/features/downloads/presentation/providers/downloads_api_provider.dart';
import 'package:sakuramedia/features/hot_reviews/data/hot_reviews_api.dart';
import 'package:sakuramedia/features/hot_reviews/presentation/providers/hot_reviews_api_provider.dart';
import 'package:sakuramedia/features/image_search/data/image_search_api.dart';
import 'package:sakuramedia/features/image_search/presentation/image_search_draft_store.dart';
import 'package:sakuramedia/features/image_search/presentation/providers/image_search_api_provider.dart';
import 'package:sakuramedia/features/image_search/presentation/providers/image_search_draft_store_provider.dart';
import 'package:sakuramedia/features/media/data/media_api.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_api_provider.dart';
import 'package:sakuramedia/features/media_import/data/media_import_api.dart';
import 'package:sakuramedia/features/media_import/presentation/providers/media_import_api_provider.dart';
import 'package:sakuramedia/features/clips/presentation/controllers/clip_mutation_change_notifier.dart';
import 'package:sakuramedia/features/clips/presentation/providers/clip_mutation_events_provider.dart';
import 'package:sakuramedia/features/movies/data/api/movies_api.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/notifiers/movie_collection_type_change_notifier.dart';
import 'package:sakuramedia/features/movies/presentation/controllers/notifiers/movie_subscription_change_notifier.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movies_api_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/mutation_events_provider.dart';
import 'package:sakuramedia/features/playlists/data/api/playlists_api.dart';
import 'package:sakuramedia/features/playlists/presentation/providers/playlists_api_provider.dart';
import 'package:sakuramedia/features/rankings/data/rankings_api.dart';
import 'package:sakuramedia/features/rankings/presentation/providers/rankings_api_provider.dart';
import 'package:sakuramedia/features/status/data/status_api.dart';
import 'package:sakuramedia/features/status/presentation/providers/status_api_provider.dart';
import 'package:sakuramedia/features/subscriptions/data/api/movie_subscriptions_api.dart';
import 'package:sakuramedia/features/subscriptions/presentation/providers/movie_subscriptions_api_provider.dart';
import 'package:sakuramedia/features/tags/data/tags_api.dart';
import 'package:sakuramedia/features/tags/presentation/providers/tags_api_provider.dart';
import 'package:sakuramedia/features/videos/data/api/video_collections_api.dart';
import 'package:sakuramedia/features/videos/data/api/video_imports_api.dart';
import 'package:sakuramedia/features/videos/data/api/videos_api.dart';
import 'package:sakuramedia/features/videos/presentation/providers/videos_api_provider.dart';

import 'fake_http_client_adapter.dart';
import 'in_memory_credential_store.dart';

class TestApiBundle {
  TestApiBundle({
    required this.sessionStore,
    required this.credentialStore,
    required this.apiClient,
    required this.accountApi,
    required this.activityApi,
    required this.activityEventStreamClient,
    required this.actorsApi,
    required this.authApi,
    required this.clipsApi,
    required this.configApi,
    required this.downloadClientsApi,
    required this.discoveryApi,
    required this.downloadsApi,
    required this.sseEventStreamClient,
    required this.indexerSettingsApi,
    required this.mediaApi,
    required this.mediaImportApi,
    required this.mediaLibrariesApi,
    required this.movieDescTranslationSettingsApi,
    required this.statusApi,
    required this.moviesApi,
    required this.movieSubscriptionsApi,
    required this.playlistsApi,
    required this.rankingsApi,
    required this.hotReviewsApi,
    required this.tagsApi,
    required this.videosApi,
    required this.videoCollectionsApi,
    required this.videoImportsApi,
    required this.clipCollectionsApi,
    required this.imageSearchApi,
    required this.adapter,
  });

  final SessionStore sessionStore;
  final CredentialStore credentialStore;
  final ApiClient apiClient;
  final AccountApi accountApi;
  final ActivityApi activityApi;
  final ActivityEventStreamClient activityEventStreamClient;
  final ActorsApi actorsApi;
  final AuthApi authApi;
  final ClipsApi clipsApi;
  final ConfigApi configApi;
  final DownloadClientsApi downloadClientsApi;
  final DiscoveryApi discoveryApi;
  final DownloadsApi downloadsApi;
  final SseEventStreamClient sseEventStreamClient;
  final IndexerSettingsApi indexerSettingsApi;
  final MediaApi mediaApi;
  final MediaImportApi mediaImportApi;
  final MediaLibrariesApi mediaLibrariesApi;
  final MovieDescTranslationSettingsApi movieDescTranslationSettingsApi;
  final StatusApi statusApi;
  final MoviesApi moviesApi;
  final MovieSubscriptionsApi movieSubscriptionsApi;
  final PlaylistsApi playlistsApi;
  final RankingsApi rankingsApi;
  final HotReviewsApi hotReviewsApi;
  final TagsApi tagsApi;
  final VideosApi videosApi;
  final VideoCollectionsApi videoCollectionsApi;
  final VideoImportsApi videoImportsApi;
  final ClipCollectionsApi clipCollectionsApi;
  final ImageSearchApi imageSearchApi;
  final FakeHttpClientAdapter adapter;

  /// 三个跨页 mutation 广播源的「单一实例」——与组合根一致:测试里 legacy
  /// Provider 侧与 Riverpod 侧都必须用同一个实例(Provider 树挂
  /// `.value(bundle.movieSubscriptionBroadcaster)`,Riverpod 侧由
  /// [riverpodOverrides] 自动注入),否则跨页广播静默丢事件。
  final MovieSubscriptionChangeNotifier movieSubscriptionBroadcaster =
      MovieSubscriptionChangeNotifier();

  /// 图搜草稿仓默认实例——图搜启动器经 Riverpod 容器写入草稿，测试树里必须有
  /// override 才能落笔。需要自持实例（预置草稿）的测试仍可传参覆盖。
  final ImageSearchDraftStore defaultImageSearchDraftStore =
      ImageSearchDraftStore();
  final MovieCollectionTypeChangeNotifier collectionTypeBroadcaster =
      MovieCollectionTypeChangeNotifier();
  final ClipMutationChangeNotifier clipMutationBroadcaster =
      ClipMutationChangeNotifier();

  /// 一次性产出全部 Riverpod 桥 provider 的 overrides——widget 测试给
  /// `ProviderScope(overrides: bundle.riverpodOverrides(...))` 用，
  /// 与 `lib/app/app.dart` 组合根的 override 清单同构。
  ///
  /// 非 API 的全局对象（页面缓存 / 图搜草稿仓 / 订阅广播源）按需传入；
  /// 不传则不 override，对应桥保持 UnimplementedError（用不到就不会触发）。
  List<Override> riverpodOverrides({
    AppPageStateCache? pageStateCache,
    ImageSearchDraftStore? imageSearchDraftStore,
    MovieSubscriptionChangeNotifier? movieSubscriptionBroadcaster,
    MovieCollectionTypeChangeNotifier? collectionTypeBroadcaster,
    ClipMutationChangeNotifier? clipMutationBroadcaster,
  }) {
    final subscriptionBroadcaster =
        movieSubscriptionBroadcaster ?? this.movieSubscriptionBroadcaster;
    final typeBroadcaster =
        collectionTypeBroadcaster ?? this.collectionTypeBroadcaster;
    final clipBroadcaster =
        clipMutationBroadcaster ?? this.clipMutationBroadcaster;
    return <Override>[
      apiClientProvider.overrideWithValue(apiClient),
      sessionStoreProvider.overrideWithValue(sessionStore),
      credentialStoreProvider.overrideWithValue(credentialStore),
      accountApiProvider.overrideWithValue(accountApi),
      activityApiProvider.overrideWithValue(activityApi),
      actorsApiProvider.overrideWithValue(actorsApi),
      authApiProvider.overrideWithValue(authApi),
      clipsApiProvider.overrideWithValue(clipsApi),
      clipCollectionsApiProvider.overrideWithValue(clipCollectionsApi),
      configApiProvider.overrideWithValue(configApi),
      discoveryApiProvider.overrideWithValue(discoveryApi),
      downloadsApiProvider.overrideWithValue(downloadsApi),
      downloadClientsApiProvider.overrideWithValue(downloadClientsApi),
      hotReviewsApiProvider.overrideWithValue(hotReviewsApi),
      imageSearchApiProvider.overrideWithValue(imageSearchApi),
      indexerSettingsApiProvider.overrideWithValue(indexerSettingsApi),
      llmSettingsApiProvider.overrideWithValue(movieDescTranslationSettingsApi),
      mediaApiProvider.overrideWithValue(mediaApi),
      mediaImportApiProvider.overrideWithValue(mediaImportApi),
      mediaLibrariesApiProvider.overrideWithValue(mediaLibrariesApi),
      moviesApiProvider.overrideWithValue(moviesApi),
      movieSubscriptionsApiProvider.overrideWithValue(movieSubscriptionsApi),
      playlistsApiProvider.overrideWithValue(playlistsApi),
      rankingsApiProvider.overrideWithValue(rankingsApi),
      statusApiProvider.overrideWithValue(statusApi),
      tagsApiProvider.overrideWithValue(tagsApi),
      videosApiProvider.overrideWithValue(videosApi),
      videoCollectionsApiProvider.overrideWithValue(videoCollectionsApi),
      videoImportsApiProvider.overrideWithValue(videoImportsApi),
      if (pageStateCache != null)
        appPageStateCacheProvider.overrideWithValue(pageStateCache),
      imageSearchDraftStoreProvider.overrideWithValue(
        imageSearchDraftStore ?? defaultImageSearchDraftStore,
      ),
      movieSubscriptionBroadcasterProvider.overrideWithValue(
        subscriptionBroadcaster,
      ),
      collectionTypeBroadcasterProvider.overrideWithValue(typeBroadcaster),
      clipMutationBroadcasterProvider.overrideWithValue(clipBroadcaster),
    ];
  }

  void dispose() {
    activityEventStreamClient.dispose();
    sseEventStreamClient.dispose();
    apiClient.dispose();
  }
}

Future<TestApiBundle> createTestApiBundle(SessionStore sessionStore) async {
  final credentialStore = InMemoryCredentialStore();
  final apiClient = ApiClient(sessionStore: sessionStore);
  final activityEventStreamClient = createActivityEventStreamClient(
    apiClient: apiClient,
    sessionStore: sessionStore,
  );
  final sseEventStreamClient = createSseEventStreamClient(
    apiClient: apiClient,
    sessionStore: sessionStore,
  );
  final adapter = FakeHttpClientAdapter();
  apiClient.rawDio.httpClientAdapter = adapter;
  apiClient.rawRefreshDio.httpClientAdapter = adapter;

  // 影片详情页 init 会发 GET /media-clips 拉该片切片(列表非关键),
  // 默认给空兜底,各用例无需逐个 enqueue;需要校验该端点的用例可显式 enqueue 覆盖。
  adapter.setFallbackJson(
    method: 'GET',
    path: '/media-clips',
    body: const <String, dynamic>{'items': <dynamic>[], 'total': 0},
  );

  return TestApiBundle(
    sessionStore: sessionStore,
    credentialStore: credentialStore,
    apiClient: apiClient,
    accountApi: AccountApi(apiClient: apiClient),
    activityApi: ActivityApi(
      apiClient: apiClient,
      streamClient: activityEventStreamClient,
    ),
    activityEventStreamClient: activityEventStreamClient,
    actorsApi: ActorsApi(apiClient: apiClient),
    authApi: AuthApi(
      apiClient: apiClient,
      sessionStore: sessionStore,
      credentialStore: credentialStore,
    ),
    clipsApi: ClipsApi(apiClient: apiClient),
    configApi: ConfigApi(apiClient: apiClient),
    downloadClientsApi: DownloadClientsApi(apiClient: apiClient),
    discoveryApi: DiscoveryApi(apiClient: apiClient),
    downloadsApi: DownloadsApi(
      apiClient: apiClient,
      streamClient: sseEventStreamClient,
    ),
    sseEventStreamClient: sseEventStreamClient,
    indexerSettingsApi: IndexerSettingsApi(apiClient: apiClient),
    mediaApi: MediaApi(apiClient: apiClient),
    mediaImportApi: MediaImportApi(apiClient: apiClient),
    mediaLibrariesApi: MediaLibrariesApi(apiClient: apiClient),
    movieDescTranslationSettingsApi: MovieDescTranslationSettingsApi(
      apiClient: apiClient,
    ),
    statusApi: StatusApi(apiClient: apiClient),
    moviesApi: MoviesApi(apiClient: apiClient),
    movieSubscriptionsApi: MovieSubscriptionsApi(apiClient: apiClient),
    playlistsApi: PlaylistsApi(apiClient: apiClient),
    rankingsApi: RankingsApi(apiClient: apiClient),
    hotReviewsApi: HotReviewsApi(apiClient: apiClient),
    tagsApi: TagsApi(apiClient: apiClient),
    videosApi: VideosApi(apiClient: apiClient),
    videoCollectionsApi: VideoCollectionsApi(apiClient: apiClient),
    videoImportsApi: VideoImportsApi(apiClient: apiClient),
    clipCollectionsApi: ClipCollectionsApi(apiClient: apiClient),
    imageSearchApi: ImageSearchApi(apiClient: apiClient),
    adapter: adapter,
  );
}
