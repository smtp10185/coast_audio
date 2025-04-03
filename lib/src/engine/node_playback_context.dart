import 'dart:typed_data';

import 'package:coast_audio/src/engine/edit_playback_context.dart';
import 'package:coast_audio/src/engine/engine/edit_playback_context.dart';
import 'package:coast_audio/src/engine/engine_node_player.dart';
import 'package:coast_audio/src/engine/node.dart';
import 'package:coast_audio/src/engine/playhead.dart';
import 'package:coast_audio/src/engine/playhead_state.dart';
import 'package:coast_audio/src/engine/engine/process_state.dart';
import 'package:coast_audio/src/engine/engine/tempo_sequence.dart';
import 'package:coast_audio/src/engine/engine/util.dart';
import 'package:music_core/music_core.dart';

class NodePlaybackContext {
  final EditPlaybackContext editPlaybackContext;
  // 这里的问题是，Dart中不能在初始化列表中访问实例成员。
  // 解决方法是将playHead的初始化移到构造函数中。
  late final PlayHead playHead;
  late final PlayHeadState playHeadState;
  late final ProcessState processState;
  late final EngineNodePlayer player;

  int latencySamples = 0;
  int numSamplesToProcess = 0;
  Range<double> referenceStreamRange = Range(0.0, 0.0);
  double pendingPosition = 0.0;
  double pendingPositionJumpTime = 0.0;
  bool positionUpdatePending = false;
  bool pendingRollInToLoop = false;
  bool pendingPositionJumpTimeValid = false;
  bool playPending = false;
  double speedCompensation = 0.0;
  double blockLengthScaleFactor = 1.0;
  List<LagrangeInterpolator> interpolators = [];
  bool isUsingInterpolator = false;
  TempoState tempoState = TempoState();
  TempoSequence tempoSequence;

  NodePlaybackContext(this.editPlaybackContext) {
    playHead = PlayHead();
    playHeadState = PlayHeadState(playHead);
    tempoSequence = editPlaybackContext.edit.tempoSequence;

    processState = ProcessState.withTempoSequence(
      playHeadState,
      tempoSequence,
    );

    player = EngineNodePlayer(processState);

    player.processState.onContinuityUpdated = () {
      final syncRange = player.processState.getSyncRange();
      final editTime = syncRange.start.time;
      editPlaybackContext.edit
          .updateModifierTimers(editTime, getNumSamples(syncRange));
      editPlaybackContext.midiDispatcher.masterTimeUpdate(editTime);
    };
  }

  void setNode(Node node, double sampleRate, int blockSize) {
    assert(sampleRate > 0.0);
    assert(blockSize > 0);
    blockSize = (blockSize * (1.0 + (10.0 * 0.01))).round();
    player.setNode(node, sampleRate, blockSize);

    final currentNode = player.getNode();
    if (currentNode != null) {
      latencySamples = currentNode.getNodeProperties().latencyNumSamples;
    }
  }

  void clearNode() {
    player.clearNode();
  }

  int getLatencySamples() {
    return latencySamples;
  }

  void postPlay() {
    playPending = true;
  }

  bool isPlayPending() {
    return playPending;
  }

  void postPosition(TimePosition positionToJumpTo, [TimePosition? whenToJump]) {
    pendingPosition = positionToJumpTo.inSeconds;

    if (whenToJump != null) {
      pendingPositionJumpTime = whenToJump.inSeconds;
      pendingPositionJumpTimeValid = true;
    } else {
      pendingPositionJumpTimeValid = false;
    }

    pendingRollInToLoop = false;
    positionUpdatePending = true;
  }

  double? getPendingPositionChange() {
    if (!positionUpdatePending) return null;
    return pendingPosition;
  }

  void postRollInToLoop(double newPosition) {
    pendingPosition = newPosition;
    pendingRollInToLoop = true;
    positionUpdatePending = true;
  }

  void setSpeedCompensation(double plusOrMinus) {
    speedCompensation = plusOrMinus.clamp(-10.0, 10.0);
  }

  void setTempoAdjustment(double plusOrMinusProportion) {
    blockLengthScaleFactor = 1.0 + plusOrMinusProportion.clamp(-0.5, 0.5);
  }

  void checkForTempoSequenceChanges() {
    final internalSequence = tempoSequence.getInternalSequence();

    if (internalSequence.hash() == tempoState.hash) return;

    final lastPositionRemapped =
        internalSequence.toTime(tempoState.lastBeatPosition);
    final lastSampleRemapped =
        toSamplesFromTimePosition(lastPositionRemapped, getSampleRate());
    playHead.overridePosition(lastSampleRemapped);
  }

  void nextBlockStarted() {
    if (playPending) {
      playPending = false;
      playHead.play();
    }
  }

  void updateReferenceSampleRange(int numSamples) {
    if (speedCompensation != 0.0) {
      numSamples = (numSamples * (1.0 + (speedCompensation * 0.01))).round();
    }

    double sampleDuration = numSamples.toDouble();

    if (blockLengthScaleFactor != 1.0) {
      sampleDuration *= blockLengthScaleFactor;
    }

    referenceStreamRange = Range(
        referenceStreamRange.end, referenceStreamRange.end + sampleDuration);
    playHead.setReferenceSampleRange(getReferenceSampleRange());
    numSamplesToProcess = numSamples;
    processState.setPlaybackSpeedRatio(blockLengthScaleFactor);

    checkForTempoSequenceChanges();
  }

  void resyncToReferenceSampleRange(Range<int> newReferenceSampleRange) {
    final sampleRate = getSampleRate();
    final currentPos = Range.sampleToTime(playHead.getPosition(), sampleRate);
    referenceStreamRange = Range(newReferenceSampleRange.start.toDouble(),
        newReferenceSampleRange.end.toDouble());
    playHead.setReferenceSampleRange(getReferenceSampleRange());
    playHead.setPosition(Range.timeToSample(currentPos, sampleRate));
  }

  void process(Float32List allChannels, int numChannels, int destNumSamples) {
    final referenceSampleRange = getReferenceSampleRange();

    if (positionUpdatePending) {
      final sampleRate = getSampleRate();
      bool shouldPerformPositionChange = true;

      if (pendingPositionJumpTimeValid) {
        final currentTimeSeconds = Range.sampleToTimeRange(
            Range(playHead.getPosition(), referenceSampleRange.length),
            sampleRate);
        final jumpTimeSeconds = pendingPositionJumpTime;

        final loopEndIsInThisBlock = playHead.isLooping() &&
            currentTimeSeconds.contains(
                Range.sampleToTime(playHead.getLoopRange().end, sampleRate));

        if (loopEndIsInThisBlock) {
          pendingPositionJumpTimeValid = false;
          pendingPositionJumpTime = 0.0;
          pendingPosition = 0.0;
          positionUpdatePending = false;
          shouldPerformPositionChange = false;
        }

        if (currentTimeSeconds.contains(jumpTimeSeconds)) {
          pendingPositionJumpTimeValid = false;
          pendingPositionJumpTime = 0.0;
        } else {
          shouldPerformPositionChange = false;
        }
      }

      if (shouldPerformPositionChange) {
        if (positionUpdatePending) {
          positionUpdatePending = false;
          final samplePos = Range.timeToSample(pendingPosition, sampleRate);

          if (pendingRollInToLoop) {
            playHead.setRollInToLoop(samplePos);
          } else {
            playHead.setPosition(samplePos);
          }
        }
      }
    }

    // Process audio and MIDI buffers
    // This is a placeholder for the actual processing logic
  }

  double getSampleRate() {
    return player.getSampleRate();
  }

  SyncPoint getSyncPoint() {
    return processState.getSyncPoint();
  }

  Range<int> getReferenceSampleRange() {
    return Range(
        referenceStreamRange.start.round(), referenceStreamRange.end.round());
  }

  void ensureNumInterpolators(int numRequired) {
    while (interpolators.length < numRequired) {
      interpolators.add(LagrangeInterpolator());
    }
  }
}

class LagrangeInterpolator {
  // Implementation
}

class SyncTime {
  final double time = 0.0;
}

class TempoState {
  int hash = 0;
  BeatPosition lastBeatPosition = BeatPosition(0.0);

  TempoState();
}
