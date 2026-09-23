import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/features/configuration/data/dto/media_library_dto.dart';
import 'package:sakuramedia/features/media/data/media_list_item_dto.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_libraries_provider.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_cover_thumbnail.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_list_item_meta_label.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_icon_button.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_badge.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_left_cover_card.dart';

/// 「同一影片的多个文件」组卡：组头 + 组内文件行，整卡只有一层。
///
/// 组头是「贴边小缩略图 + 标题区 + chevron」的 [AppLeftCoverCard]（`shell: false`
/// 复用其贴边封面布局），缩略图由组卡圆角裁剪、与行卡封面区分层级；
/// 组内文件行是平铺的「文件名 + 单行灰字元数据 + 尾部删除图标」，不再各自成卡。
class MediaFileGroupCard extends ConsumerWidget {
  const MediaFileGroupCard({
    super.key,
    required this.items,
    required this.countLabel,
    required this.headerKey,
    required this.deleteLabel,
    this.itemSupplement,
    required this.keyPrefix,
    required this.mobile,
    this.onOpen,
    required this.onDelete,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<MediaListItemDto> items;
  final String countLabel;
  final Key headerKey;
  final String deleteLabel;
  final Widget? Function(MediaListItemDto)? itemSupplement;
  final String keyPrefix;
  final bool mobile;
  final VoidCallback? onOpen;
  final ValueChanged<MediaListItemDto> onDelete;
  final Set<int>? selectedIds;
  final ValueChanged<MediaListItemDto> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final movie = items.first;
    final selectionLimitReached =
        items.where((item) => selectedIds?.contains(item.id) ?? false).length >=
        items.length - 1;
    final libraries = ref.watch(mediaLibrariesProvider).value?.librariesById;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: context.appRadius.mdBorder,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GroupHeader(
            movie: movie,
            countLabel: countLabel,
            headerKey: headerKey,
            keyPrefix: keyPrefix,
            mobile: mobile,
            onOpen: onOpen,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(spacing.lg, 0, spacing.lg, spacing.md),
            child: Column(
              children: [
                for (var index = 0; index < items.length; index += 1) ...[
                  if (index > 0)
                    Divider(height: 1, thickness: 1, color: colors.divider),
                  _FileRow(
                    item: items[index],
                    library: libraries?[items[index].libraryId],
                    keyPrefix: keyPrefix,
                    deleteLabel: deleteLabel,
                    selectionLimitReached: selectionLimitReached,
                    selectedIds: selectedIds,
                    onToggle: onToggle,
                    onDelete: onDelete,
                    itemSupplement: itemSupplement?.call(items[index]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.movie,
    required this.countLabel,
    required this.headerKey,
    required this.keyPrefix,
    required this.mobile,
    required this.onOpen,
  });

  final MediaListItemDto movie;
  final String countLabel;
  final Key headerKey;
  final String keyPrefix;
  final bool mobile;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final tokens = context.appComponentTokens;
    final width = tokens.listGroupHeaderCoverWidth;
    final height = tokens.listGroupHeaderCoverHeight;
    final subtitle = movie.displaySubtitle;
    return AppLeftCoverCard(
      key: headerKey,
      shell: false,
      coverWidth: width,
      bodyMinHeight: height,
      bodyPadding: EdgeInsets.all(mobile ? spacing.sm : spacing.md),
      onTap: onOpen,
      cover: MediaCoverThumbnail(
        url: mobile ? movie.preferredCoverUrl : movie.wideCoverUrl,
        imageKey: Key('$keyPrefix-cover-${movie.id}'),
        width: width,
        height: height,
        fit: mobile
            ? (movie.usesThinCover ? BoxFit.cover : BoxFit.contain)
            : (movie.hasWideCover ? BoxFit.cover : BoxFit.contain),
        placeholderBackground: colors.surfaceMuted,
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  movie.displayHeading,
                  key: Key('$keyPrefix-row-heading-${movie.id}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: resolveAppTextStyle(
                    context,
                    size: AppTextSize.s16,
                    weight: AppTextWeight.semibold,
                    tone: AppTextTone.primary,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: spacing.xs / 2),
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
                SizedBox(height: spacing.sm),
                AppBadge(label: countLabel, tone: AppBadgeTone.neutral),
              ],
            ),
          ),
          if (onOpen != null)
            Icon(
              Icons.chevron_right_rounded,
              color: context.appTextPalette.muted,
            ),
        ],
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.item,
    required this.library,
    required this.keyPrefix,
    required this.deleteLabel,
    required this.selectionLimitReached,
    required this.selectedIds,
    required this.onToggle,
    required this.onDelete,
    required this.itemSupplement,
  });

  final MediaListItemDto item;
  final MediaLibraryDto? library;
  final String keyPrefix;
  final String deleteLabel;
  final bool selectionLimitReached;
  final Set<int>? selectedIds;
  final ValueChanged<MediaListItemDto> onToggle;
  final ValueChanged<MediaListItemDto> onDelete;
  final Widget? itemSupplement;

  bool get _selectable =>
      selectedIds == null ||
      (!selectionLimitReached || selectedIds!.contains(item.id));

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final filenameStyle = resolveAppTextStyle(
      context,
      size: AppTextSize.s14,
      weight: AppTextWeight.medium,
      tone: AppTextTone.primary,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        mouseCursor: _selectable && selectedIds != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        key: Key('$keyPrefix-row-${item.id}'),
        borderRadius: context.appRadius.mdBorder,
        onTap: selectedIds == null || !_selectable
            ? null
            : () => onToggle(item),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: spacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: IgnorePointer(
                  ignoring: selectedIds != null,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectedIds != null) ...[
                        Tooltip(
                          message: selectionLimitReached &&
                                  !selectedIds!.contains(item.id)
                              ? '至少保留一个'
                              : '选择此项',
                          child: Checkbox(
                            key: Key('$keyPrefix-select-${item.id}'),
                            value: selectedIds!.contains(item.id),
                            onChanged:
                                selectionLimitReached &&
                                    !selectedIds!.contains(item.id)
                                ? null
                                : (_) => onToggle(item),
                          ),
                        ),
                        SizedBox(width: spacing.xs),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(
                              item.fileName,
                              key: Key('$keyPrefix-file-${item.id}'),
                              style: filenameStyle,
                            ),
                            SizedBox(height: spacing.xs),
                            Text(
                              buildMediaListItemMetaLabel(
                                item,
                                library: library,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: resolveAppTextStyle(
                                context,
                                size: AppTextSize.s12,
                                tone: AppTextTone.muted,
                              ),
                            ),
                            if (itemSupplement != null) ...[
                              SizedBox(height: spacing.xs),
                              itemSupplement!,
                            ],
                            if (!item.valid) ...[
                              SizedBox(height: spacing.xs),
                              const AppBadge(
                                label: '失效',
                                tone: AppBadgeTone.error,
                                size: AppBadgeSize.compact,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (selectedIds == null) ...[
                SizedBox(width: spacing.sm),
                AppIconButton(
                  key: Key('$keyPrefix-delete-${item.id}'),
                  icon: const Icon(Icons.delete_outline_rounded),
                  iconColor: context.appTextPalette.error,
                  tooltip: deleteLabel,
                  semanticLabel: deleteLabel,
                  onPressed: () => onDelete(item),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
