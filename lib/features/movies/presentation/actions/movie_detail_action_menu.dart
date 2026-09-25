import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_detail_dto.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/overlays/app_action_menu.dart';

enum MovieDetailActionType {
  openInspector,
  toggleSubscription,
  toggleBlacklist,
  refreshMetadata,
  recomputeHeat,
}

class MovieDetailActionDescriptor {
  const MovieDetailActionDescriptor({
    required this.type,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.tone = AppTextTone.primary,
  });

  final MovieDetailActionType type;
  final String label;
  final IconData icon;
  final bool enabled;
  final AppTextTone tone;
}

List<MovieDetailActionDescriptor> buildMovieDetailActionDescriptors({
  required MovieDetailDto movie,
  required bool isSubscribed,
  required bool isBlacklisted,
}) {
  return <MovieDetailActionDescriptor>[
    const MovieDetailActionDescriptor(
      type: MovieDetailActionType.openInspector,
      label: '更多信息',
      icon: Icons.info_outline_rounded,
    ),
    if (!isBlacklisted)
      MovieDetailActionDescriptor(
        type: MovieDetailActionType.toggleSubscription,
        label: isSubscribed ? '取消订阅' : '订阅影片',
        icon: isSubscribed
            ? Icons.favorite_border_rounded
            : Icons.favorite_rounded,
        tone: isSubscribed ? AppTextTone.error : AppTextTone.primary,
      ),
    if (isBlacklisted || !isSubscribed)
      MovieDetailActionDescriptor(
        type: MovieDetailActionType.toggleBlacklist,
        label: isBlacklisted ? '取消屏蔽' : '屏蔽影片',
        icon: isBlacklisted ? Icons.undo_rounded : Icons.block_rounded,
        tone: isBlacklisted ? AppTextTone.primary : AppTextTone.error,
      ),
    const MovieDetailActionDescriptor(
      type: MovieDetailActionType.refreshMetadata,
      label: '刷新元数据',
      icon: Icons.sync_rounded,
    ),
    const MovieDetailActionDescriptor(
      type: MovieDetailActionType.recomputeHeat,
      label: '计算热度',
      icon: Icons.local_fire_department_outlined,
    ),
  ];
}

List<AppMenuItem<MovieDetailActionType>> buildMovieDetailActionMenuItems(
  List<MovieDetailActionDescriptor> actions,
) {
  return <AppMenuItem<MovieDetailActionType>>[
    for (final action in actions)
      AppMenuItem(
        key: Key('movie-detail-hero-action-${action.type.name}'),
        value: action.type,
        label: action.label,
        icon: action.icon,
        tone: action.tone,
        enabled: action.enabled,
      ),
  ];
}

Future<MovieDetailActionType?> showMovieDetailDesktopActionMenu({
  required BuildContext context,
  required Offset globalPosition,
  required List<MovieDetailActionDescriptor> actions,
}) {
  return showAppActionMenu<MovieDetailActionType>(
    context: context,
    globalPosition: globalPosition,
    presentation: AppMenuPresentation.popup,
    items: buildMovieDetailActionMenuItems(actions),
  );
}

Future<MovieDetailActionType?> showMovieDetailMobileActionDrawer({
  required BuildContext context,
  required List<MovieDetailActionDescriptor> actions,
}) {
  return showAppActionMenu<MovieDetailActionType>(
    context: context,
    presentation: AppMenuPresentation.bottomDrawer,
    title: '影片操作',
    items: buildMovieDetailActionMenuItems(actions),
  );
}
