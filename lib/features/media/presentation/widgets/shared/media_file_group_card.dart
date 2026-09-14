import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakuramedia/features/media/data/media_list_item_dto.dart';
import 'package:sakuramedia/features/media/presentation/providers/media_libraries_provider.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_cover_thumbnail.dart';
import 'package:sakuramedia/features/media/presentation/widgets/shared/media_list_item_meta_line.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_button.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_badge.dart';

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
    final tokens = context.appComponentTokens;
    final movie = items.first;
    final selectionLimitReached =
        items.where((item) => selectedIds?.contains(item.id) ?? false).length >=
        items.length - 1;
    final libraries = ref.watch(mediaLibrariesProvider).value?.librariesById;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: context.appRadius.lgBorder,
        border: Border.all(color: context.appColors.borderSubtle),
        boxShadow: context.appShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              mouseCursor: onOpen != null
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              key: headerKey,
              hoverColor: Colors.transparent,
              borderRadius: context.appRadius.mdBorder,
              onTap: onOpen,
              child: Row(
                children: [
                  MediaCoverThumbnail(
                    url: movie.coverImage?.bestAvailableUrl,
                    imageKey: Key('$keyPrefix-cover-${movie.id}'),
                    width: mobile
                        ? tokens.movieDetailPlotThumbnailWidth
                        : tokens.downloadTaskCoverWidth,
                    height: mobile
                        ? tokens.movieDetailPlotThumbnailHeight
                        : tokens.mediaManagementRowHeight,
                    fit: BoxFit.contain,
                    placeholderBackground: context.appColors.surfacePage,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(spacing.lg),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movie.displayHeading,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: resolveAppTextStyle(
                                    context,
                                    size: AppTextSize.s14,
                                    weight: AppTextWeight.semibold,
                                    tone: AppTextTone.primary,
                                  ),
                                ),
                                if (movie.displaySubtitle != null) ...[
                                  SizedBox(height: spacing.sm),
                                  Text(
                                    movie.displaySubtitle!,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: resolveAppTextStyle(
                                      context,
                                      size: AppTextSize.s14,
                                      weight: AppTextWeight.medium,
                                      tone: AppTextTone.primary,
                                    ),
                                  ),
                                ],
                                SizedBox(height: spacing.sm),
                                AppBadge(
                                  label: countLabel,
                                  tone: AppBadgeTone.neutral,
                                ),
                              ],
                            ),
                          ),
                          if (onOpen != null) ...[
                            SizedBox(width: spacing.sm),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: context.appTextPalette.muted,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(spacing.lg, 0, spacing.lg, spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in items) ...[
                  Divider(height: spacing.xl, color: context.appColors.divider),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      mouseCursor:
                          selectedIds != null &&
                              !(selectionLimitReached &&
                                  !selectedIds!.contains(item.id))
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                      key: Key('$keyPrefix-row-${item.id}'),
                      borderRadius: context.appRadius.mdBorder,
                      onTap:
                          selectedIds == null ||
                              (selectionLimitReached &&
                                  !selectedIds!.contains(item.id))
                          ? null
                          : () => onToggle(item),
                      child: IgnorePointer(
                        ignoring: selectedIds != null,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (selectedIds != null) ...[
                              Tooltip(
                                message:
                                    selectionLimitReached &&
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
                              SizedBox(width: spacing.sm),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SelectableText(
                                    item.fileName,
                                    key: Key('$keyPrefix-file-${item.id}'),
                                    style: resolveAppTextStyle(
                                      context,
                                      size: AppTextSize.s14,
                                      weight: AppTextWeight.medium,
                                      tone: AppTextTone.primary,
                                    ),
                                  ),
                                  SizedBox(height: spacing.sm),
                                  MediaListItemMetaLine(
                                    item: item,
                                    library: libraries?[item.libraryId],
                                    spacing: spacing.sm,
                                    runSpacing: spacing.xs,
                                  ),
                                  if (itemSupplement?.call(item)
                                      case final supplement?) ...[
                                    SizedBox(height: spacing.sm),
                                    supplement,
                                  ],
                                  if (!item.valid) ...[
                                    SizedBox(height: spacing.sm),
                                    const AppBadge(
                                      label: '失效',
                                      tone: AppBadgeTone.error,
                                      size: AppBadgeSize.compact,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!mobile && selectedIds == null) ...[
                              SizedBox(width: spacing.lg),
                              _deleteButton(item),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (mobile && selectedIds == null) ...[
                    SizedBox(height: spacing.md),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _deleteButton(item),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deleteButton(MediaListItemDto item) => AppButton(
    key: Key('$keyPrefix-delete-${item.id}'),
    label: deleteLabel,
    size: AppButtonSize.small,
    variant: AppButtonVariant.danger,
    icon: const Icon(Icons.delete_outline_rounded),
    onPressed: () => onDelete(item),
  );
}
