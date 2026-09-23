import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/configuration/data/dto/media_library_dto.dart';
import 'package:sakuramedia/features/media/data/media_list_item_dto.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_cover_thumbnail.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_list_item_meta_label.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_list_item_path_line.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';
import 'package:sakuramedia/widgets/base/feedback/app_inline_spinner.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_badge.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_left_cover_card.dart';

/// 单条媒体的统一展示卡，供媒体列表和媒体维护列表复用。
///
/// 版式对齐订阅管理行卡（[AppLeftCoverCard]）：`[封面 | 内容]`。
/// 封面贴左整高、由卡片圆角裁剪，桌面用宽图（16:9）、移动用窄竖图；
/// 卡片只有一层（白底、细边、无阴影），选中只换边框色。
///
/// 单项「删除 / 迁移 / 重试缩略图」是平铺的图标动作（不再收进「更多」菜单），
/// 移动端空间紧，操作另起一行右对齐。
class MediaListItemCard extends StatelessWidget {
  const MediaListItemCard({
    super.key,
    required this.keyPrefix,
    required this.item,
    required this.mobile,
    this.library,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.onOpenMovieDetail,
    this.onDelete,
    this.isDeleting = false,
    this.canDelete = true,
    this.onTransfer,
    this.isTransferring = false,
    this.canTransfer = true,
    this.onRetryThumbnails,
    this.isRetryingThumbnails = false,
    this.canRetryThumbnails = true,
    this.showUpdatedAt = false,
  });

  final String keyPrefix;
  final MediaListItemDto item;
  final bool mobile;
  final MediaLibraryDto? library;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final void Function(BuildContext context, String movieNumber)?
  onOpenMovieDetail;
  final VoidCallback? onDelete;
  final bool isDeleting;
  final bool canDelete;
  final VoidCallback? onTransfer;
  final bool isTransferring;
  final bool canTransfer;
  final VoidCallback? onRetryThumbnails;
  final bool isRetryingThumbnails;
  final bool canRetryThumbnails;
  final bool showUpdatedAt;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final tokens = context.appComponentTokens;
    final width = tokens.listRowCoverWidth;
    final height = tokens.listRowCoverHeight;
    final handleLongPress = onLongPress == null
        ? null
        : () {
            HapticFeedback.selectionClick();
            onLongPress!();
          };

    final card = AppLeftCoverCard(
      key: Key('$keyPrefix-row-${item.id}'),
      coverWidth: width,
      bodyMinHeight: height,
      bodyPadding: EdgeInsets.symmetric(
        horizontal: spacing.lg,
        vertical: spacing.md,
      ),
      selected: selected,
      onTap: onTap,
      onLongPress: mobile ? handleLongPress : null,
      cover: _MediaListItemCover(
        keyPrefix: keyPrefix,
        item: item,
        mobile: mobile,
        width: width,
        height: height,
        onOpenMovieDetail: onOpenMovieDetail,
      ),
      body: _MediaListItemBody(
        keyPrefix: keyPrefix,
        item: item,
        library: library,
        mobile: mobile,
        onDelete: onDelete,
        isDeleting: isDeleting,
        canDelete: canDelete,
        onTransfer: onTransfer,
        isTransferring: isTransferring,
        canTransfer: canTransfer,
        onRetryThumbnails: onRetryThumbnails,
        isRetryingThumbnails: isRetryingThumbnails,
        canRetryThumbnails: canRetryThumbnails,
        showUpdatedAt: showUpdatedAt,
      ),
    );

    return card;
  }
}

class _MediaListItemBody extends StatelessWidget {
  const _MediaListItemBody({
    required this.keyPrefix,
    required this.item,
    required this.library,
    required this.mobile,
    required this.onDelete,
    required this.isDeleting,
    required this.canDelete,
    required this.onTransfer,
    required this.isTransferring,
    required this.canTransfer,
    required this.onRetryThumbnails,
    required this.isRetryingThumbnails,
    required this.canRetryThumbnails,
    required this.showUpdatedAt,
  });

  final String keyPrefix;
  final MediaListItemDto item;
  final MediaLibraryDto? library;
  final bool mobile;
  final VoidCallback? onDelete;
  final bool isDeleting;
  final bool canDelete;
  final VoidCallback? onTransfer;
  final bool isTransferring;
  final bool canTransfer;
  final VoidCallback? onRetryThumbnails;
  final bool isRetryingThumbnails;
  final bool canRetryThumbnails;
  final bool showUpdatedAt;

  /// 缩略图重试：平铺图标动作；重试中换成小转圈。
  Widget? _retryAction(BuildContext context) {
    final retry = onRetryThumbnails;
    if (retry == null) {
      return null;
    }
    if (isRetryingThumbnails) {
      return const AppInlineSpinner();
    }
    return AppIconButton(
      key: Key('$keyPrefix-retry-thumbnails-${item.id}'),
      icon: const Icon(Icons.refresh_rounded),
      tooltip: '重试缩略图',
      semanticLabel: '重试缩略图',
      onPressed: canRetryThumbnails ? retry : null,
    );
  }

  /// 行操作（平铺图标）：行内「重试缩略图」+「迁移」+「删除」。
  Widget? _actions(BuildContext context, Widget? retry) {
    final spacing = context.appSpacing;
    final widgets = <Widget>[];
    if (retry != null) {
      widgets.add(retry);
    }
    if (onTransfer != null) {
      widgets.add(
        isTransferring
            ? const AppInlineSpinner()
            : AppIconButton(
                key: Key('$keyPrefix-transfer-${item.id}'),
                icon: const Icon(Icons.drive_file_move_outline),
                tooltip: '迁移',
                semanticLabel: '迁移到其它媒体库',
                onPressed: canTransfer ? onTransfer : null,
              ),
      );
    }
    if (onDelete != null) {
      widgets.add(
        isDeleting
            ? const AppInlineSpinner()
            : AppIconButton(
                key: Key('$keyPrefix-delete-${item.id}'),
                icon: const Icon(Icons.delete_outline_rounded),
                iconColor: context.appTextPalette.error,
                tooltip: '删除',
                semanticLabel: '删除',
                onPressed: canDelete ? onDelete : null,
              ),
      );
    }
    if (widgets.isEmpty) {
      return null;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < widgets.length; index += 1) ...[
          if (index > 0) SizedBox(width: spacing.xs),
          widgets[index],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final subtitle = item.displaySubtitle;
    final retryAction = _retryAction(context);
    final actions = _actions(context, retryAction);
    final pathLine = MediaListItemPathLine(
      keyPrefix: keyPrefix,
      item: item,
      // 行内重试占用了行尾，就不再挤「更新 …」。
      showUpdatedAt: showUpdatedAt && retryAction == null,
      trailing: mobile ? null : actions,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _MediaListItemHeading(keyPrefix: keyPrefix, item: item),
        if (subtitle != null) ...[
          SizedBox(height: spacing.xs),
          Text(
            subtitle,
            maxLines: mobile ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s12,
              tone: AppTextTone.secondary,
            ),
          ),
        ],
        SizedBox(height: spacing.sm),
        Text(
          buildMediaListItemMetaLabel(item, library: library),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s12,
            tone: AppTextTone.muted,
          ),
        ),
        SizedBox(height: spacing.xs),
        pathLine,
        if (mobile && actions != null) ...[
          SizedBox(height: spacing.sm),
          Align(alignment: AlignmentDirectional.centerEnd, child: actions),
        ],
      ],
    );
  }
}

class _MediaListItemCover extends StatelessWidget {
  const _MediaListItemCover({
    required this.keyPrefix,
    required this.item,
    required this.mobile,
    required this.width,
    required this.height,
    this.onOpenMovieDetail,
  });

  final String keyPrefix;
  final MediaListItemDto item;
  final bool mobile;
  final double width;
  final double height;
  final void Function(BuildContext context, String movieNumber)?
  onOpenMovieDetail;

  /// 桌面用宽图（16:9），移动用窄图。
  String? get _coverUrl => mobile ? item.preferredCoverUrl : item.wideCoverUrl;

  /// 用图与框方向一致才裁切（cover）；回退到另一方向的图时改居中留边（contain）。
  BoxFit get _coverFit {
    if (mobile) {
      return item.usesThinCover ? BoxFit.cover : BoxFit.contain;
    }
    return item.hasWideCover ? BoxFit.cover : BoxFit.contain;
  }

  @override
  Widget build(BuildContext context) {
    final image = MediaCoverThumbnail(
      url: _coverUrl,
      width: width,
      height: height,
      fit: _coverFit,
      placeholderKey: Key('$keyPrefix-cover-placeholder-${item.id}'),
      imageKey: Key('$keyPrefix-cover-${item.id}'),
      placeholderBackground: context.appColors.surfaceMuted,
    );
    final movieNumber = item.movieNumber?.trim();
    if (!item.isJav || movieNumber == null || movieNumber.isEmpty) {
      return image;
    }
    final openMovieDetail = onOpenMovieDetail;
    if (openMovieDetail == null) return image;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        key: Key('$keyPrefix-cover-tap-${item.id}'),
        onTap: () => openMovieDetail(context, movieNumber),
        child: image,
      ),
    );
  }
}

class _MediaListItemHeading extends StatelessWidget {
  const _MediaListItemHeading({required this.keyPrefix, required this.item});

  final String keyPrefix;
  final MediaListItemDto item;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    return Row(
      children: [
        Flexible(
          child: Text(
            item.displayHeading,
            key: Key('$keyPrefix-row-heading-${item.id}'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s16,
              weight: AppTextWeight.semibold,
              tone: AppTextTone.primary,
            ),
          ),
        ),
        // JAV 是绝大多数，徽标只在「视频归属」这类非默认情况出现；
        // 「未知归属」没有信息量，也不出徽标。
        if (item.kind == MediaListItemKind.video) ...[
          SizedBox(width: spacing.sm),
          AppBadge(
            label: item.kind.label,
            tone: AppBadgeTone.neutral,
            size: AppBadgeSize.compact,
          ),
        ],
        if (!item.valid) ...[
          SizedBox(width: spacing.sm),
          const AppBadge(
            label: '失效',
            tone: AppBadgeTone.error,
            size: AppBadgeSize.compact,
          ),
        ],
      ],
    );
  }
}
