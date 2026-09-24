import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/moments/presentation/pages/shared/moments_content.dart';
import 'package:sakuramedia/routes/app_route_paths.dart';
import 'package:sakuramedia/routes/mobile_routes.dart';

/// 移动概览「时刻」tab 壳：预览关闭后的导航（图搜 / 视频页 / 播放 / 详情）
/// 由共享预览流程 [MomentsContent] 内部按移动分支处理；这里只负责下拉刷新、
/// 底部抽屉筛选、预览抽屉 Key 与合集入口。
class MobileOverviewMomentsTab extends StatelessWidget {
  const MobileOverviewMomentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return MomentsContent(
      keyPrefix: 'mobile-moments',
      rootKey: const Key('mobile-overview-moments-tab'),
      previewFallbackPath: mobileOverviewPath,
      previewDrawerKey: const Key('mobile-moments-preview-bottom-sheet'),
      enablePullToRefresh: true,
      useMobileFilterDrawer: true,
      onOpenCollections: () =>
          const MobileMomentCollectionsRouteData().push(context),
      onOpenCollectionDetail: (collectionId) =>
          MobileMomentCollectionDetailRouteData(
            collectionId: collectionId,
          ).push(context),
    );
  }
}
