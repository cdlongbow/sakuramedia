import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/playlists/presentation/controllers/playlist_filter_state.dart';

void main() {
  group('PlaylistFilterState', () {
    test('initial is default and keeps null sort/resolution', () {
      const state = PlaylistFilterState.initial;

      expect(state.isDefault, isTrue);
      expect(state.sortField, isNull);
      expect(state.sortDirection, SortDirection.desc);
      expect(state.resolution, isNull);
      expect(state.sortExpression, isNull);
      expect(state.triggerLabel, '全部');
    });

    test('sortExpression renders field:direction only when sortField set', () {
      final state = PlaylistFilterState.initial.copyWith(
        sortField: PlaylistSortField.heat,
      );

      expect(state.sortExpression, 'heat:desc');
      expect(
        state.copyWith(sortDirection: SortDirection.asc).sortExpression,
        'heat:asc',
      );
    });

    test('copyWith clears sortField back to null (sentinel)', () {
      final filtered = PlaylistFilterState.initial.copyWith(
        sortField: PlaylistSortField.bitrate,
      );
      expect(filtered.sortField, PlaylistSortField.bitrate);

      final cleared = filtered.copyWith(sortField: null);
      expect(cleared.sortField, isNull);
      expect(cleared.isDefault, isTrue);
    });

    test('copyWith clears resolution back to null (sentinel)', () {
      final filtered = PlaylistFilterState.initial.copyWith(
        resolution: PlaylistResolutionFilter.k4k,
      );
      expect(filtered.resolution, PlaylistResolutionFilter.k4k);

      final cleared = filtered.copyWith(resolution: null);
      expect(cleared.resolution, isNull);
      expect(cleared.isDefault, isTrue);
    });

    test('triggerLabel: 单维度时报该维度、两维都非默认时用「·」拼合', () {
      expect(
        PlaylistFilterState.initial
            .copyWith(resolution: PlaylistResolutionFilter.k4k)
            .triggerLabel,
        '4K',
      );
      expect(
        PlaylistFilterState.initial
            .copyWith(sortField: PlaylistSortField.addedAt)
            .triggerLabel,
        '最近入库',
      );
      // 分辨率 + 排序同时非默认 → 复合展示，避免只显示分辨率把排序藏了。
      expect(
        PlaylistFilterState.initial
            .copyWith(
              resolution: PlaylistResolutionFilter.k4k,
              sortField: PlaylistSortField.bitrate,
            )
            .triggerLabel,
        '4K · 码率',
      );
    });

    test('matches compares all fields', () {
      const a = PlaylistFilterState.initial;
      const b = PlaylistFilterState.initial;
      final c = a.copyWith(sortField: PlaylistSortField.heat);

      expect(a.matches(b), isTrue);
      expect(a.matches(c), isFalse);
    });
  });

  group('PlaylistResolutionFilter', () {
    test('fromApiValue round-trips known labels and rejects unknown', () {
      for (final filter in PlaylistResolutionFilter.values) {
        expect(
          PlaylistResolutionFilterX.fromApiValue(filter.apiValue),
          filter,
        );
      }
      expect(PlaylistResolutionFilterX.fromApiValue('5K'), isNull);
    });

    test('8K and 4K are distinct buckets', () {
      expect(
        PlaylistResolutionFilter.k8k.apiValue,
        isNot(PlaylistResolutionFilter.k4k.apiValue),
      );
    });
  });
}
