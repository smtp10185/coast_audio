import 'package:coast_audio/coast_audio.dart';
import 'package:coast_audio/src/engine/edit_playback_context.dart';
import 'package:coast_audio/src/engine/playhead_wrapper.dart';
import 'package:music_core/music_core.dart';

import 'transport_state.dart';

class TransportControl {
  final Edit edit;

  bool looping = false;
  TimePosition position = TimePosition(0);
  TimePosition loopPoint1 = TimePosition(0);
  TimePosition loopPoint2 = TimePosition(0);
  late EditPlaybackContext playbackContext;
  late PlayHeadWrapper playHeadWrapper;
  late PlayingFlag playingFlag;
  Engine engine;

  late TransportState transportState;

  TransportControl({required this.edit, required this.engine}) {
    transportState = TransportState(this);
    playHeadWrapper = PlayHeadWrapper(this);
    playingFlag = PlayingFlag(engine);
  }

  void setPosition(TimePosition position) {
    transportState.lastUserDragTime = DateTime.now().millisecondsSinceEpoch;
    this.position = position;
  }

  void performPlay() {
    // Reset section player logic here (section play)

    if (!edit.shouldPlay()) return;

    if (!playingFlag.playing) {
      if (transportState.justSendMMCIfEnabled && sendMMCStartPlay()) return;

      if (looping) {
        final cursorPos = position;
        final loopRange = getLoopRange();

        if (cursorPos < loopRange.start ||
            cursorPos > loopRange.end - TimePosition(0.1)) {
          position = loopRange.start;
        }

        transportState.startTime = loopRange.start;
        transportState.endTime = loopRange.end;

        if (transportState.endTime <
            transportState.startTime + TimePosition(0.01)) {
          print(
              "Can't play in loop mode unless the in/out markers are further apart");
          return;
        }
      } else {
        transportState.startTime = position;
        transportState.endTime = Edit.getMaximumEditEnd();
      }

      /* Ableton Link 用 暂时跳过
      if (edit.getAbletonLink().isConnected()) {
        final barLength = edit.tempoSequence.getTimeSig(0).numerator;
        final beatsUntilNextLinkCycle =
            edit.getAbletonLink().getBeatsUntilNextCycle(barLength);

        final cyclePos = transportState.startTime % barLength;
        final nextLinkCycle =
            edit.tempoSequence.toTime(beatsUntilNextLinkCycle);

        transportState.startTime =
            (transportState.startTime - cyclePos) + (barLength - nextLinkCycle);
      }*/

      transportState.recording = false;
      transportState.safeRecording = false;
      playingFlag = PlayingFlag(engine);

      ensureContextAllocated();

      if (playbackContext != null) {
        playHeadWrapper.playByRange(
            TimeRange(transportState.startTime, transportState.endTime),
            looping);
        playHeadWrapper.setPosition(position);
      } else {
        clearPlayingFlags();
      }

      edit.setClickTrackRange(TimeRange.empty());
    }
  }

  void ensureContextAllocated({bool alwaysReallocate = false}) {
    if (!edit.shouldPlay()) {
      return;
    }

    final start = position;

    if (playbackContext == null) {
      playbackContext = EditPlaybackContext(this);
      playbackContext!.createPlayAudioNodes(start);
      transportState.playbackContextAllocation += 1;
    }

    if (alwaysReallocate) {
      playbackContext!.createPlayAudioNodes(start);
    } else {
      playbackContext!.createPlayAudioNodesIfNeeded(start);
    }
  }

  bool sendMMCStartPlay() {
    return true;
  }

  TimeRange getLoopRange() {
    return TimeRange(loopPoint1, loopPoint2);
  }

  getPosition() {}

  void clearPlayingFlags() {
    transportState.playing = false;
    transportState.recording = false;
    transportState.safeRecording = false;
    playingFlag.reset();
  }
}

class PlayingFlag {
  final Engine engine;

  PlayingFlag(this.engine);

  bool playing = false;

  void reset() {}
}
