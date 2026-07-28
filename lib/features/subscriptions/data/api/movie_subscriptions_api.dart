import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/network/paginated_response_dto.dart';
import 'package:sakuramedia/features/subscriptions/data/dto/movie_subscription_list_item_dto.dart';
import 'package:sakuramedia/features/subscriptions/data/dto/movie_subscription_search_reset_result_dto.dart';
import 'package:sakuramedia/features/subscriptions/data/dto/movie_subscription_status.dart';
import 'package:sakuramedia/features/subscriptions/data/dto/movie_subscription_status_counts_dto.dart';

/// 影片订阅**管理**（读 + 重置资源查询状态）。
///
/// 订阅的写入侧不在这里：单条订阅 / 取消订阅走 `MoviesApi.subscribeMovie` /
/// `unsubscribeMovie`，批量取消订阅走 `MoviesApi.batchUnsubscribeMovies`
/// （`POST /movies/unsubscriptions`）。后端刻意没有在 `/movie-subscriptions` 下平行
/// 造一套写端点，前端也不要在本类里补。
class MovieSubscriptionsApi {
  const MovieSubscriptionsApi({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// `GET /movie-subscriptions`：分页查询订阅影片及其资源查询状态。
  ///
  /// - [status] 为 `null` 表示不按状态过滤（后端默认 `all`）。
  /// - [search] 按番号 / 标题 / 中文标题模糊匹配，trim 后为空则不下发。
  Future<PaginatedResponseDto<MovieSubscriptionListItemDto>> getSubscriptions({
    int page = 1,
    int pageSize = 20,
    MovieSubscriptionStatus? status,
    MovieSubscriptionSort? sort,
    String? search,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    final statusValue = status?.apiValue;
    if (statusValue != null) {
      queryParameters['status'] = statusValue;
    }
    if (sort != null) {
      queryParameters['sort'] = sort.apiValue;
    }
    final trimmedSearch = search?.trim();
    if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
      queryParameters['search'] = trimmedSearch;
    }
    final response = await _apiClient.get(
      '/movie-subscriptions',
      queryParameters: queryParameters,
    );
    return PaginatedResponseDto<MovieSubscriptionListItemDto>.fromJson(
      response,
      MovieSubscriptionListItemDto.fromJson,
    );
  }

  /// `GET /movie-subscriptions/status-counts`：各状态计数，供分段签角标。
  Future<MovieSubscriptionStatusCountsDto> getStatusCounts() async {
    final response = await _apiClient.get('/movie-subscriptions/status-counts');
    return MovieSubscriptionStatusCountsDto.fromJson(response);
  }

  /// `POST /movie-subscriptions/search-resets`：把影片放回资源查询队列。
  ///
  /// [resetAllExhausted] 为 true 时后端忽略 [movieNumbers]，重置全部「已放弃」的
  /// 订阅影片。两者都为空 / false 时后端返回 422 `invalid_movie_subscription_reset`
  /// ——调用方应先判空，别把这个当作校验入口。
  Future<MovieSubscriptionSearchResetResultDto> resetSearchState({
    List<String> movieNumbers = const <String>[],
    bool resetAllExhausted = false,
  }) async {
    final response = await _apiClient.post(
      '/movie-subscriptions/search-resets',
      data: <String, dynamic>{
        'movie_numbers': movieNumbers,
        'reset_all_exhausted': resetAllExhausted,
      },
    );
    return MovieSubscriptionSearchResetResultDto.fromJson(response);
  }
}
