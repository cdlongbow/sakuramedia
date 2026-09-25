import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/actors/data/dto/actor_list_item_dto.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/interaction/app_cover_hover_info.dart';
import 'package:sakuramedia/widgets/base/interaction/app_interactive_surface.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_cover_card.dart';
import 'package:sakuramedia/widgets/base/media/images/app_cover_bottom_shade.dart';
import 'package:sakuramedia/widgets/base/media/images/masked_image.dart';
import 'package:sakuramedia/widgets/domain/movies/subscription_heart_badge.dart';

/// 女优摘要卡：竖版海报 + 底部渐变姓名，与影片卡同参数（`lg` 圆角、常驻 1px
/// 边框与卡片阴影）；触摸端没有 hover，停留在这层，随卡片附带的订阅心提供主操作。
///
/// 桌面悬停时底部渐显姓名与订阅 / 取消订阅动作，收起态姓名层淡出；与全站封面
/// 卡片共用同一套悬停披露范式。演员页没有多选 / 右键菜单业务，卡片不接入。
class ActorSummaryCard extends StatelessWidget {
  const ActorSummaryCard({
    super.key,
    required this.actor,
    this.onTap,
    this.onSubscriptionTap,
    this.isSubscriptionUpdating = false,
  });

  final ActorListItemDto actor;
  final VoidCallback? onTap;
  final VoidCallback? onSubscriptionTap;
  final bool isSubscriptionUpdating;

  @override
  Widget build(BuildContext context) {
    final componentTokens = context.appComponentTokens;
    final spacing = context.appSpacing;

    final card = AppCoverCard(
      key: Key('actor-summary-card-${actor.id}'),
      coverAspectRatio: componentTokens.movieCardAspectRatio,
      cover: _ActorPoster(actor: actor),
      collapsedOverlay: _buildCollapsedOverlay(context),
      infoBuilder: (context) => _buildHoverInfo(context),
    );

    return Stack(
      children: [
        AppInteractiveSurface(onTap: onTap, child: card),
        Positioned(
          top: spacing.xs,
          left: spacing.xs,
          child: SubscriptionHeartBadge(
            key: Key('actor-summary-card-subscription-${actor.id}'),
            loadingKey: Key(
              'actor-summary-card-subscription-loading-${actor.id}',
            ),
            isSubscribed: actor.isSubscribed,
            isUpdating: isSubscriptionUpdating,
            onTap: onSubscriptionTap,
          ),
        ),
      ],
    );
  }

  /// 收起态名字层：底部渐变 + 姓名（Tooltip 补全截断）；悬停展开时淡出。
  Widget _buildCollapsedOverlay(BuildContext context) {
    final spacing = context.appSpacing;
    return Stack(
      fit: StackFit.expand,
      children: [
        const AppCoverBottomShade(stops: [0.42, 0.7, 1]),
        Positioned(
          left: spacing.md,
          right: spacing.md,
          bottom: spacing.md,
          child: Tooltip(
            message: actor.displayName,
            waitDuration: const Duration(milliseconds: 300),
            child: Text(
              actor.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: resolveCoverOverlayTextStyle(
                context,
                size: AppTextSize.s12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 悬停面板：姓名与订阅 / 取消订阅动作。
  Widget _buildHoverInfo(BuildContext context) {
    final spacing = context.appSpacing;
    final subscribe = onSubscriptionTap;
    final actions = <Widget>[
      if (subscribe != null)
        AppCoverHoverActionButton(
          key: Key('actor-summary-card-subscription-action-${actor.id}'),
          icon: actor.isSubscribed
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          tooltip: actor.isSubscribed ? '取消订阅' : '订阅演员',
          onTap: isSubscriptionUpdating ? null : subscribe,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppCoverHoverInfoRow(label: actor.displayName),
        if (actions.isNotEmpty) ...[
          SizedBox(height: spacing.sm),
          AppCoverHoverActionBar(actions: actions),
        ],
      ],
    );
  }
}

class _ActorPoster extends StatelessWidget {
  const _ActorPoster({required this.actor});

  final ActorListItemDto actor;

  @override
  Widget build(BuildContext context) {
    final imageUrl = actor.profileImage?.bestAvailableUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    if (!hasImage) {
      // 纯图片卡缺图态统一为 muted 纯色块：不带渐变 / 居中图标。
      return ColoredBox(
        key: Key('actor-summary-card-placeholder-${actor.id}'),
        color: context.appColors.surfaceMuted,
      );
    }

    return MaskedImage(url: imageUrl, fit: BoxFit.cover);
  }
}
