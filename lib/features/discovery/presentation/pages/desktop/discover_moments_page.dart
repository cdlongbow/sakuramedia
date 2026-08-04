import 'package:flutter/material.dart';
import 'package:sakuramedia/features/discovery/presentation/pages/shared/discovery_recommendation_content.dart';
import 'package:sakuramedia/features/image_search/presentation/actions/image_search_launcher.dart';
import 'package:sakuramedia/features/moments/presentation/moment_listing_models.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/domain/moments/moment_image.dart';

/// 桌面推荐时刻壳：桌面语义（pageSize 24 / surfaceElevated 背景 / 无下拉刷新 /
/// 预览弹层落对话框、无 drawerKey）收在壳里，图搜走桌面 launcher，
/// 实现在 [DiscoveryMomentsContent]。
class DesktopDiscoverMomentsPage extends StatelessWidget {
  const DesktopDiscoverMomentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DiscoveryMomentsContent(
      pageSize: 24,
      keyPrefix: 'desktop-discover-moments',
      headerGap: context.appSpacing.lg,
      backgroundColor: context.appColors.surfaceElevated,
      basePath: desktopMoviesPath,
      onSearchSimilar: (context, item) => _searchSimilarFromMoment(
        context,
        item,
      ),
    );
  }
}

Future<void> _searchSimilarFromMoment(
  BuildContext context,
  MomentListItem item,
) async {
  final imageUrl = resolveMomentImageUrl(item);
  if (imageUrl.isEmpty) {
    return;
  }
  await launchDesktopImageSearchFromUrl(
    context,
    imageUrl: imageUrl,
    fallbackPath: desktopDiscoverMomentsPath,
    fileName: buildMomentImageFileName(item, imageUrl),
  );
}
