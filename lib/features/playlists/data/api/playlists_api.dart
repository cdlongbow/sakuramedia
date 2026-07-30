import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/network/paginated_response_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/playlists/data/dto/playlist_dto.dart';
import 'package:sakuramedia/features/playlists/data/dto/playlist_resolution_option_dto.dart';
import 'package:sakuramedia/features/playlists/data/playlist_resolution_filter.dart';

class PlaylistsApi {
  const PlaylistsApi({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<PlaylistDto>> getPlaylists({bool includeSystem = true}) async {
    final response = await _apiClient.getList(
      '/playlists',
      queryParameters: <String, dynamic>{'include_system': includeSystem},
    );
    return response.map(PlaylistDto.fromJson).toList(growable: false);
  }

  Future<PlaylistDto> createPlaylist({
    required String name,
    String? description,
  }) async {
    final response = await _apiClient.post(
      '/playlists',
      data: <String, dynamic>{
        'name': name.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      },
    );
    return PlaylistDto.fromJson(response);
  }

  Future<PlaylistDto> getPlaylistDetail({required int playlistId}) async {
    final response = await _apiClient.get('/playlists/$playlistId');
    return PlaylistDto.fromJson(response);
  }

  Future<PlaylistDto> updatePlaylist({
    required int playlistId,
    required UpdatePlaylistPayload payload,
  }) async {
    final response = await _apiClient.patch(
      '/playlists/$playlistId',
      data: payload.toJson(),
    );
    return PlaylistDto.fromJson(response);
  }

  Future<void> deletePlaylist(int playlistId) {
    return _apiClient.deleteNoContent('/playlists/$playlistId');
  }

  Future<PaginatedResponseDto<MovieListItemDto>> getPlaylistMovies({
    required int playlistId,
    int page = 1,
    int pageSize = 20,
    String? sort,
    String? resolution,
  }) async {
    final response = await _apiClient.get(
      '/playlists/$playlistId/movies',
      queryParameters: <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (sort != null) 'sort': sort,
        if (resolution != null) 'resolution': resolution,
      },
    );
    return PaginatedResponseDto<MovieListItemDto>.fromJson(
      response,
      MovieListItemDto.fromJson,
    );
  }

  /// 聚合播放列表内影片覆盖的分辨率档位（从高到低，附命中影片数），
  /// 供筛选下拉渲染。
  ///
  /// 前端按 [PlaylistResolutionFilter.values] 顺序做一次稳定排序，未在枚举
  /// 里登记的档位（后端新增但前端尚未收录）排到最后，以固定档位取值顺序、
  /// 屏蔽后端顺序抖动。
  Future<List<PlaylistResolutionOptionDto>> getPlaylistResolutions({
    required int playlistId,
  }) async {
    final response = await _apiClient.getList(
      '/playlists/$playlistId/resolutions',
    );
    final options = response
        .map(PlaylistResolutionOptionDto.fromJson)
        .toList(growable: false);
    return _sortResolutionOptions(options);
  }

  static List<PlaylistResolutionOptionDto> _sortResolutionOptions(
    List<PlaylistResolutionOptionDto> options,
  ) {
    int rankOf(String apiValue) {
      final filter = PlaylistResolutionFilterX.fromApiValue(apiValue);
      // 未识别档位排到已知档位之后，仍互相保持原始出现顺序。
      return filter == null
          ? PlaylistResolutionFilter.values.length
          : filter.index;
    }

    final sorted = [...options]
      ..sort((a, b) => rankOf(a.resolution).compareTo(rankOf(b.resolution)));
    return List.unmodifiable(sorted);
  }

  Future<void> addMovieToPlaylist({
    required int playlistId,
    required String movieNumber,
  }) {
    return _apiClient.putNoContent(
      '/playlists/$playlistId/movies/$movieNumber',
    );
  }

  Future<void> removeMovieFromPlaylist({
    required int playlistId,
    required String movieNumber,
  }) {
    return _apiClient.deleteNoContent(
      '/playlists/$playlistId/movies/$movieNumber',
    );
  }
}
