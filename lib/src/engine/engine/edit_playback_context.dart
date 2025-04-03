import 'package:coast_audio/coast_audio.dart';
import 'package:coast_audio/src/engine/context_syncroniser.dart';
import 'package:coast_audio/src/engine/device.dart';
import 'package:coast_audio/src/engine/level_measure.dart';
import 'package:coast_audio/src/engine/midi_note_dispatcher.dart';
import 'package:coast_audio/src/engine/node_playback_context.dart';
import 'package:coast_audio/src/engine/playhead.dart';
import 'package:coast_audio/src/engine/transport_control.dart';
import 'package:music_core/music_core.dart';

import 'util.dart';

class EditPlaybackContext {
  final TransportControl transport;
  final Edit edit;
  final LevelMeasurer masterLevels = LevelMeasurer();
  final MidiNoteDispatcher midiDispatcher = MidiNoteDispatcher();
  List<MidiOutputDeviceInstance> midiOutputs = [];
  List<WaveOutputDeviceInstance> waveOutputs = [];
  ProcessPriorityBooster? priorityBooster;
  bool isAllocated = false;
  NodePlaybackContext? nodePlaybackContext;
  ContextSyncroniser? contextSyncroniser;
  double audiblePlaybackTime = 0.0;
  int activelyRecordingInputDevices = 0;

  EditPlaybackContext(this.transport) : edit = transport.edit {
    if (edit.shouldPlay()) {
      nodePlaybackContext = NodePlaybackContext(
          this);
      contextSyncroniser = ContextSyncroniser();
    }
  }

  void removeInstanceForDevice(InputDevice device) {
    // Implementation
  }

  void addWaveInputDeviceInstance(InputDevice device) {
    // Implementation
  }

  void addMidiInputDeviceInstance(InputDevice device) {
    // Implementation
  }

  void clearNodes() {
    // Implementation
  }

  void createPlayAudioNodes(TimePosition startTime) {
    createNode();
    startPlaying(startTime);
  }

  void startPlaying(TimePosition start) {
    prepareOutputDevices(start);

    priorityBooster ??= ProcessPriorityBooster(edit.engine);

    for (var mo in midiOutputs) {
      mo.start();
    }
  }

  void prepareOutputDevices(TimePosition start) {
    var dm = edit.engine.deviceManager;
    double sampleRate = dm.getSampleRate();
    int blockSize = dm.getBlockSize();

    start = globalStreamTimeToEditTime(start.inSeconds);

    for (var wo in waveOutputs) {
      wo.prepareToPlay(sampleRate, blockSize);
    }

    for (var mo in midiOutputs) {
      mo.prepareToPlay(start, true);
    }

    midiDispatcher.prepareToPlay(start);
  }

  void createPlayAudioNodesIfNeeded(TimePosition startTime) {
    if (!isAllocated) {
      createPlayAudioNodes(startTime);
    }
  }

  void reallocate() {
    createPlayAudioNodes(getPosition());
  }

  bool isPlaybackGraphAllocated() {
    return isAllocated;
  }

  void prepareForPlaying(TimePosition startTime) {
    // Implementation
  }

  void prepareForRecording(TimePosition startTime, TimePosition punchIn) {
    // Implementation
  }

  void syncToContext(EditPlaybackContext? contextToSyncTo,
      TimePosition previousBarTime, TimeDuration syncInterval) {
    // Implementation
  }

  InputDeviceInstance? getInputFor(InputDevice? d) {
    // Implementation
  }

  OutputDeviceInstance? getOutputFor(OutputDevice? d) {
    // Implementation
  }

  bool isPlaying() {
    return nodePlaybackContext?.playHead.isPlaying() ?? false;
  }

  bool isLooping() {
    return nodePlaybackContext?.playHead.isLooping() ?? false;
  }

  bool isDragging() {
    return nodePlaybackContext?.playHead.isUserDragging() ?? false;
  }

  TimePosition getPosition() {
    return TimePosition.fromSamples(
      nodePlaybackContext?.playHead.getPosition() ?? 0,
      nodePlaybackContext?.getSampleRate() ?? 44100.0,
    );
  }

  TimePosition getUnloopedPosition() {
    return TimePosition.fromSamples(
      nodePlaybackContext?.playHead.getUnloopedPosition() ?? 0,
      nodePlaybackContext?.getSampleRate() ?? 44100.0,
    );
  }

  TimeRange getLoopTimes() {
    return TimeRange.fromSamples(
      nodePlaybackContext?.playHead.getLoopRange() ?? Range(0, 0),
      nodePlaybackContext?.getSampleRate() ?? 44100.0,
    );
  }

  int getLatencySamples() {
    return nodePlaybackContext?.getLatencySamples() ?? 0;
  }

  TimePosition getAudibleTimelineTime() {
    return nodePlaybackContext != null
        ? TimePosition.fromSeconds(audiblePlaybackTime)
        : transport.getPosition();
  }

  double getSampleRate() {
    return nodePlaybackContext?.getSampleRate() ?? 44100.0;
  }

  void setSpeedCompensation(double plusOrMinus) {
    if (nodePlaybackContext != null) {
      nodePlaybackContext!.setSpeedCompensation(plusOrMinus);
    }
  }

  void setTempoAdjustment(double plusOrMinusProportion) {
    if (nodePlaybackContext != null) {
      nodePlaybackContext!.setTempoAdjustment(plusOrMinusProportion);
    }
  }

  void postPosition(TimePosition positionToJumpTo, TimePosition? whenToJump) {
    if (nodePlaybackContext != null) {
      nodePlaybackContext!.postPosition(positionToJumpTo, whenToJump);
    }
  }

  TimePosition globalStreamTimeToEditTime(double globalStreamTime) {
    if (nodePlaybackContext == null) return TimePosition();

    final sampleRate = getSampleRate();
    final globalSamplePos = Range.timeToSample(globalStreamTime, sampleRate);
    final timelinePosition = nodePlaybackContext!.playHead
        .referenceSamplePositionToTimelinePosition(globalSamplePos);

    return TimePosition.fromSamples(timelinePosition, sampleRate);
  }

  TimePosition globalStreamTimeToEditTimeUnlooped(double globalStreamTime) {
    if (nodePlaybackContext == null) return TimePosition();

    final sampleRate = getSampleRate();
    final globalSamplePos = Range.timeToSample(globalStreamTime, sampleRate);
    final timelinePosition = nodePlaybackContext!.playHead
        .referenceSamplePositionToTimelinePositionUnlooped(globalSamplePos);

    return TimePosition.fromSamples(timelinePosition, sampleRate);
  }

  void resyncToGlobalStreamTime(
      Range<double> globalStreamTime, double sampleRate) {
    if (nodePlaybackContext == null) return;

    final globalSampleRange =
        Range.timeToSampleRange(globalStreamTime, sampleRate);
    nodePlaybackContext!.resyncToReferenceSampleRange(globalSampleRange);
  }

  void setThreadPoolStrategy(int type) {
    // Implementation
  }

  void enablePooledMemory(bool enable) {
    // Implementation
  }

  void enableNodeMemorySharing(bool enable) {
    // Implementation
  }

  void enableAudioWorkgroup(bool enable) {
    // Implementation
  }

  int getNumActivelyRecordingDevices() {
    return activelyRecordingInputDevices;
  }

  void incrementNumActivelyRecordingDevices() {
    activelyRecordingInputDevices++;
  }

  void decrementNumActivelyRecordingDevices() {
    activelyRecordingInputDevices--;
  }

  void play() {
    if (nodePlaybackContext != null) {
      nodePlaybackContext!.playHead.play();
    }
  }

  void postPlay() {
    if (nodePlaybackContext != null) {
      nodePlaybackContext!.postPlay();
    }
  }

  bool isPlayPending() {
    return nodePlaybackContext?.isPlayPending() ?? false;
  }

  void stop() {
    if (nodePlaybackContext != null) {
      nodePlaybackContext!.playHead.stop();
    }
  }

  SyncPoint? getSyncPoint() {
    return nodePlaybackContext?.getSyncPoint();
  }

  void blockUntilSyncPointChange() {
    // Implementation
  }

  void createNode() {
    // Implementation
  }

  void nextBlockStarted() {
    // Implementation
  }

  void fillNextNodeBlock(
      List<List<double>> allChannels, int numChannels, int numSamples) {
    // Implementation
  }

  PlayHead? getNodePlayHead() {
    return nodePlaybackContext?.playHead;
  }
}

class ProcessPriorityBooster {
  final Engine engine;

  ProcessPriorityBooster(this.engine);
}
