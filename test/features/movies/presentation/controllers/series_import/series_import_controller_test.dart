import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:sakuramedia/features/movies/presentation/providers/series_import_provider.dart';
import 'package:sakuramedia/features/movies/presentation/providers/series_import_state.dart';

import '../../../../../support/test_api_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionStore sessionStore;
  late TestApiBundle bundle;
  late ProviderContainer container;
  late ProviderSubscription<SeriesImportState> subscription;
  late SeriesImport notifier;

  SeriesImportState readState() => container.read(seriesImportProvider(7));

  setUp(() async {
    sessionStore = SessionStore.inMemory();
    await sessionStore.saveBaseUrl('https://api.example.com');
    await sessionStore.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.parse('2026-03-10T12:00:00Z'),
    );
    bundle = await createTestApiBundle(sessionStore);
    container = ProviderContainer(overrides: bundle.riverpodOverrides());
    subscription = container.listen(
      seriesImportProvider(7),
      (_, __) {},
      fireImmediately: true,
    );
    notifier = container.read(seriesImportProvider(7).notifier);
  });

  tearDown(() {
    subscription.close();
    container.dispose();
    bundle.dispose();
  });

  test('completed stream exposes progress, stats and new-movie result', () async {
    bundle.adapter.enqueueSse(
      method: 'POST',
      path: '/movies/series/7/javdb/import/stream',
      chunks: <String>[
        'event: upsert_started\ndata: {"total":2}\n\n',
        'event: movie_upsert_finished\ndata: {"index":1,"total":2}\n\n',
        'event: completed\ndata: {"success":true,"total":2,"created_count":1,"already_exists_count":1,"failed_count":0}\n\n',
      ],
    );

    await notifier.startImport();
    await _settle();

    expect(readState().isRunning, isFalse);
    expect(readState().isCompleted, isTrue);
    expect(readState().hasFailed, isFalse);
    expect(readState().canDismiss, isTrue);
    expect(readState().hasNewMovies, isTrue);
    expect(readState().current, 1);
    expect(readState().total, 2);
    expect(readState().progress, 0.5);
    expect(readState().stats?.createdCount, 1);
  });

  test('completed failure maps the backend reason and can retry', () async {
    const seriesId = 8;
    subscription.close();
    subscription = container.listen(
      seriesImportProvider(seriesId),
      (_, __) {},
      fireImmediately: true,
    );
    notifier = container.read(seriesImportProvider(seriesId).notifier);
    bundle.adapter.enqueueSse(
      method: 'POST',
      path: '/movies/series/8/javdb/import/stream',
      chunks: <String>[
        'event: completed\ndata: {"success":false,"reason":"javdb_series_not_found"}\n\n',
      ],
    );
    await notifier.startImport();
    await _settle();

    expect(container.read(seriesImportProvider(seriesId)).hasFailed, isTrue);
    expect(
      container.read(seriesImportProvider(seriesId)).errorMessage,
      '未能在 JAVDB 找到匹配的系列，请确认系列名称',
    );

    bundle.adapter.enqueueSse(
      method: 'POST',
      path: '/movies/series/8/javdb/import/stream',
      chunks: <String>[
        'event: completed\ndata: {"success":true,"created_count":0}\n\n',
      ],
    );
    await notifier.startImport();
    await _settle();

    final state = container.read(seriesImportProvider(seriesId));
    expect(state.hasFailed, isFalse);
    expect(state.errorMessage, isNull);
    expect(state.isCompleted, isTrue);
  });

  test('stream closing before completed becomes retryable failure', () async {
    const seriesId = 9;
    subscription.close();
    subscription = container.listen(
      seriesImportProvider(seriesId),
      (_, __) {},
      fireImmediately: true,
    );
    notifier = container.read(seriesImportProvider(seriesId).notifier);
    bundle.adapter.enqueueSse(
      method: 'POST',
      path: '/movies/series/9/javdb/import/stream',
      chunks: <String>['event: search_started\ndata: {}\n\n'],
    );

    await notifier.startImport();
    await _settle();

    final state = container.read(seriesImportProvider(seriesId));
    expect(state.isRunning, isFalse);
    expect(state.hasFailed, isTrue);
    expect(state.errorMessage, '连接意外断开，请重试');
  });

  test('busy start is deduplicated and cancel stops the run', () async {
    const seriesId = 10;
    subscription.close();
    subscription = container.listen(
      seriesImportProvider(seriesId),
      (_, __) {},
      fireImmediately: true,
    );
    notifier = container.read(seriesImportProvider(seriesId).notifier);
    bundle.adapter.enqueueSse(
      method: 'POST',
      path: '/movies/series/10/javdb/import/stream',
      chunks: <String>['event: search_started\ndata: {}\n\n'],
      keepOpen: true,
    );

    await notifier.startImport();
    await notifier.startImport();
    await _settle();
    expect(
      bundle.adapter.hitCount('POST', '/movies/series/10/javdb/import/stream'),
      1,
    );
    expect(container.read(seriesImportProvider(seriesId)).isRunning, isTrue);

    await notifier.cancel();

    final state = container.read(seriesImportProvider(seriesId));
    expect(state.isRunning, isFalse);
    expect(state.canDismiss, isFalse);
  });
}

Future<void> _settle() => pumpEventQueue();
