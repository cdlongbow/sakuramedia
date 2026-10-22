import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/features/movies/data/dto/detail/movie_detail_dto.dart';
import 'package:sakuramedia/l10n/app_localizations.dart';
import 'package:sakuramedia/theme.dart';

class MovieMergePlaybackCandidateList extends StatelessWidget {
  const MovieMergePlaybackCandidateList({
    super.key,
    required this.candidates,
    required this.onSelected,
  });

  final List<MovieMergePlaybackCandidateDto> candidates;
  final ValueChanged<MovieMergePlaybackCandidateDto> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.movieWidgetSelectMergeLibraryTitle,
          style: resolveAppTextStyle(context, size: AppTextSize.s18),
        ),
        SizedBox(height: context.appSpacing.md),
        for (final candidate in candidates)
          ListTile(
            key: Key('movie-merge-playback-library-${candidate.libraryId}'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              candidate.libraryName.trim().isEmpty
                  ? l10n.movieWidgetMediaLibraryFallback(candidate.libraryId)
                  : candidate.libraryName.trim(),
            ),
            subtitle: Text(
              l10n.movieWidgetMediaLibrarySegments(
                candidate.providerKey,
                candidate.segmentCount,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => onSelected(candidate),
          ),
      ],
    );
  }
}
