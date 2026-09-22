import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;
import 'package:sakuramedia/features/movies/presentation/providers/movie_detail_magnet_provider.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/overlays/app_adaptive_modal.dart';
import 'package:sakuramedia/widgets/domain/movies/movie_magnet_search_content.dart';

/// 磁力搜索弹窗。壳由 [showAppAdaptiveModal] 分流：桌面 [AppDesktopDialog]，
/// 移动底部抽屉；内容 [MovieMagnetSearchContent] 两端共用。
Future<void> showMovieMagnetSearchDialog({
  required BuildContext context,
  required String movieNumber,
}) {
  return showAppAdaptiveModal<void>(
    context: context,
    modalKey: const Key('movie-magnet-search-dialog'),
    desktopWidth: context.appComponentTokens.movieDetailDialogWidth,
    desktopHeight: context.appComponentTokens.movieDetailDialogMinHeight,
    builder: (_) => _MovieMagnetSearchDialogBody(movieNumber: movieNumber),
  );
}

class _MovieMagnetSearchDialogBody extends ConsumerStatefulWidget {
  const _MovieMagnetSearchDialogBody({required this.movieNumber});

  final String movieNumber;

  @override
  ConsumerState<_MovieMagnetSearchDialogBody> createState() =>
      _MovieMagnetSearchDialogBodyState();
}

class _MovieMagnetSearchDialogBodyState
    extends ConsumerState<_MovieMagnetSearchDialogBody> {
  KeepAliveLink? _cacheLink;

  @override
  void initState() {
    super.initState();
    _cacheLink = ref
        .read(movieDetailMagnetProvider(widget.movieNumber).notifier)
        .cacheLink;
  }

  @override
  void dispose() {
    _cacheLink?.close();
    _cacheLink = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(
            end: context.appComponentTokens.buttonHeightMd,
          ),
          child: Text(
            '磁力搜索',
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s18,
              weight: AppTextWeight.semibold,
              tone: AppTextTone.primary,
            ),
          ),
        ),
        SizedBox(height: context.appSpacing.md),
        Expanded(
          child: MovieMagnetSearchContent(movieNumber: widget.movieNumber),
        ),
      ],
    );
  }
}
