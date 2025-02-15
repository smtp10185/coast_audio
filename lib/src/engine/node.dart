import 'package:coast_audio/coast_audio.dart';
import 'package:coast_audio/src/engine/midi_message.dart';
import 'package:coast_audio/src/engine/node_player_utils.dart';
import 'package:music_core/music_core.dart';

class Node {
  // 音频视图和MIDI缓冲区
  late AudioBuffer audioView;
  late AudioBuffer audioBuffer;
  MidiMessageArray midiBuffer = MidiMessageArray();
  int numSamplesProcessed = 0;

  // 获取节点属性
  NodeProperties getNodeProperties() {
    // 实现
    return NodeProperties();
  }

  // 检查节点是否准备好进行处理
  bool isReadyToProcess() {
    // 实现
    return true;
  }

  // 处理节点
  void process(int numSamples, Range<int> referenceSampleRange) {
    // 实现
  }

  // 初始化节点
  void initialise(PlaybackInitialisationInfo info) {
    prepareToPlay(info);

    //var props = getNodeProperties();
    //var audioBufferSize = Size.create(props.numberOfChannels, info.blockSize);

    if (info.allocateAudioBuffer != null) {
      allocateAudioBuffer = info.allocateAudioBuffer;
      deallocateAudioBuffer = info.deallocateAudioBuffer;
    } else if (nodeOptimisations.allocate == AllocateAudioBuffer.yes) {
      //audioBuffer.resize(audioBufferSize);
    }

    directInputNodes = getDirectInputNodes();
  }

  // 获取直接输入节点
  List<Node> getDirectInputNodes() {
    // 实现
    return [];
  }

  // 为下一个块准备节点
  void prepareForNextBlock(Range<int> referenceSampleRange) {
    if (retainCount == 0) {
      nodeToRelease = null; // 重置以防输出节点行为改变

      retain();

      for (var n in directInputNodes) {
        n.retain();
      }
    }

    hasBeenProcessed = false;
    prefetchBlock(referenceSampleRange);
  }

  // 获取处理后的输出
  AudioAndMidiBuffer getProcessedOutput() {
    assert(hasProcessed());

    // 在调试模式下检查 nodeToRelease 是否已处理
    assert(() {
      final node = nodeToRelease;
      if (node != null) {
        assert(node.hasProcessed());
      }
      return true;
    }());

    return AudioAndMidiBuffer(
      audioView.getStart(numSamplesProcessed),
      midiBuffer,
    );
  }

  // 其他方法和属性
  bool hasBeenProcessed = false;
  List<Node> directInputNodes = [];
  Node? nodeToRelease;
  Function? allocateAudioBuffer;
  Function? deallocateAudioBuffer;
  NodeOptimisations nodeOptimisations = NodeOptimisations();
  int retainCount = 0;

  void retain() {
    assert(retainCount >= 0);
    retainCount++;
  }

  void release() {
    assert(retainCount > 0);

    if (--retainCount == 0) {
      if (nodeToRelease != null) {
        nodeToRelease!.release();
      }

      if (deallocateAudioBuffer != null) {
        deallocateAudioBuffer!(AudioAndMidiBuffer(audioView, midiBuffer));
      }
    }
  }

  void prepareToPlay(PlaybackInitialisationInfo info) {
    // 实现
  }

  void prefetchBlock(Range<int> referenceSampleRange) {
    // 实现
  }

  bool hasProcessed() {
    return hasBeenProcessed;
  }
}

/// 枚举表示是否在传递给处理之前清除缓冲区。
enum ClearBuffers {
  /// 不清除缓冲区，子类将负责处理。
  no,

  /// 清除缓冲区，以便子类可以简单地将数据添加到其中。
  yes
}

/// 枚举表示是否分配音频缓冲区。
enum AllocateAudioBuffer {
  /// 不分配音频缓冲区，子类将忽略传递给处理的目标缓冲区。
  no,

  /// 分配音频缓冲区，以便子类使用传递给处理的目标缓冲区。
  yes
}

/// 包含一些可能被节点或播放器使用的提示以提高效率。
class NodeOptimisations {
  ClearBuffers clear;
  AllocateAudioBuffer allocate;

  NodeOptimisations({
    this.clear = ClearBuffers.yes,
    this.allocate = AllocateAudioBuffer.yes,
  });
}

class NodeProperties {
  bool hasAudio;
  bool hasMidi;
  int numberOfChannels;
  int latencyNumSamples;
  int nodeID;

  NodeProperties({
    this.hasAudio = false,
    this.hasMidi = false,
    this.numberOfChannels = 0,
    this.latencyNumSamples = 0,
    this.nodeID = 0,
  });
}

class ProcessContext {
  int numSamples;
  Range<int> referenceSampleRange;
  AudioAndMidiBuffer buffers;

  ProcessContext(this.numSamples, this.referenceSampleRange, this.buffers);
}

class AudioAndMidiBuffer {
  final AudioBuffer audio;
  final MidiMessageArray midi;

  AudioAndMidiBuffer(this.audio, this.midi);
}
