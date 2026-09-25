import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/core/format/media_timecode.dart';
import 'package:sakuramedia/features/moments/presentation/moment_listing_models.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/interaction/app_cover_hover_info.dart';
import 'package:sakuramedia/widgets/base/interaction/selection/selection_check_badge.dart';
import 'package:sakuramedia/widgets/base/media/images/masked_image.dart';

/// 时刻卡：整卡即封面，收起态不铺任何文字；桌面端指针悬停时底部渐显单行
/// 「番号 / 视频号 + 内容类型 · 时刻位置」与靠右的播放按钮。
///
/// 触摸端没有 hover（移动端靠点击预览与长按多选），触屏停在收起态。
class MomentCard extends StatelessWidget {
  const MomentCard({
    super.key,
    required this.item,
    this.onTap,
    this.onPlay,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelectedChanged,
    this.onLongPress,
  });

  final MomentListItem item;
  final VoidCallback? onTap;

  /// 悬停面板里的播放主按钮回调（跳播到该时刻）;为 `null` 时不显示按钮。
  final VoidCallback? onPlay;

  final bool selectionMode;
  final bool isSelected;
  final ValueChanged<bool>? onSelectedChanged;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final selected = selectionMode && isSelected;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        mouseCursor: (selectionMode ? onSelectedChanged != null : onTap != null)
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        key: Key('moment-card-${item.pointId}'),
        borderRadius: context.appRadius.lgBorder,
        onTap: selectionMode
            ? () => onSelectedChanged?.call(!isSelected)
            : onTap,
        onLongPress: onLongPress,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.appColors.surfaceCard,
            borderRadius: context.appRadius.lgBorder,
            border: Border.all(
              color: selected
                  ? context.appColors.selectionBorder
                  : context.appColors.borderSubtle,
              width: selected ? 2 : 1,
            ),
            boxShadow: context.appShadows.card,
          ),
          child: ClipRRect(
            borderRadius: context.appRadius.lgBorder,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppCoverHoverInfo(
                  enabled: !selectionMode,
                  cover: MaskedImage(
                    url: item.image?.bestAvailableUrl ?? '',
                    fit: BoxFit.cover,
                  ),
                  infoBuilder: (context) => _buildHoverInfo(context),
                ),
                if (selectionMode)
                  Positioned(
                    top: context.appSpacing.xs,
                    left: context.appSpacing.xs,
                    child: IgnorePointer(
                      child: SelectionCheckBadge(isSelected: isSelected),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 悬停展开内容：单行「标签 + 类型 · 时刻位置（来源已删除时补提示）」，
  /// 播放主按钮靠右。
  Widget _buildHoverInfo(BuildContext context) {
    final kindLabel = item.isVideo ? '视频' : 'JAV';
    final meta = StringBuffer(
      '$kindLabel · ${formatMediaTimecode(item.offsetSeconds)}',
    );
    if (item.mediaId <= 0) {
      meta.write(' · 来源已删除');
    }
    final play = onPlay;
    return AppCoverHoverInfoRow(
      key: Key('moment-card-info-${item.pointId}'),
      label: item.displayLabel,
      meta: meta.toString(),
      action: play == null
          ? null
          : AppCoverHoverPlayButton(
              key: Key('moment-card-play-${item.pointId}'),
              onTap: play,
            ),
    );
  }
}
