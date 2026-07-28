import 'package:sakuramedia/core/json/json_parse.dart';

/// `POST /movie-subscriptions/search-resets` 的结果。
///
/// [resetCount] 是被删掉的资源查询状态行数——不是「本次会重新查到资源的影片数」。
/// 传入的番号里本来就没有状态行的（例如从未查过的待查片）不计入。
///
/// 重置**不放开选种黑名单**：`info_hash` 是内容寻址的，同一个 hash 就是同一个
/// swarm，换索引器它照样是死的。重置的语义是让影片去找**别的**种子。
class MovieSubscriptionSearchResetResultDto {
  const MovieSubscriptionSearchResetResultDto({this.resetCount = 0});

  final int resetCount;

  factory MovieSubscriptionSearchResetResultDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return MovieSubscriptionSearchResetResultDto(
      resetCount: asInt(json['reset_count']),
    );
  }
}
