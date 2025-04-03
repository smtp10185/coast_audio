import 'package:coast_audio/src/engine/process_state.dart.bak';
import 'package:coast_audio/src/engine/engine/util.dart';
import 'package:music_core/music_core.dart';

class EngineNode {
  ProcessState processState;

  EngineNode(this.processState);

  int getNumSamples() => processState.numSamples;
  double getSampleRate() => processState.sampleRate;
  Range<int> getTimelineSampleRange() => processState.timelineSampleRange;
  TimeRange getEditTimeRange() => processState.editTimeRange;
  BeatRange getEditBeatRange() => processState.editBeatRange;
  Range<int> getReferenceSampleRange() => processState.referenceSampleRange;
  double getPlaybackSpeedRatio() => processState.playbackSpeedRatio;

  void setProcessState(ProcessState newProcessState) {
    processState = newProcessState;
  }
}

class PlaybackInitialisationInfo {
  double sampleRate = 44100.0;
}

class MidiMessageSequence {}

class TimeBase {}

class LiveClipLevel {
  bool isMute() => false;
  double getGain() => 1.0;
}

class EditItemID {
  int getRawID() => 0;
}

class MPESourceID {}

MPESourceID createUniqueMPESourceID() => MPESourceID();
