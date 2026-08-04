import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/features/discovery/presentation/pages/shared/discovery_recommendation_content.dart';
import 'package:sakuramedia/features/image_search/presentation/actions/image_search_launcher.dart';
import 'package:sakuramedia/features/moments/presentation/moment_listing_models.dart';
import 'package:sakuramedia/routes/app_navigation.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/domain/moments/moment_image.dart';

/// 移动推荐时刻壳：移动语义（pageSize 18 / surfaceCard 背景 / 下拉刷新 /
/// 预览弹层底部抽屉 + drawerKey）收在壳里，图搜走 draft store 中转，
/// 实现在 [DiscoveryMomentsContent]。
class MobileDiscoverMomentsPage extends StatelessWidget {
  const MobileDiscoverMomentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DiscoveryMomentsContent(
      pageSize: 18,
      keyPrefix: 'mobile-discover-moments',
      headerGap: context.appSpacing.md,
      backgroundColor: context.appColors.surfaceCard,
      basePath: mobileMoviesPath,
      previewDrawerKey: const Key('mobile-discover-moments-preview-bottom-sheet'),
      enablePullToRefresh: true,
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
  try {
    await launchImageSearchFromUrl(
      context,
      imageUrl: imageUrl,
      routePath: mobileImageSearchPath,
      fallbackPath: mobileOverviewPath,
      fileName: buildMomentImageFileName(item, imageUrl),
    );
  } catch (_) {
    if (context.mounted) {
      showToast('读取结果图片失败，请稍后重试');
    }
  }
}
