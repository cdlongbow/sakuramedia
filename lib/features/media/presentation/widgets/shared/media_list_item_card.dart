import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/configuration/data/dto/media_library_dto.dart';
import 'package:sakuramedia/features/media/data/media_list_item_dto.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_cover_thumbnail.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_list_item_meta_line.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_list_item_path_line.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_badge.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_left_cover_card.dart';

/// 单条媒体的统一展示卡，供媒体列表和媒体维护列表复用。
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
  final bool showUpdatedAt;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final componentTokens = context.appComponentTokens;
    final coverWidth = mobile
        ? componentTokens.mobileFollowMovieThinCoverWidth
        : componentTokens.downloadTaskCoverWidth;
    final coverHeight = mobile
        ? componentTokens.mobileFollowMovieCardHeight
        : componentTokens.mediaManagementRowHeight;

    final card = AppLeftCoverCard(
      key: Key('$keyPrefix-row-${item.id}'),
      coverWidth: coverWidth,
      bodyMinHeight: coverHeight,
      bodyPadding: EdgeInsets.symmetric(
        horizontal: spacing.lg,
        vertical: spacing.md,
      ),
      selected: selected,
      onTap: onTap,
      cover: _MediaListItemCover(
        keyPrefix: keyPrefix,
        item: item,
        width: coverWidth,
        height: coverHeight,
        mobile: mobile,
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
        showUpdatedAt: showUpdatedAt,
      ),
    );

    if (!mobile || onLongPress == null) return card;
    return GestureDetector(
      key: Key('$keyPrefix-row-long-press-${item.id}'),
      behavior: HitTestBehavior.translucent,
      onLongPress: onLongPress,
      child: card,
    );
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
    required this.showUpdatedAt,
  });

  final String keyPrefix;
  final MediaListItemDto item;
  final MediaLibraryDto? library;
  final bool mobile;
  final VoidCallback? onDelete;
  final bool isDeleting;
  final bool canDelete;
  final bool showUpdatedAt;

  Widget _content(BuildContext context) {
    final spacing = context.appSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MediaListItemHeading(keyPrefix: keyPrefix, item: item),
        SizedBox(height: spacing.md),
        MediaListItemMetaLine(
          item: item,
          library: library,
          spacing: spacing.sm,
          runSpacing: spacing.xs,
        ),
        if (!mobile || item.fileName.isNotEmpty) ...[
          SizedBox(height: spacing.sm),
          MediaListItemPathLine(
            keyPrefix: keyPrefix,
            item: item,
            showUpdatedAt: showUpdatedAt,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (onDelete == null) return _content(context);
    final deleteButton = AppButton(
      key: Key('$keyPrefix-delete-${item.id}'),
      label: isDeleting ? '删除中' : '删除',
      size: AppButtonSize.small,
      variant: AppButtonVariant.danger,
      icon: const Icon(Icons.delete_outline_rounded),
      isLoading: isDeleting,
      onPressed: canDelete ? onDelete : null,
    );
    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _content(context),
          SizedBox(height: context.appSpacing.md),
          Align(alignment: Alignment.centerRight, child: deleteButton),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _content(context)),
        SizedBox(width: context.appSpacing.lg),
        deleteButton,
      ],
    );
  }
}

class _MediaListItemCover extends StatelessWidget {
  const _MediaListItemCover({
    required this.keyPrefix,
    required this.item,
    required this.width,
    required this.height,
    required this.mobile,
    this.onOpenMovieDetail,
  });

  final String keyPrefix;
  final MediaListItemDto item;
  final double width;
  final double height;
  final bool mobile;
  final void Function(BuildContext context, String movieNumber)?
  onOpenMovieDetail;

  String? get _coverUrl {
    if (mobile) return item.preferredCoverUrl;
    final coverUrl = item.coverImage?.bestAvailableUrl.trim();
    if (coverUrl != null && coverUrl.isNotEmpty) return coverUrl;
    return item.thinCoverImage?.bestAvailableUrl.trim();
  }

  @override
  Widget build(BuildContext context) {
    final image = MediaCoverThumbnail(
      url: _coverUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.displayHeading,
                key: Key('$keyPrefix-row-heading-${item.id}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: resolveAppTextStyle(
                  context,
                  size: AppTextSize.s14,
                  weight: AppTextWeight.semibold,
                  tone: AppTextTone.primary,
                ),
              ),
              if (item.displaySubtitle != null) ...[
                SizedBox(height: spacing.xs),
                Text(
                  item.displaySubtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s12,
                    weight: AppTextWeight.regular,
                    tone: AppTextTone.secondary,
                  ),
                ),
              ],
            ],
          ),
        ),
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
