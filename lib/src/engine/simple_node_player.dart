import 'package:coast_audio/src/engine/node.dart';
import 'package:coast_audio/src/engine/node_player_utils.dart';

class SimpleNodePlayer {
  NodeGraph? graph;

  double sampleRate = 0.0;

  SimpleNodePlayer(
      Node nodeToPlay, double sampleRateToUse, int blockSizeToUse) {
    setNode(nodeToPlay, sampleRateToUse, blockSizeToUse);
  }

  void setNode(Node newNode, double sampleRateToUse, int blockSizeToUse) {
    assert(newNode != null);
    graph = NodePlayerUtilities.prepareToPlay(
        newNode, null, sampleRateToUse, blockSizeToUse);
  }

  Node? getNode() {
    return graph?.rootNode;
  }

  void clearNode() {
    graph = null;
  }

  int process(ProcessContext pc) {
    if (graph == null) return -1;

    // 准备所有节点以处理下一个块
    for (var node in graph!.orderedNodes) {
      node.prepareForNextBlock(pc.referenceSampleRange);
    }

    // 然后按顺序处理它们
    for (var node in graph!.orderedNodes) {
      node.process(pc.numSamples, pc.referenceSampleRange);
    }

    // 最后将输出从根节点复制到播放器缓冲区
    var output = graph!.rootNode?.getProcessedOutput();
    var numAudioChannels = output?.audio
        .getNumChannels()
        .clamp(0, pc.buffers.audio.getNumChannels());

    if (numAudioChannels! > 0) {
      pc.buffers.audio
          .getFirstChannels(numAudioChannels)
          .add(output!.audio.getFirstChannels(numAudioChannels));
    }

    pc.buffers.midi.mergeFrom(output!.midi);

    return 0;
  }

  double getSampleRate() {
    return sampleRate;
  }

  void prepareToPlay(double sampleRate, int blockSize) {}
}

class NodePlayerUtilities {
  static NodeGraph prepareToPlay(
      Node node, NodeGraph? oldGraph, double sampleRate, int blockSize,
      {Function? allocateAudioBuffer,
      Function? deallocateAudioBuffer,
      bool nodeMemorySharingEnabled = false}) {
    if (node == null) {
      return NodeGraph();
    }

    // 创建节点图
    var nodeGraph = createNodeGraph(node);
    assert(!areThereAnyCycles(nodeGraph.orderedNodes));
    assert(areNodeIDsUnique(nodeGraph.orderedNodes, true));

    // 初始化所有节点
    var info = PlaybackInitialisationInfo(
      sampleRate: sampleRate,
      blockSize: blockSize,
      nodeGraph: nodeGraph,
      nodeGraphToReplace: oldGraph,
      allocateAudioBuffer: allocateAudioBuffer,
      deallocateAudioBuffer: deallocateAudioBuffer,
      enableNodeMemorySharing: nodeMemorySharingEnabled,
    );

    for (var n in nodeGraph.orderedNodes) {
      n.initialise(info);
    }

    return nodeGraph;
  }

  static NodeGraph createNodeGraph(Node node) {
    // 创建节点图的逻辑
    return NodeGraph();
  }

  static bool areThereAnyCycles(List<Node> nodes) {
    // 检查是否有循环的逻辑
    return false;
  }

  static bool areNodeIDsUnique(List<Node> nodes, bool check) {
    // 检查节点ID是否唯一的逻辑
    return true;
  }
}
