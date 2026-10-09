import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/core/format/relative_time_label.dart';
import 'package:sakuramedia/features/recent_views/data/dto/recent_view_dto.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/interaction/app_interactive_surface.dart';
import 'package:sakuramedia/widgets/base/media/images/masked_image.dart';

/// 最近浏览行：影片=16:9 小封面 + 番号/标题；女优=方形头像 + 显示名；
/// 右侧相对时间。点击进对应详情页（回调由调用方给）。
class RecentViewRow extends StatelessWidget {
  const RecentViewRow({super.key, required this.entry, this.onTap});

  final RecentViewEntryDto entry;
  final VoidCallback? onTap;

  static const double _thumbWidth = 64;
  static const double _thumbHeight = 36;
  static const double _avatarSize = 36;

  static Key keyFor(RecentViewEntryDto entry) {
    final movie = entry.movie;
    if (movie != null) {
      return Key('recent-view-row-movie-${movie.movieNumber}');
    }
    return Key('recent-view-row-actor-${entry.actor?.id ?? 0}');
  }

  @override
  Widget build(BuildContext context) {
    final movie = entry.movie;
    final actor = entry.actor;
    final title = movie?.movieNumber ?? actor?.displayName ?? '';
    final subtitle = movie?.title ?? '';
    return AppInteractiveSurface(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.appSpacing.sm),
        child: Row(
          children: [
            _buildThumb(context),
            SizedBox(width: context.appSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: resolveAppTextStyle(
                      context,
                      size: AppTextSize.s14,
                      weight: AppTextWeight.medium,
                      tone: AppTextTone.primary,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: context.appSpacing.xs / 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: resolveAppTextStyle(
                        context,
                        size: AppTextSize.s12,
                        tone: AppTextTone.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: context.appSpacing.sm),
            Text(
              formatRelativeTimeLabel(entry.viewedAt),
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s12,
                tone: AppTextTone.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumb(BuildContext context) {
    final movie = entry.movie;
    final radius = context.appRadius.smBorder;
    if (movie != null) {
      final imageUrl = movie.thinCoverImage?.origin ?? movie.coverImage?.origin;
      return ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          width: _thumbWidth,
          height: _thumbHeight,
          child: _thumbImage(context, imageUrl),
        ),
      );
    }
    return SizedBox(
      width: _thumbWidth,
      height: _thumbHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            width: _avatarSize,
            height: _avatarSize,
            child: _thumbImage(context, entry.actor?.profileImage?.origin),
          ),
        ),
      ),
    );
  }

  Widget _thumbImage(BuildContext context, String? url) {
    final resolved = url?.trim() ?? '';
    if (resolved.isEmpty) {
      return ColoredBox(color: context.appColors.surfaceMuted);
    }
    return MaskedImage(url: resolved, fit: BoxFit.cover);
  }
}
