import 'package:material_ui/material_ui.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/actors/data/api/actors_api.dart';
import 'package:sakuramedia/features/movies/data/api/movies_api.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_detail_dto.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_actor_picker_sheet.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_actor_wrap.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_detail_section.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/actions/app_text_button.dart';

/// 影片详情页的演员区块：浏览态只读，进入管理态后可就地移除，并通过弹层添加。
class MovieActorSection extends StatefulWidget {
  const MovieActorSection({
    super.key,
    required this.movieNumber,
    required this.actors,
    this.isActorsManuallyManaged = false,
    this.onActorTap,
    this.moviesApi,
    this.actorsApi,
    this.onActorsChanged,
  });

  final String movieNumber;
  final List<MovieActorDto> actors;
  final bool isActorsManuallyManaged;
  final ValueChanged<MovieActorDto>? onActorTap;

  /// 三个依赖同时存在时才开放编辑；只读上下文（如纯组件测试）不显示入口。
  final MoviesApi? moviesApi;
  final ActorsApi? actorsApi;
  final Future<void> Function()? onActorsChanged;

  @override
  State<MovieActorSection> createState() => _MovieActorSectionState();
}

class _MovieActorSectionState extends State<MovieActorSection> {
  bool _isEditing = false;
  bool _isAdding = false;
  final Set<int> _removingActorIds = <int>{};

  bool get _canManage =>
      widget.moviesApi != null &&
      widget.actorsApi != null &&
      widget.onActorsChanged != null;

  Future<void> _openPicker() async {
    final actorsApi = widget.actorsApi;
    final moviesApi = widget.moviesApi;
    if (!_canManage || actorsApi == null || moviesApi == null || _isAdding) {
      return;
    }
    final selected = await showMovieActorPickerSheet(
      context,
      actorsApi: actorsApi,
      existingActorIds: widget.actors.map((actor) => actor.id).toSet(),
    );
    if (!mounted || selected == null || selected.isEmpty) return;

    setState(() => _isAdding = true);
    var added = 0;
    var failed = 0;
    for (final actor in selected) {
      try {
        await moviesApi.addMovieActor(
          movieNumber: widget.movieNumber,
          actorId: actor.id,
        );
        added++;
      } catch (_) {
        failed++;
      }
    }

    final refreshed = await _notifyActorsChanged();
    if (!mounted) return;
    setState(() => _isAdding = false);
    if (added == 0) {
      showToast('添加演员失败，请稍后重试');
    } else if (failed > 0) {
      showToast('已添加 $added 位演员，$failed 位添加失败');
    } else if (!refreshed) {
      showToast('已添加 $added 位演员，列表刷新失败');
    } else if (added == 1) {
      showToast('已添加 ${selected.single.displayName}');
    } else {
      showToast('已添加 $added 位演员');
    }
  }

  Future<void> _removeActor(MovieActorDto actor) async {
    final moviesApi = widget.moviesApi;
    if (!_canManage || moviesApi == null) return;
    if (_removingActorIds.contains(actor.id)) return;

    setState(() => _removingActorIds.add(actor.id));
    try {
      await moviesApi.removeMovieActor(
        movieNumber: widget.movieNumber,
        actorId: actor.id,
      );
      final refreshed = await _notifyActorsChanged();
      if (!mounted) return;
      showToast(
        refreshed
            ? '已从演员表移除 ${actor.displayName}'
            : '已移除 ${actor.displayName}，列表刷新失败',
      );
    } catch (error) {
      if (mounted) {
        showToast(apiErrorMessage(error, fallback: '移除演员失败，请稍后重试'));
      }
    } finally {
      if (mounted) {
        setState(() => _removingActorIds.remove(actor.id));
      }
    }
  }

  Future<bool> _notifyActorsChanged() async {
    final onActorsChanged = widget.onActorsChanged;
    if (onActorsChanged == null) return false;
    try {
      await onActorsChanged();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canManage && widget.actors.isEmpty) {
      return const SizedBox.shrink();
    }
    final spacing = context.appSpacing;
    final editing = _isEditing && _canManage;
    return MovieDetailSection(
      title: '演员',
      titleKey: const Key('movie-actors-title'),
      trailing: _canManage ? _buildHeaderAction(context, editing) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MovieActorWrap(
            actors: widget.actors,
            onActorTap: editing ? null : widget.onActorTap,
            editing: editing,
            onRemoveTap: _removeActor,
            removingActorIds: _removingActorIds,
            trailing: editing
                ? _AddActorTile(
                    isLoading: _isAdding,
                    onTap: _isAdding ? null : _openPicker,
                  )
                : null,
          ),
          if (widget.isActorsManuallyManaged) ...[
            SizedBox(height: spacing.sm),
            _SectionHint(
              key: const Key('movie-actors-manual-notice'),
              text: editing ? '移除只影响本片，不会删除女优资料。' : '演员表已手动管理，刷新元数据不会覆盖。',
            ),
          ] else if (editing) ...[
            SizedBox(height: spacing.sm),
            const _SectionHint(
              key: Key('movie-actors-edit-hint'),
              text: '移除只影响本片；增删后将改为手动管理，刷新元数据不再覆盖。',
            ),
          ] else if (widget.actors.isEmpty) ...[
            SizedBox(height: spacing.sm),
            const _SectionHint(
              key: Key('movie-actors-empty-hint'),
              text: '添加后将改为手动管理，刷新元数据不再覆盖。',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderAction(BuildContext context, bool editing) {
    if (editing) {
      return AppTextButton(
        key: const Key('movie-actors-finish-button'),
        label: '完成',
        size: AppTextButtonSize.xSmall,
        onPressed: () => setState(() => _isEditing = false),
      );
    }
    if (widget.actors.isEmpty) {
      return AppTextButton(
        key: const Key('movie-actors-add-button'),
        label: '添加演员',
        size: AppTextButtonSize.xSmall,
        emphasis: AppTextButtonEmphasis.accent,
        isLoading: _isAdding,
        onPressed: _isAdding ? null : _openPicker,
      );
    }
    return AppTextButton(
      key: const Key('movie-actors-manage-button'),
      label: '管理',
      size: AppTextButtonSize.xSmall,
      onPressed: () => setState(() => _isEditing = true),
    );
  }
}

class _SectionHint extends StatelessWidget {
  const _SectionHint({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: context.appSpacing.xs,
      runSpacing: context.appSpacing.xs,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: context.appComponentTokens.iconSizeXs,
          color: context.appTextPalette.muted,
        ),
        Text(
          text,
          style: resolveAppTextStyle(
            context,
            size: AppTextSize.s12,
            tone: AppTextTone.muted,
          ),
        ),
      ],
    );
  }
}

class _AddActorTile extends StatelessWidget {
  const _AddActorTile({required this.isLoading, this.onTap});

  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final tokens = context.appComponentTokens;
    final tile = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: tokens.movieDetailActorAvatarSize,
          height: tokens.movieDetailActorAvatarSize,
          decoration: BoxDecoration(
            color: context.appColors.surfaceMuted,
            shape: BoxShape.circle,
            border: Border.all(color: context.appColors.borderSubtle),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: tokens.iconSizeSm,
                    height: tokens.iconSizeSm,
                    child: CircularProgressIndicator.adaptive(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color?>(
                        context.appTextPalette.secondary,
                      ),
                    ),
                  )
                : Icon(
                    Icons.person_add_alt_1_rounded,
                    size: tokens.iconSizeSm,
                    color: context.appTextPalette.secondary,
                  ),
          ),
        ),
        SizedBox(height: spacing.sm),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: tokens.movieDetailActorCardWidth,
          ),
          child: Text(
            '添加',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: resolveAppTextStyle(
              context,
              size: AppTextSize.s12,
              tone: AppTextTone.secondary,
            ),
          ),
        ),
      ],
    );

    final content = KeyedSubtree(
      key: const Key('movie-actor-add-tile'),
      child: tile,
    );
    if (onTap == null) {
      return Tooltip(message: '添加演员', child: content);
    }
    return Tooltip(
      message: '添加演员',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }
}
