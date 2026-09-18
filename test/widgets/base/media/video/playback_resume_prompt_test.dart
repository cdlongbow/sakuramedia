import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/theme.dart';
import 'package:sakuramedia/widgets/base/media/video/playback_resume_prompt.dart';

void main() {
  Widget buildSubject({
    required VoidCallback onResume,
    required VoidCallback onStartOver,
    Duration timeout = defaultPlaybackResumePromptTimeout,
  }) {
    return MaterialApp(
      theme: sakuraThemeData,
      home: Scaffold(
        body: Center(
          child: PlaybackResumePrompt(
            position: const Duration(minutes: 12, seconds: 34),
            autoDismissAfter: timeout,
            onResume: onResume,
            onStartOver: onStartOver,
          ),
        ),
      ),
    );
  }

  testWidgets('shows history time and resumes only after confirmation', (
    tester,
  ) async {
    var resumeCount = 0;
    var startOverCount = 0;
    await tester.pumpWidget(
      buildSubject(
        onResume: () => resumeCount++,
        onStartOver: () => startOverCount++,
      ),
    );

    expect(find.text('上次看到 12:34'), findsOneWidget);
    expect(find.byKey(const Key('playback-resume-prompt')), findsOneWidget);

    await tester.tap(find.byKey(const Key('playback-resume-continue-label')));
    await tester.pump();

    expect(resumeCount, 1);
    expect(startOverCount, 0);
  });

  testWidgets('start-over action resolves without resuming', (tester) async {
    var resumeCount = 0;
    var startOverCount = 0;
    await tester.pumpWidget(
      buildSubject(
        onResume: () => resumeCount++,
        onStartOver: () => startOverCount++,
      ),
    );

    await tester.tap(find.byKey(const Key('playback-resume-start-over-label')));
    await tester.pump();

    expect(resumeCount, 0);
    expect(startOverCount, 1);
  });

  testWidgets('timeout keeps playback at the beginning', (tester) async {
    var startOverCount = 0;
    await tester.pumpWidget(
      buildSubject(
        timeout: const Duration(seconds: 2),
        onResume: () {},
        onStartOver: () => startOverCount++,
      ),
    );

    await tester.pump(const Duration(seconds: 2));

    expect(startOverCount, 1);
  });

  testWidgets('overlay anchors the prompt to the bottom-left on touch widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: sakuraMobileThemeData,
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF000000)),
              PlaybackResumePromptOverlay(
                position: const Duration(minutes: 12, seconds: 34),
                onResume: () {},
                onStartOver: () {},
              ),
            ],
          ),
        ),
      ),
    );

    final promptRect = tester.getRect(
      find.byKey(const Key('playback-resume-prompt')),
    );
    const overlayTokens = AppOverlayTokens.defaults();
    expect(promptRect.left, overlayTokens.playerControlBarHorizontalInset);
    expect(
      promptRect.bottom,
      844 - overlayTokens.playerSeekBarBottomInset - AppSpacing.defaults().xl,
    );
    expect(tester.takeException(), isNull);
  });
}
