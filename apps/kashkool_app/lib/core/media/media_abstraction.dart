library media_abstraction;

import 'package:flutter/foundation.dart';

/// Abstract controller for DRM-protected recorded lectures
abstract class LecturePlayerController {
  Future<void> play(String lectureId, String drmKeyId);
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> dispose();
}

/// Abstract controller for WebRTC live classroom sessions
abstract class LiveRoomController {
  Future<void> join(String roomId, String userId);
  Future<void> leave();
  Future<void> raiseHand();
  Future<void> sendPoll(String question, List<String> options);
  Future<void> toggleVideo(bool enabled);
  Future<void> toggleAudio(bool enabled);
  Future<void> dispose();
}

class DefaultLecturePlayerController implements LecturePlayerController {
  @override
  Future<void> play(String lectureId, String drmKeyId) async {
    // Integrate with ExoPlayer / AVPlayer / DRM SDK here
    debugPrint('Playing DRM lecture: $lectureId with key: $drmKeyId');
  }

  @override
  Future<void> pause() async => debugPrint('Lecture paused');

  @override
  Future<void> stop() async => debugPrint('Lecture stopped');

  @override
  Future<void> seek(Duration position) async => debugPrint('Seeked to: $position');

  @override
  Future<void> dispose() async {}
}

class DefaultLiveRoomController implements LiveRoomController {
  @override
  Future<void> join(String roomId, String userId) async {
    // Integrate with WebRTC / Agora / live streaming here
    debugPrint('Joined live room: $roomId as $userId');
  }

  @override
  Future<void> leave() async => debugPrint('Left live room');

  @override
  Future<void> raiseHand() async => debugPrint('Hand raised');

  @override
  Future<void> sendPoll(String question, List<String> options) async {
    debugPrint('Poll sent: $question with options: $options');
  }

  @override
  Future<void> toggleVideo(bool enabled) async => debugPrint('Video: $enabled');

  @override
  Future<void> toggleAudio(bool enabled) async => debugPrint('Audio: $enabled');

  @override
  Future<void> dispose() async {}
}
