import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/core/session/providers/session_store_provider.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/thumbnails/movie_media_thumbnail_dto.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/media/images/masked_image.dart';
import 'package:sakuramedia/widgets/domain/movies/player/movie_player_seek_bar_preview.dart';

const _seekBarKey = Key('test-seek-bar');

List<MovieMediaThumbnailDto> _thumbnails({int count = 101}) {
  return <MovieMediaThumbnailDto>[
    for (var index = 0; index < count; index++)
      MovieMediaThumbnailDto(
        thumbnailId: index + 1,
        mediaId: 1,
        offsetSeconds: index * 10,
        image: MovieImageDto(id: index + 1, origin: '/thumb-$index.webp'),
        width: 1920,
        height: 1080,
      ),
  ];
}

Future<void> _pumpPreview(
  WidgetTester tester, {
  required List<MovieMediaThumbnailDto> thumbnails,
  Duration duration = const Duration(seconds: 1000),
}) async {
  final sessionStore = SessionStore.inMemory();
  await sessionStore.saveBaseUrl('https://api.example.com');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sessionStoreProvider.overrideWithValue(sessionStore)],
      child: MaterialApp(
        theme: sakuraThemeData,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 600,
              child: MoviePlayerSeekBarPreview(
                thumbnails: thumbnails,
                readDuration: () => duration,
                seekBar: const SizedBox(
                  key: _seekBarKey,
                  width: double.infinity,
                  height: 36,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('preview appears after hovering the seek bar', (
    WidgetTester tester,
  ) async {
    await _pumpPreview(tester, thumbnails: _thumbnails());
    final barRect = tester.getRect(find.byKey(_seekBarKey));

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    await mouse.moveTo(barRect.center);
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.byType(MaskedImage), findsOneWidget);
    expect(find.text('08:20'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await mouse.removePointer();
  });

  testWidgets('preview switches when the cursor crosses a frame boundary', (
    WidgetTester tester,
  ) async {
    await _pumpPreview(tester, thumbnails: _thumbnails());
    final barRect = tester.getRect(find.byKey(_seekBarKey));

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    await mouse.moveTo(barRect.center);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('08:20'), findsOneWidget);

    await mouse.moveTo(
      Offset(barRect.left + barRect.width * 0.8, barRect.center.dy),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('13:20'), findsOneWidget);
    expect(find.text('08:20'), findsNothing);

    await mouse.removePointer();
  });

  testWidgets('preview waits out the switch delay before showing', (
    WidgetTester tester,
  ) async {
    await _pumpPreview(tester, thumbnails: _thumbnails());
    final barRect = tester.getRect(find.byKey(_seekBarKey));

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    await mouse.moveTo(
      Offset(barRect.left + barRect.width * 0.2, barRect.center.dy),
    );
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(MaskedImage), findsNothing);

    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('03:20'), findsOneWidget);

    await mouse.removePointer();
  });

  testWidgets('preview hides when the cursor leaves the seek bar', (
    WidgetTester tester,
  ) async {
    await _pumpPreview(tester, thumbnails: _thumbnails());
    final barRect = tester.getRect(find.byKey(_seekBarKey));

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    await mouse.moveTo(barRect.center);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byType(MaskedImage), findsOneWidget);

    await mouse.moveTo(const Offset(5, 5));
    await tester.pump();
    expect(find.byType(MaskedImage), findsNothing);

    await mouse.removePointer();
  });

  testWidgets('preview stays hidden without thumbnails or duration', (
    WidgetTester tester,
  ) async {
    await _pumpPreview(tester, thumbnails: const <MovieMediaThumbnailDto>[]);
    final barRect = tester.getRect(find.byKey(_seekBarKey));

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    await mouse.moveTo(barRect.center);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byType(MaskedImage), findsNothing);

    await mouse.removePointer();
  });
}
