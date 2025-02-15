import 'package:coast_audio/src/engine/midi_message.dart';
import 'package:coast_audio/src/engine/node.dart';
import 'package:coast_audio/src/engine/playhead.dart';
import 'package:coast_audio/src/engine/playhead_state.dart';
import 'package:coast_audio/src/engine/process_state.dart.bak';
import 'package:coast_audio/src/engine/simple_node_player.dart';
import 'package:music_core/music_core.dart';

class EngineNodePlayer {
  final PlayHeadState playHeadState;
  final ProcessState processState;
  late SimpleNodePlayer nodePlayer;
  final MidiMessageArray scratchMidi = MidiMessageArray();

  EngineNodePlayer(this.processState)
      : playHeadState = processState.playHeadState;

  EngineNodePlayer.withPoolCreator(
      this.processState, Function poolCreator, bool audioWorkgroupEnabled)
      : playHeadState = processState.playHeadState {
    // 使用池创建者和音频工作组初始化
  }

  Node? getNode() {
    return nodePlayer.getNode();
  }

  void setNodeWithDefault(Node newNode) {
    nodePlayer.setNode(newNode, nodePlayer.getSampleRate(), 512);
  }

  void setNode(Node newNode, double sampleRate, int blockSize) {
    nodePlayer.setNode(newNode, sampleRate, blockSize);
  }

  void prepareToPlay(double sampleRate, int blockSize) {
    nodePlayer.prepareToPlay(sampleRate, blockSize);
  }

  int process(ProcessContext pc) {
    int numMisses = 0;
    playHeadState.playHead.setReferenceSampleRange(pc.referenceSampleRange);

    // 检查时间线是否需要由于循环而分成两部分进行处理
    final splitTimelineRange = referenceSampleRangeToSplitTimelineRange(
        playHeadState.playHead, pc.referenceSampleRange);

    if (splitTimelineRange.isSplit) {
      final firstRangeLength = splitTimelineRange.timelineRange1.length;

      numMisses += processReferenceRange(
          pc, pc.referenceSampleRange.withLength(firstRangeLength));
      numMisses += processReferenceRange(
          pc,
          pc.referenceSampleRange
              .withStart(pc.referenceSampleRange.start + firstRangeLength));
    } else {
      numMisses += processReferenceRange(pc, pc.referenceSampleRange);
    }

    return numMisses;
  }

  void clearNode() {
    nodePlayer.clearNode();
  }

  double getSampleRate() {
    return nodePlayer.getSampleRate();
  }

  int processReferenceRange(
      ProcessContext pc, Range<int> referenceSampleRange) {
    return processTempoChanges(pc);
  }

  int processTempoChanges(ProcessContext pc) {
    int numMisses = 0;
    playHeadState.playHead.setReferenceSampleRange(pc.referenceSampleRange);

    final sampleRate = nodePlayer.getSampleRate();
    processState.update(
        sampleRate, pc.referenceSampleRange, UpdateContinuityFlags.no);
    final timeRange = processState.editTimeRange;

    final tempoPosition = processState.getTempoSequencePosition();
    if (tempoPosition != null) {
      double startProportion = 0.0;
      var lastEventPosition = timeRange.start;

      while (true) {
        final nextTempoChangePosition = tempoPosition.getTimeOfNextChange();
        if (nextTempoChangePosition == lastEventPosition) break;
        if (!timeRange.containsPosition(nextTempoChangePosition)) break;

        final proportion = (nextTempoChangePosition - timeRange.start).seconds /
            timeRange.length.seconds;
        final numSamples = (pc.numSamples * proportion).round();
        lastEventPosition = nextTempoChangePosition;

        if (numSamples < 128) continue;

        processSubRange(pc, Range(startProportion, proportion));
        startProportion = proportion;
      }

      if (startProportion < 1.0) {
        processSubRange(pc, Range(startProportion, 1.0));
      }
    } else {
      processSubRange(pc, Range(0.0, 1.0));
    }

    return numMisses;
  }

  int processSubRange(ProcessContext pc, Range<double> proportion) {
    assert(pc.numSamples > 0);
    assert(proportion.start >= 0.0);
    assert(proportion.end <= 1.0);

    final sampleRate = nodePlayer.getSampleRate();
    final startReferenceSample = pc.referenceSampleRange.start +
        (proportion.start * pc.referenceSampleRange.length).round();
    final endReferenceSample = pc.referenceSampleRange.start +
        (proportion.end * pc.referenceSampleRange.length).round();
    final referenceRange = Range(startReferenceSample, endReferenceSample);

    final startSample = (proportion.start * pc.numSamples).round();
    final endSample = (proportion.end * pc.numSamples).round();
    final sampleRange = Range(startSample, endSample);

    if (sampleRange.length == 0) return 0;

    final destAudio =
        pc.buffers.audio.getFrameRange(sampleRange.start, sampleRange.end);
    scratchMidi.clear();

    final pc2 = ProcessContext(sampleRange.length, referenceRange,
        AudioAndMidiBuffer(destAudio, scratchMidi));
    processState.update(sampleRate, referenceRange, UpdateContinuityFlags.yes);
    final numMisses = nodePlayer.process(pc2);

    final offset = TimeDuration.fromSamples(
        startReferenceSample - pc.referenceSampleRange.start, sampleRate);
    pc.buffers.midi.mergeFromWithOffset(scratchMidi, offset.inSeconds);

    return numMisses;
  }
}
