import 'package:coast_audio/src/engine/clip.dart';

class MidiClip extends Clip {
  bool mpeMode;
  String grooveTemplate;
  double grooveStrength;
  List<String> channelSequence;

  MidiClip({
    required String clipName,
    this.mpeMode = false,
    this.grooveTemplate = '',
    this.grooveStrength = 0.0,
    this.channelSequence = const [],
  }) : super(clipName: clipName);

  void setMPEMode(bool shouldUseMPE) {
    mpeMode = shouldUseMPE;
  }

  bool getMPEMode() {
    return mpeMode;
  }

  void setGrooveTemplate(String templateName) {
    grooveTemplate = templateName;
  }

  String getGrooveTemplate() {
    return grooveTemplate;
  }

  void setGrooveStrength(double strength) {
    grooveStrength = strength.clamp(0.0, 1.0);
  }

  double getGrooveStrength() {
    return grooveStrength;
  }

  // Add other methods as needed
}
