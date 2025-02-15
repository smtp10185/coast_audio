import 'package:coast_audio/src/engine/core/tempo.dart';
import 'package:coast_audio/src/engine/engine/tempo_sequence.dart';
import 'package:coast_audio/src/engine/playhead.dart';
import 'package:coast_audio/src/engine/playhead_state.dart';
import 'package:music_core/music_core.dart';

class ProcessState {
  final PlayHeadState playHeadState;
  double sampleRate = 44100.0;
  double playbackSpeedRatio = 1.0;
  int numSamples = 0;
  Range<int> referenceSampleRange = Range(0, 0);
  Range<int> timelineSampleRange = Range(0, 0);
  TimeRange editTimeRange = TimeRange(TimePosition(0), TimePosition(0));
  BeatRange editBeatRange = BeatRange(BeatPosition(0), BeatPosition(0));
  TempoSequence? tempoSequence;
  TempoSequencePosition? tempoPosition;
  SyncRange syncRange = SyncRange.defaultSyncRange();
  Function? onContinuityUpdated;

  ProcessState(this.playHeadState);

  ProcessState.withTempoSequence(this.playHeadState, TempoSequence seq)
      : tempoSequence = seq,
        tempoPosition =
            TempoSequencePosition(seq.internalSequence, TimePosition());

  void update(double newSampleRate, Range<int> newReferenceSampleRange,
      UpdateContinuityFlags updateContinuityFlags) {
    if (sampleRate != newSampleRate) {
      playHeadState.playHead.setScrubbingBlockLength(TimeDuration.toSamples(
          TimeDuration.fromMilliseconds(80), newSampleRate));
    }

    playHeadState.playHead.setReferenceSampleRange(newReferenceSampleRange);

    if (updateContinuityFlags == UpdateContinuityFlags.yes) {
      playHeadState.update(newReferenceSampleRange);
    }

    sampleRate = newSampleRate;
    numSamples = newReferenceSampleRange.length;
    referenceSampleRange = newReferenceSampleRange;

    final splitTimelineRange = referenceSampleRangeToSplitTimelineRange(
        playHeadState.playHead, newReferenceSampleRange);
    assert(!splitTimelineRange.isSplit);
    timelineSampleRange = splitTimelineRange.timelineRange1;
    assert(timelineSampleRange.length == 0 ||
        timelineSampleRange.length == newReferenceSampleRange.length);

    editTimeRange = TimeRange.fromSamples(timelineSampleRange, sampleRate);

    if (tempoPosition == null) return;

    tempoPosition!.set(editTimeRange.start);
    final beatStart = tempoPosition!.getBeats();
    tempoPosition!.set(editTimeRange.end);
    final beatEnd = tempoPosition!.getBeats();
    editBeatRange = BeatRange(beatStart, beatEnd);

    if (updateContinuityFlags == UpdateContinuityFlags.no) return;

    final unloopTimelineSample = playHeadState.playHead
        .referenceSamplePositionToTimelinePositionUnlooped(
            referenceSampleRange.end);
    final oldSyncPoint = getSyncPoint();
    final newSyncPoint = SyncPoint(
      referenceSamplePosition: referenceSampleRange.end,
      monotonicBeat: MonotonicBeat(BeatPosition(
          oldSyncPoint.monotonicBeat.v.beats + editBeatRange.length.inBeats())),
      unloopedTime: TimePosition.fromSamples(unloopTimelineSample, sampleRate),
      time: editTimeRange.end,
      beat: beatEnd,
    );

    oldSyncPoint.time = editTimeRange.start;
    oldSyncPoint.beat = beatStart;
    syncRange = SyncRange(start: oldSyncPoint, end: newSyncPoint);

    if (onContinuityUpdated != null) {
      onContinuityUpdated!();
    }
  }

  void setPlaybackSpeedRatio(double newRatio) {
    playbackSpeedRatio = newRatio;
  }

  void setTempoSequence(TempoSequence? ts) {
    if (tempoSequence == ts) return;

    tempoSequence = ts;

    if (tempoSequence != null) {
      tempoPosition = TempoSequencePosition(
          tempoSequence!.internalSequence, TimePosition());
    } else {
      tempoPosition = null;
    }
  }

  TempoSequence? getTempoSequence() {
    return tempoSequence;
  }

  TempoSequencePosition? getTempoSequencePosition() {
    return tempoPosition;
  }

  SyncRange getSyncRange() {
    return syncRange;
  }

  SyncPoint getSyncPoint() {
    return syncRange.end;
  }

  void setSyncRange(SyncRange r) {
    syncRange = r;
  }
}

enum UpdateContinuityFlags { no, yes }
