import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakuramedia/widgets/base/media/video/mpv_video_quality_settings.dart';
import 'package:sakuramedia/widgets/domain/movies/player/movie_player_quality_coordinator.dart';

class _QualityHarness {
  _QualityHarness({this.playing = true});

  bool playing;
  bool failCapture = false;
  Completer<void>? captureGate;
  Uint8List? frame = Uint8List.fromList(const <int>[1, 2, 3]);
  final List<String> calls = <String>[];
  final Map<String, String> written = <String, String>{};
  final Map<String, String> properties = <String, String>{
    'deband': 'no',
    'cscale': 'bilinear',
  };
  int notifications = 0;

  late final MoviePlayerQualityCoordinator coordinator =
      MoviePlayerQualityCoordinator(
        isPlaying: () => playing,
        pause: () async {
          calls.add('pause');
          playing = false;
        },
        play: () async {
          calls.add('play');
          playing = true;
        },
        captureFrame: () async {
          calls.add('capture');
          await captureGate?.future;
          if (failCapture) {
            throw StateError('screenshot unavailable');
          }
          return frame;
        },
        readProperty: (key) async => properties[key],
        writeProperty: (key, value) async {
          written[key] = value;
        },
      )..addListener(() => notifications++);
}

void main() {
  group('MoviePlayerQualityCoordinator', () {
    test('enable pauses, captures a frame and writes enhancements', () async {
      final harness = _QualityHarness();
      addTearDown(harness.coordinator.dispose);

      await harness.coordinator.toggle();

      expect(harness.coordinator.enabled, isTrue);
      expect(harness.coordinator.originalFrame, harness.frame);
      expect(harness.calls, <String>['pause', 'capture']);
      expect(harness.written, MpvVideoQualitySettings.enhancements);
      // 一次是立即反馈，一次是原始帧就绪。
      expect(harness.notifications, 2);
    });

    test('enable flips the switch before the frame is captured', () async {
      final harness = _QualityHarness()..captureGate = Completer<void>();
      addTearDown(harness.coordinator.dispose);

      final pending = harness.coordinator.toggle();
      await Future<void>.delayed(Duration.zero);

      expect(harness.coordinator.enabled, isTrue);
      expect(harness.coordinator.value, isTrue);
      expect(harness.coordinator.originalFrame, isNull);

      harness.captureGate!.complete();
      await pending;

      expect(harness.coordinator.originalFrame, harness.frame);
    });

    test('disabling mid-flight discards the pending enable', () async {
      final harness = _QualityHarness()..captureGate = Completer<void>();
      addTearDown(harness.coordinator.dispose);

      final pending = harness.coordinator.toggle();
      await Future<void>.delayed(Duration.zero);
      final disabling = harness.coordinator.toggle();
      harness.captureGate!.complete();
      await Future.wait(<Future<void>>[pending, disabling]);

      expect(harness.coordinator.enabled, isFalse);
      expect(harness.coordinator.originalFrame, isNull);
      expect(harness.playing, isTrue);
    });

    test('finishComparison clears the frame and resumes playback', () async {
      final harness = _QualityHarness();
      addTearDown(harness.coordinator.dispose);
      await harness.coordinator.toggle();

      await harness.coordinator.finishComparison();

      expect(harness.coordinator.originalFrame, isNull);
      expect(harness.coordinator.enabled, isTrue);
      expect(harness.calls, <String>['pause', 'capture', 'play']);
      expect(harness.notifications, 3);
    });

    test('paused playback stays paused through the comparison', () async {
      final harness = _QualityHarness(playing: false);
      addTearDown(harness.coordinator.dispose);

      await harness.coordinator.toggle();
      await harness.coordinator.finishComparison();

      expect(harness.calls, <String>['capture']);
      expect(harness.coordinator.enabled, isTrue);
    });

    test('a failed capture skips the comparison and resumes at once', () async {
      final harness = _QualityHarness()..failCapture = true;
      addTearDown(harness.coordinator.dispose);

      await harness.coordinator.toggle();

      expect(harness.coordinator.enabled, isTrue);
      expect(harness.coordinator.originalFrame, isNull);
      expect(harness.calls, <String>['pause', 'capture', 'play']);
      expect(harness.written, MpvVideoQualitySettings.enhancements);
    });

    test('disable restores previous values and resumes playback', () async {
      final harness = _QualityHarness();
      addTearDown(harness.coordinator.dispose);
      await harness.coordinator.toggle();
      harness.written.clear();

      await harness.coordinator.toggle();

      expect(harness.coordinator.enabled, isFalse);
      expect(harness.coordinator.originalFrame, isNull);
      expect(harness.written['deband'], 'no');
      expect(harness.written['cscale'], 'bilinear');
      expect(
        harness.written['sharpen'],
        MpvVideoQualitySettings.neutralValues['sharpen'],
      );
      expect(harness.calls, <String>['pause', 'capture', 'play']);
    });

    test('disable during the comparison resumes playback only once', () async {
      final harness = _QualityHarness();
      addTearDown(harness.coordinator.dispose);
      await harness.coordinator.toggle();

      await harness.coordinator.toggle();
      await harness.coordinator.finishComparison();

      expect(harness.coordinator.enabled, isFalse);
      expect(harness.coordinator.originalFrame, isNull);
      expect(harness.calls, <String>['pause', 'capture', 'play']);
      expect(harness.playing, isTrue);
    });
  });
}
