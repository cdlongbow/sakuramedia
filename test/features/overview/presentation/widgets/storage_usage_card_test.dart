import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/features/overview/presentation/widgets/storage_usage_card.dart';
import 'package:sakuramedia/features/status/data/status_dto.dart';
import 'package:sakuramedia/theme.dart';

void main() {
  testWidgets('每个媒体库展示文件数与容量', (WidgetTester tester) async {
    await _pumpCard(
      tester,
      const StorageUsageCard(
        libraries: <MediaLibraryUsageDto>[
          MediaLibraryUsageDto(
            libraryId: 1,
            name: '主媒体库',
            providerKey: 'local',
            fileCount: 1420,
            totalSizeBytes: 6400000000000,
          ),
          MediaLibraryUsageDto(
            libraryId: 2,
            name: '备份库',
            providerKey: 'cloud115',
            fileCount: 700,
            totalSizeBytes: 2300000000000,
          ),
        ],
      ),
    );

    expect(
      find.byKey(const Key('overview-storage-library-1')),
      findsOneWidget,
    );
    expect(find.text('主媒体库'), findsOneWidget);
    expect(find.text('1,420 个文件 · 5.8 TB'), findsOneWidget);
    expect(find.text('700 个文件 · 2.1 TB'), findsOneWidget);
  });

  testWidgets('没有媒体库时展示空文案', (WidgetTester tester) async {
    await _pumpCard(
      tester,
      const StorageUsageCard(libraries: <MediaLibraryUsageDto>[]),
    );

    expect(find.text('暂无媒体库'), findsOneWidget);
  });

  testWidgets('加载失败展示重试', (WidgetTester tester) async {
    var retried = false;
    await _pumpCard(
      tester,
      StorageUsageCard(
        libraries: null,
        errorMessage: '统计数据加载失败',
        onRetry: () => retried = true,
      ),
    );

    expect(find.text('统计数据加载失败'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('overview-storage-usage-retry-button')),
    );
    await tester.pump();
    expect(retried, isTrue);
  });
}

Future<void> _pumpCard(WidgetTester tester, Widget card) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: sakuraThemeData,
      home: Scaffold(body: SingleChildScrollView(child: card)),
    ),
  );
}
