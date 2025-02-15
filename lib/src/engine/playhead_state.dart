import 'package:coast_audio/src/engine/playhead.dart';

import 'package:music_core/music_core.dart';

class PlayHeadState {
  final PlayHead playHead;
  bool isPlayHeadRunning = false;
  bool playheadJumped = false;
  bool lastBlockOfLoop = false;
  bool firstBlockOfLoop = false;
  DateTime lastUserInteractionTime = DateTime.now();

  PlayHeadState(this.playHead);

  void update(Range<int> referenceSampleRange) {
    final bool isPlayingNow = playHead.isPlaying();
    bool jumped = false;

    if (lastUserInteractionTime != playHead.getLastUserInteractionTime()) {
      lastUserInteractionTime = playHead.getLastUserInteractionTime();
      jumped = true;
    }

    if (isPlayingNow != isPlayHeadRunning) {
      isPlayHeadRunning = isPlayingNow;
      jumped = jumped || isPlayHeadRunning;
    }

    playheadJumped = jumped;

    if (playHead.isLooping()) {
      final timelineLoopRange = playHead.getLoopRange();
      final startTimelinePos =
          playHead.referenceSamplePositionToTimelinePosition(
              referenceSampleRange.start);
      final endTimelinePos = playHead.referenceSamplePositionToTimelinePosition(
              referenceSampleRange.end - 1) +
          1;

      if (playHead.isRollingIntoLoop()) {
        firstBlockOfLoop = false;
      } else {
        firstBlockOfLoop = startTimelinePos == timelineLoopRange.start;
      }

      lastBlockOfLoop = endTimelinePos == timelineLoopRange.end;
    } else {
      firstBlockOfLoop = false;
      lastBlockOfLoop = false;
    }
  }

  bool isContiguousWithPreviousBlock() =>
      !(didPlayheadJump() || isFirstBlockOfLoop());

  bool didPlayheadJump() => playheadJumped;

  bool isFirstBlockOfLoop() => firstBlockOfLoop;

  bool isLastBlockOfLoop() => lastBlockOfLoop;
}
