import 'package:coast_audio/src/engine/node.dart';
import 'package:coast_audio/src/engine/node_player_utils.dart';

class NodePlayer {
  late NodeGraph graph;

  NodePlayer(Node nodeToPlay, double sampleRateToUse, int blockSizeToUse) {
    // assert(nodeToPlay != null);
    graph = NodePlayerUtils.prepareToPlay(
        nodeToPlay, null, sampleRateToUse, blockSizeToUse);
  }

  void process(ProcessContext pc) {
    // Prepare all nodes for the next block
    for (var node in graph!.orderedNodes) {
      node.prepareForNextBlock(pc.referenceSampleRange);
    }

    // Then process them all in sequence
    for (var node in graph!.orderedNodes) {
      node.process(pc.numSamples, pc.referenceSampleRange);
    }

    // Finally copy the output from the root Node to our player buffers
    var output = graph.rootNode?.getProcessedOutput();
    var numAudioChannels = output?.audio.format.channels
        .clamp(0, pc.buffers.audio.format.channels);

    if (numAudioChannels! > 0) {
      /*
      add(pc.buffers.audio.getFirstChannels(numAudioChannels),
          output.audio.getFirstChannels(numAudioChannels));*/

      pc.buffers.audio.add(output!.audio);
    }

    pc.buffers.midi.mergeFrom(output!.midi);
  }
}
