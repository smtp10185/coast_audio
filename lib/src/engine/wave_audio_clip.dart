import 'package:coast_audio/src/engine/clip.dart';

class WaveAudioClip extends Clip {
  double sourceLength;
  int currentTakeIndex;
  List<String> takes;

  WaveAudioClip({
    required String clipName,
    this.sourceLength = 0.0,
    this.currentTakeIndex = -2,
    this.takes = const [],
  }) : super(clipName: clipName);

  void addTake(String projectItemID) {
    takes.add(projectItemID);
  }

  void clearTakes() {
    takes.clear();
  }

  int getCurrentTake() {
    return currentTakeIndex;
  }

  void setCurrentTake(int takeIndex) {
    currentTakeIndex = takeIndex;
  }

  // Add other methods as needed
}
