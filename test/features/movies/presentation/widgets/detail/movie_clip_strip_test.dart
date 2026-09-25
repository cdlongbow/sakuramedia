import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/clips/data/dto/media_clip_dto.dart';
import 'package:sakuramedia/features/movies/presentation/widgets/detail/movie_clip_strip.dart';
import 'package:sakuramedia/theme.dart';

void main() {
  testWidgets('悬停播放键直接播放，不打开动作面板', (WidgetTester tester) async {
    var played = 0;
    var openedActions = 0;

    await _pumpStrip(
      tester,
      onOpenClipActions: (_) => openedActions++,
      onPlayClip: (_) => played++,
    );
    await _hoverCard(tester);

    await tester.tap(find.byKey(const Key('clip-grid-card-play-1')));
    await tester.pumpAndSettle();

    expect(played, 1);
    expect(openedActions, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('点击切片卡打开动作面板，不直接播放', (WidgetTester tester) async {
    var played = 0;
    var openedActions = 0;

    await _pumpStrip(
      tester,
      onOpenClipActions: (_) => openedActions++,
      onPlayClip: (_) => played++,
    );

    await tester.tap(find.byKey(const Key('movie-clip-strip-card-1')));
    await tester.pumpAndSettle();

    expect(openedActions, 1);
    expect(played, 0);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpStrip(
  WidgetTester tester, {
  required ValueChanged<MediaClipDto> onOpenClipActions,
  required ValueChanged<MediaClipDto> onPlayClip,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1100, 760);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: sakuraThemeData,
      home: Scaffold(
        body: MovieClipStrip(
          clips: const <MediaClipDto>[_clip],
          isLoading: false,
          onOpenClipActions: onOpenClipActions,
          onPlayClip: onPlayClip,
          onRenameClip: (_) {},
          onDeleteClip: (_) {},
          onAddClipToCollection: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _hoverCard(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  await tester.pump();
  await mouse.moveTo(
    tester.getCenter(find.byKey(const Key('movie-clip-strip-card-1'))),
  );
  await tester.pump();
}

const MediaClipDto _clip = MediaClipDto(
  clipId: 1,
  mediaId: 9,
  movieNumber: 'ABC-001',
  startOffsetSeconds: 30,
  endOffsetSeconds: 90,
  title: '第一段',
  durationSeconds: 60,
  fileSizeBytes: 1024,
  coverImage: null,
  streamUrl: 'https://api.example.com/clip-1.mp4',
  createdAt: null,
);
