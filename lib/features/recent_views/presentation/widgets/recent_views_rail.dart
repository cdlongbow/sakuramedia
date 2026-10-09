import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/app/app_platform.dart';
import 'package:sakuramedia/features/actors/data/dto/actor_list_item_dto.dart';
import 'package:sakuramedia/features/actors/presentation/providers/actor_subscription_toggle_provider.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/movies/presentation/actions/movie_collection_feature_actions.dart';
import 'package:sakuramedia/features/movies/presentation/providers/movie_subscription_toggle_provider.dart';
import 'package:sakuramedia/features/recent_views/data/dto/recent_view_dto.dart';
import 'package:sakuramedia/features/subscriptions/presentation/subscription_feedback.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/scrolling/app_scroll_rail.dart';
import 'package:sakuramedia/widgets/domain/actors/actor_summary_card.dart';
import 'package:sakuramedia/widgets/domain/movies/movie_summary_card.dart';

/// 「最近浏览」横向 rail：影片/女优混排，卡宽与其他预览 rail 同档
/// （移动 `mobileLatestMovieCardWidth`，桌面 `movieCardTargetWidth` 的 0.75）。
///
/// 卡片直接复用全站标准的 [MovieSummaryCard] / [ActorSummaryCard]：
/// 订阅心、热度角标、ⓘ 检查器与悬停面板都随卡片自带；订阅切换走跨列表的
/// 标准 toggle provider，历史顺序不因订阅状态变化而增删。
class RecentViewsRail extends ConsumerWidget {
  const RecentViewsRail({
    super.key,
    required this.entries,
    required this.onMovieTap,
    required this.onActorTap,
  });

  final List<RecentViewEntryDto> entries;
  final ValueChanged<String> onMovieTap;
  final ValueChanged<int> onActorTap;

  static const double _desktopCardWidthFactor = 0.75;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.appComponentTokens;
    final isMobile = AppPlatformScope.maybeOf(context) == AppPlatform.mobile;
    final cardWidth = isMobile
        ? tokens.mobileLatestMovieCardWidth
        : tokens.movieCardTargetWidth * _desktopCardWidthFactor;
    final cardHeight = cardWidth / tokens.movieCardAspectRatio;
    final updatingMovieNumbers = ref.watch(movieSubscriptionToggleProvider);
    final updatingActorIds = ref.watch(actorSubscriptionToggleProvider);
    return AppScrollRail(
      scrollViewKey: const Key('recent-views-rail'),
      height: cardHeight,
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return SizedBox(
          width: cardWidth,
          child: _buildCard(
            context,
            ref,
            entry,
            updatingMovieNumbers,
            updatingActorIds,
          ),
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref,
    RecentViewEntryDto entry,
    Set<String> updatingMovieNumbers,
    Set<int> updatingActorIds,
  ) {
    final movie = entry.movie;
    if (movie != null) {
      return MovieSummaryCard(
        key: Key('recent-view-card-movie-${movie.movieNumber}'),
        movie: movie,
        onTap: () => onMovieTap(movie.movieNumber),
        onRequestMenu: (globalPosition) => requestMovieCollectionMenu(
          context,
          movie.movieNumber,
          globalPosition,
          isSubscribed: movie.isSubscribed,
        ),
        onSubscriptionTap: () =>
            unawaited(_toggleMovieSubscription(ref, context, movie)),
        isSubscriptionUpdating: updatingMovieNumbers.contains(
          movie.movieNumber,
        ),
      );
    }
    final ActorListItemDto actor = entry.actor!;
    return ActorSummaryCard(
      key: Key('recent-view-card-actor-${actor.id}'),
      actor: actor,
      onTap: () => onActorTap(actor.id),
      onSubscriptionTap: () =>
          unawaited(_toggleActorSubscription(ref, context, actor)),
      isSubscriptionUpdating: updatingActorIds.contains(actor.id),
    );
  }
}

Future<void> _toggleMovieSubscription(
  WidgetRef ref,
  BuildContext context,
  MovieListItemDto movie,
) async {
  final result = await ref
      .read(movieSubscriptionToggleProvider.notifier)
      .toggle(movieNumber: movie.movieNumber, isSubscribed: movie.isSubscribed);
  if (context.mounted) showMovieSubscriptionFeedback(result);
}

Future<void> _toggleActorSubscription(
  WidgetRef ref,
  BuildContext context,
  ActorListItemDto actor,
) async {
  final result = await ref
      .read(actorSubscriptionToggleProvider.notifier)
      .toggle(actorId: actor.id, isSubscribed: actor.isSubscribed);
  if (context.mounted) showActorSubscriptionFeedback(result);
}
