import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakuramedia/core/session/providers/session_store_provider.dart';
import 'package:sakuramedia/features/cast/data/cast_remote_controller.dart';
import 'package:sakuramedia/features/cast/data/cast_transport.dart';
import 'package:sakuramedia/features/cast/presentation/pages/cast_remote_page.dart';
import 'package:sakuramedia/features/cast/presentation/providers/cast_remote_thumbnails_provider.dart';
import 'package:sakuramedia/features/cast/presentation/providers/cast_session_provider.dart';
import 'package:sakuramedia/features/movies/data/dto/listing/movie_list_item_dto.dart';
import 'package:sakuramedia/features/movies/data/dto/thumbnails/movie_media_thumbnail_dto.dart';
import 'package:sakuramedia/theme.dart';

import '../../support/cast_test_helpers.dart';
import '../../support/logged_in_session_store.dart';

MovieMediaThumbnailDto _thumbnail({
  required int id,
  required int offsetSeconds,
}) {
  return MovieMediaThumbnailDto(
    thumbnailId: id,
    mediaId: 7,
    offsetSeconds: offsetSeconds,
    image: MovieImageDto(id: id, origin: '/media/thumb/$id'),
  );
}

Future<ProviderContainer> _pumpPage(
  WidgetTester tester, {
  required FakeCastTransport transport,
  bool withSession = true,
  List<MovieMediaThumbnailDto> thumbnails = const <MovieMediaThumbnailDto>[],
}) async {
  final sessionStore = await buildLoggedInSessionStore();
  addTearDown(sessionStore.dispose);
  final container = ProviderContainer(
    overrides: [
      sessionStoreProvider.overrideWithValue(sessionStore),
      castRemoteThumbnailsProvider(
        mediaId: 7,
      ).overrideWith((ref) => Future.value(thumbnails)),
    ],
  );
  addTearDown(container.dispose);
  if (withSession) {
    container
        .read(castSessionControllerProvider.notifier)
        .start(buildTestCastSession());
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: sakuraMobileThemeData,
        home: CastRemotePage(
          controllerFactory: (session) => CastRemoteController(
            session: session,
            transport: transport,
            reportProgress:
                ({required int mediaId, required int positionSeconds}) async {},
            pollInterval: const Duration(milliseconds: 200),
            seekDebounce: const Duration(milliseconds: 40),
            seekCooldown: const Duration(milliseconds: 120),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  testWidgets('播放中展示设备名、时间与断开入口', (tester) async {
    final transport = FakeCastTransport()
      ..position = const CastPositionInfo(position: Duration(seconds: 10));
    await _pumpPage(tester, transport: transport);

    expect(find.text('投屏到「测试电视」'), findsOneWidget);
    expect(find.text('00:10 / 01:00:00'), findsOneWidget);
    expect(find.text('断开'), findsOneWidget);
    expect(find.byKey(const Key('cast-remote-play-pause')), findsOneWidget);
  });

  testWidgets('快进快退按 10 秒步长下发 seek', (tester) async {
    final transport = FakeCastTransport()
      ..position = const CastPositionInfo(position: Duration(seconds: 30));
    await _pumpPage(tester, transport: transport);

    await tester.tap(find.byKey(const Key('cast-remote-forward-10')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(transport.seeks, contains(const Duration(seconds: 40)));

    await tester.tap(find.byKey(const Key('cast-remote-back-10')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(transport.seeks, contains(const Duration(seconds: 30)));
  });

  testWidgets('暂停下发 pause 并切换为播放图标', (tester) async {
    final transport = FakeCastTransport();
    await _pumpPage(tester, transport: transport);

    await tester.tap(find.byKey(const Key('cast-remote-play-pause')));
    await tester.pump();

    expect(transport.calls, contains('pause'));
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });

  testWidgets('点击缩略图跳到对应时间点', (tester) async {
    final transport = FakeCastTransport();
    await _pumpPage(
      tester,
      transport: transport,
      thumbnails: [
        _thumbnail(id: 1, offsetSeconds: 0),
        _thumbnail(id: 2, offsetSeconds: 120),
        _thumbnail(id: 3, offsetSeconds: 240),
      ],
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('movie-player-thumb-1')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(transport.seeks, contains(const Duration(seconds: 120)));
  });

  testWidgets('连续轮询失败展示断开提示，重试后恢复', (tester) async {
    final transport = FakeCastTransport()..failure = Exception('offline');
    await _pumpPage(tester, transport: transport);

    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text('与电视的连接已断开'), findsOneWidget);
    expect(find.byKey(const Key('cast-remote-retry')), findsOneWidget);

    transport.failure = null;
    await tester.tap(find.byKey(const Key('cast-remote-retry')));
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('与电视的连接已断开'), findsNothing);
  });

  testWidgets('无会话时展示投屏已结束空态', (tester) async {
    await _pumpPage(
      tester,
      transport: FakeCastTransport(),
      withSession: false,
    );

    expect(find.text('投屏已结束'), findsOneWidget);
  });
}
