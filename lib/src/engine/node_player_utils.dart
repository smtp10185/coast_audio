import 'dart:collection';

import 'package:coast_audio/src/engine/node.dart';

class NodeGraph {
  Node? rootNode;
  List<Node> orderedNodes = [];
  List<NodeAndID> sortedNodes = [];

  NodeGraph({this.rootNode});
}

class NodeAndID {
  Node? node;
  int id = 0;

  NodeAndID({this.node, this.id = 0});
}

class PlaybackInitialisationInfo {
  final double sampleRate;
  final int blockSize;
  final NodeGraph nodeGraph;
  final NodeGraph? nodeGraphToReplace;
  final Function? allocateAudioBuffer;
  final Function? deallocateAudioBuffer;
  final bool enableNodeMemorySharing;

  PlaybackInitialisationInfo({
    required this.sampleRate,
    required this.blockSize,
    required this.nodeGraph,
    this.nodeGraphToReplace,
    this.allocateAudioBuffer,
    this.deallocateAudioBuffer,
    this.enableNodeMemorySharing = false,
  });
}

class AudioBufferPool {
  void reserve(int numBuffers, BufferSize size) {
    // Implementation
  }
}

class BufferSize {
  int channels;
  int blockSize;

  BufferSize(this.channels, this.blockSize);

  static BufferSize create(int channels, int blockSize) {
    return BufferSize(channels, blockSize);
  }
}

class NodePlayerUtils {
  static bool areNodeIDsUnique(List<Node> nodes, bool ignoreZeroIDs) {
    List<int> nodeIDs = nodes.map((n) => n.getNodeProperties().nodeID).toList();
    nodeIDs.sort();

    if (ignoreZeroIDs) {
      nodeIDs.removeWhere((id) => id == 0);
    }

    return nodeIDs.toSet().length == nodeIDs.length;
  }

  static bool areThereAnyCycles(List<Node> orderedNodes) {
    int numCycles = 0;

    for (int i = 0; i < orderedNodes.length; i++) {
      Node node = orderedNodes[i];

      for (Node inputNode in node.getDirectInputNodes()) {
        int inputPosition = orderedNodes.indexOf(inputNode);

        if (inputPosition > i) {
          numCycles++;
        }
      }
    }

    return numCycles > 0;
  }

  static NodeGraph prepareToPlay(
    Node node,
    NodeGraph? oldGraph,
    double sampleRate,
    int blockSize, {
    Function? allocateAudioBuffer,
    Function? deallocateAudioBuffer,
    bool nodeMemorySharingEnabled = false,
  }) {
    if (node == null) return NodeGraph();

    NodeGraph nodeGraph = createNodeGraph(node);
    assert(!areThereAnyCycles(nodeGraph.orderedNodes));
    assert(areNodeIDsUnique(nodeGraph.orderedNodes, true));

    PlaybackInitialisationInfo info = PlaybackInitialisationInfo(
      sampleRate: sampleRate,
      blockSize: blockSize,
      nodeGraph: nodeGraph,
      nodeGraphToReplace: oldGraph,
      allocateAudioBuffer: allocateAudioBuffer,
      deallocateAudioBuffer: deallocateAudioBuffer,
    );

    for (Node n in nodeGraph.orderedNodes) {
      n.initialise(info);
    }

    return nodeGraph;
  }

  static void reserveAudioBufferPool(
    Node rootNode,
    List<Node> allNodes,
    AudioBufferPool audioBufferPool,
    int numThreads,
    int blockSize,
  ) {
    if (rootNode == null) return;

    int maxNumChannels = 0;
    int maxNumInputs = 0;
    int numLeafNodes = 0;

    for (Node n in allNodes) {
      int numInputs = n.getDirectInputNodes().length;
      NodeProperties props = n.getNodeProperties();
      maxNumInputs = maxNumInputs > numInputs ? maxNumInputs : numInputs;
      maxNumChannels = maxNumChannels > props.numberOfChannels
          ? maxNumChannels
          : props.numberOfChannels;

      if (numInputs == 0) numLeafNodes++;
    }

    int numBuffersRequired =
        [2, allNodes.length, 1 + numThreads].reduce((a, b) => a < b ? a : b);
    audioBufferPool.reserve(
        numBuffersRequired, BufferSize.create(maxNumChannels, blockSize));
  }

  static NodeGraph createNodeGraph(Node node) {
    // Implementation to create a NodeGraph
    return NodeGraph();
  }
}
