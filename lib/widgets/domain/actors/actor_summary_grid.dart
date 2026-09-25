import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/actors/data/dto/actor_list_item_dto.dart';
import 'package:sakuramedia/widgets/base/layout/grids/app_adaptive_card_grid.dart';
import 'package:sakuramedia/widgets/domain/actors/actor_summary_card.dart';

/// 累计分页女优列表使用的 Sliver 网格版本。
class ActorSummarySliver extends StatelessWidget {
  const ActorSummarySliver({
    super.key,
    required this.items,
    this.errorMessage,
    this.onActorTap,
    this.onActorSubscriptionTap,
    this.isActorSubscriptionUpdating,
    this.emptyMessage = '当前没有可展示的女优数据。',
  });

  final List<ActorListItemDto> items;
  final String? errorMessage;
  final ValueChanged<ActorListItemDto>? onActorTap;
  final ValueChanged<ActorListItemDto>? onActorSubscriptionTap;
  final bool Function(ActorListItemDto actor)? isActorSubscriptionUpdating;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveCardSliver<ActorListItemDto>(
      gridKey: const Key('actor-summary-grid'),
      items: items,
      errorMessage: errorMessage,
      emptyMessage: emptyMessage,
      itemBuilder:
          (context, actor, index) => ActorSummaryCard(
            actor: actor,
            onTap: onActorTap == null ? null : () => onActorTap!(actor),
            onSubscriptionTap:
                onActorSubscriptionTap == null
                    ? null
                    : () => onActorSubscriptionTap!(actor),
            isSubscriptionUpdating:
                isActorSubscriptionUpdating?.call(actor) ?? false,
          ),
    );
  }
}
