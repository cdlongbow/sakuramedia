import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/recent_views/data/api/recent_views_api.dart';
import 'package:sakuramedia/features/recent_views/data/dto/recent_view_dto.dart';
import 'package:sakuramedia/features/recent_views/presentation/providers/recent_views_provider.dart';
import 'package:sakuramedia/features/recent_views/presentation/widgets/recent_view_row.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/feedback/app_empty_state.dart';
import 'package:sakuramedia/widgets/base/feedback/app_inline_spinner.dart';

/// 「最近浏览」更多页的四态列表（sliver 版）：加载 / 错误 / 空 / 内容。
class RecentViewsSliverList extends ConsumerWidget {
  const RecentViewsSliverList({
    super.key,
    required this.onRetry,
    required this.onMovieTap,
    required this.onActorTap,
  });

  final VoidCallback onRetry;
  final ValueChanged<String> onMovieTap;
  final ValueChanged<int> onActorTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentViewsProvider(RecentViewsApi.listLimit));
    final entries = async.value;
    if (async.isLoading && entries == null) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: AppInlineSpinner()),
      );
    }
    if (async.hasError && entries == null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AppEmptyState(
          message: '最近浏览暂时无法加载，请稍后重试',
          onRetry: onRetry,
        ),
      );
    }
    final visible = entries ?? const <RecentViewEntryDto>[];
    if (visible.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: AppEmptyState(message: '还没有浏览记录'),
      );
    }
    return SliverList.separated(
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final entry = visible[index];
        return RecentViewRow(
          key: RecentViewRow.keyFor(entry),
          entry: entry,
          onTap: () => _openEntry(entry),
        );
      },
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: context.appColors.divider),
    );
  }

  void _openEntry(RecentViewEntryDto entry) {
    final movie = entry.movie;
    if (movie != null) {
      onMovieTap(movie.movieNumber);
      return;
    }
    final actor = entry.actor;
    if (actor != null) {
      onActorTap(actor.id);
    }
  }
}
