import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/core/format/file_size.dart';
import 'package:sakuramedia/features/overview/presentation/overview_system_info_format.dart';
import 'package:sakuramedia/features/overview/presentation/widgets/overview_card_states.dart';
import 'package:sakuramedia/features/status/data/status_dto.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/layout/cards/app_content_card.dart';

/// 存储分布卡：各媒体库的文件数与容量占比。
class StorageUsageCard extends StatelessWidget {
  const StorageUsageCard({
    super.key,
    required this.libraries,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  final List<MediaLibraryUsageDto>? libraries;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppContentCard(
      key: const Key('overview-storage-usage-card'),
      title: '存储分布',
      headerBottomSpacing: context.appSpacing.lg,
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return const OverviewCardLoadingBars(rows: 4);
    }
    if (errorMessage != null) {
      return OverviewCardErrorRow(
        message: errorMessage!,
        onRetry: onRetry,
        retryKey: const Key('overview-storage-usage-retry-button'),
      );
    }

    final items = libraries ?? const <MediaLibraryUsageDto>[];
    if (items.isEmpty) {
      return Text(
        '暂无媒体库',
        style: resolveAppTextStyle(
          context,
          size: AppTextSize.s12,
          weight: AppTextWeight.regular,
          tone: AppTextTone.muted,
        ),
      );
    }

    final totalBytes = items.fold<int>(
      0,
      (sum, library) => sum + library.totalSizeBytes,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var index = 0; index < items.length; index += 1) ...<Widget>[
          if (index > 0) SizedBox(height: context.appSpacing.lg),
          _StorageUsageRow(
            library: items[index],
            ratio: totalBytes <= 0
                ? 0
                : items[index].totalSizeBytes / totalBytes,
          ),
        ],
      ],
    );
  }
}

class _StorageUsageRow extends StatelessWidget {
  const _StorageUsageRow({required this.library, required this.ratio});

  static const double _barHeight = 6;

  final MediaLibraryUsageDto library;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: Key('overview-storage-library-${library.libraryId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Expanded(
              child: Text(
                library.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: resolveAppTextStyle(
                  context,
                  size: AppTextSize.s14,
                  weight: AppTextWeight.medium,
                  tone: AppTextTone.primary,
                ),
              ),
            ),
            SizedBox(width: context.appSpacing.md),
            Text(
              '${formatCount(library.fileCount)} 个文件 · ${formatFileSize(library.totalSizeBytes)}',
              style: resolveAppTextStyle(
                context,
                size: AppTextSize.s12,
                weight: AppTextWeight.regular,
                tone: AppTextTone.secondary,
              ),
            ),
          ],
        ),
        SizedBox(height: context.appSpacing.sm),
        ClipRRect(
          borderRadius: context.appRadius.pillBorder,
          child: SizedBox(
            height: _barHeight,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ColoredBox(color: context.appColors.surfaceMuted),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: ratio.clamp(0, 1),
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
