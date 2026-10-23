import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/playlists/presentation/controllers/playlist_filter_state.dart';
import 'package:sakuramedia/features/playlists/presentation/widgets/playlist_filter_sections.dart';
import 'package:sakuramedia/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSections(
    WidgetTester tester, {
    PlaylistFilterState filterState = PlaylistFilterState.initial,
    required ValueChanged<PlaylistFilterState> onChanged,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: sakuraThemeData,
        home: Material(
          child: SingleChildScrollView(
            child: PlaylistFilterSectionGroup(
              filterState: filterState,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('固定展示全部分辨率档位', (tester) async {
    await pumpSections(tester, onChanged: (_) {});
    for (final label in [
      '全部',
      '8K',
      '4K',
      '2K',
      '1080P',
      '720P',
      '480P',
      '360P',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('点击分辨率 chip 回传对应档位，点击全部回传 null', (tester) async {
    final resolutions = <PlaylistResolutionFilter?>[];
    await pumpSections(
      tester,
      onChanged: (state) => resolutions.add(state.resolution),
    );

    await tester.tap(find.byKey(const Key('playlist-filter-resolution-4K')));
    await tester.tap(find.byKey(const Key('playlist-filter-resolution-all')));

    expect(resolutions, <PlaylistResolutionFilter?>[
      PlaylistResolutionFilter.k4k,
      null,
    ]);
  });
}
