import 'package:coast_audio/src/engine/playhead.dart';
import 'package:music_core/music_core.dart';

class ContextSyncroniser {
  bool hasSynced = false;
  bool isValid = false;
  TimePosition previousBarTime = TimePosition.zero();
  TimeDuration syncInterval = TimeDuration.zero();
  TimePosition lastSourceTimelineTime = TimePosition.zero();

  ContextSyncroniser();

  SyncAndPosition getSyncAction(
      PlayHead sourcePlayHead, PlayHead destPlayHead, double sampleRate) {
    if (!isValid) {
      return SyncAndPosition(SyncAction.none, TimePosition.zero());
    }

    final sourceTimelineTime =
        TimePosition.fromSamples(sourcePlayHead.getPosition(), sampleRate);
    final millisecondsSinceEpoch =
        sourcePlayHead.getLastUserInteractionTime().millisecondsSinceEpoch;
    final sourceLastInteractionTime =
        DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);

    final destTimelineTime =
        TimePosition.fromSamples(destPlayHead.getPosition(), sampleRate);
    final destLoopDuration = TimeDuration.fromSamples(
        destPlayHead.getLoopRange().length, sampleRate);

    return getSyncActionInternal(
      sourceTimelineTime,
      sourcePlayHead.isPlaying(),
      sourceLastInteractionTime,
      destTimelineTime,
      destPlayHead.isLooping(),
      destLoopDuration,
    );
  }

  void reset(TimePosition previousBarTime_, TimeDuration syncInterval_) {
    hasSynced = false;
    previousBarTime = previousBarTime_;
    syncInterval = syncInterval_;
    isValid = true;
  }

  SyncAndPosition getSyncActionInternal(
    TimePosition sourceTimelineTime,
    bool sourceIsPlaying,
    DateTime sourceLastInteractionTime,
    TimePosition destTimelineTime,
    bool destIsLooping,
    TimeDuration destLoopDuration,
  ) {
    lastSourceTimelineTime = sourceTimelineTime;

    if (!hasSynced) {
      final sourceDurationSinceLastBarStart = TimeDuration.fromSeconds(
          (sourceTimelineTime - previousBarTime)
              .inSeconds
              .remainder(syncInterval.inSeconds));
      assert(sourceTimelineTime - previousBarTime >= TimePosition.zero());
      assert(sourceDurationSinceLastBarStart > TimeDuration.zero());

      var newTimelineTime = sourceDurationSinceLastBarStart - syncInterval;

      if (destIsLooping && newTimelineTime < syncInterval.invert()) {
        newTimelineTime = sourceDurationSinceLastBarStart;
      }

      newTimelineTime = TimeDuration.fromSeconds(
          newTimelineTime.inSeconds.remainder(destLoopDuration.inSeconds));
      hasSynced = true;

      return SyncAndPosition(
          SyncAction.rollInToLoop, toPosition(newTimelineTime));
    }

    if (!sourceIsPlaying ||
        (lastSourceTimelineTime.inSeconds - sourceTimelineTime.inSeconds)
                .abs() >
            0.2) {
      final rt = DateTime.now().difference(sourceLastInteractionTime);

      if (!sourceIsPlaying || rt.inSeconds < 0.2) {
        isValid = false;
        return SyncAndPosition(SyncAction.breakSync, TimePosition.zero());
      } else {
        final sourceDurationSinceLastBarStart = TimeDuration.fromSeconds(
            (sourceTimelineTime - previousBarTime).inSeconds %
                syncInterval.inSeconds);
        var newTimelineTime = syncInterval *
                ((destTimelineTime.inSeconds + 0.1) / syncInterval.inSeconds)
                    .floor() +
            sourceDurationSinceLastBarStart;
        newTimelineTime = TimeDuration.fromSeconds(
            newTimelineTime.inSeconds % destLoopDuration.inSeconds);

        return SyncAndPosition(
            SyncAction.rollInToLoop, toPosition(newTimelineTime));
      }
    }

    return SyncAndPosition(SyncAction.none, TimePosition.zero());
  }

  TimePosition toPosition(TimeDuration duration) {
    // Convert TimeDuration to TimePosition
    return TimePosition.fromSeconds(duration.inSeconds);
  }
}

enum SyncAction { none, rollInToLoop, breakSync }

class SyncAndPosition {
  final SyncAction action;
  final TimePosition position;

  SyncAndPosition(this.action, this.position);
}
