import 'package:music_core/music_core.dart';

class Clip {
  String clipName;
  TimePosition clipStart;
  TimeDuration length, offset;
  bool isMuted;
  bool disabled;
  double dbGain;
  double pan;
  double fadeIn;
  double fadeOut;
  double loopStart;
  double loopLength;
  double loopStartBeats;
  double loopLengthBeats;
  String colour;
  String linkID;
  String groupID;
  bool useClipLaunchQuantisation;
  bool autoPitch;
  bool autoTempo;
  bool isReversed;
  bool warpTime;
  bool proxyAllowed;
  int transpose;
  double pitchChange;
  double beatSensitivity;
  String timeStretchMode;
  String elastiqueProOptions;
  String autoPitchMode;
  String resamplingQuality;
  String syncType;
  String followActionDurationType;
  double followActionBeats;
  double followActionNumLoops;

  Clip({
    required this.clipName,
    this.clipStart = const TimePosition(),
    this.length = const TimeDuration(),
    this.offset = const TimeDuration(),
    this.isMuted = false,
    this.disabled = false,
    this.dbGain = 0.0,
    this.pan = 0.0,
    this.fadeIn = 0.0,
    this.fadeOut = 0.0,
    this.loopStart = 0.0,
    this.loopLength = 0.0,
    this.loopStartBeats = 0.0,
    this.loopLengthBeats = 0.0,
    this.colour = '',
    this.linkID = '',
    this.groupID = '',
    this.useClipLaunchQuantisation = false,
    this.autoPitch = false,
    this.autoTempo = false,
    this.isReversed = false,
    this.warpTime = false,
    this.proxyAllowed = true,
    this.transpose = 0,
    this.pitchChange = 0.0,
    this.beatSensitivity = 0.5,
    this.timeStretchMode = '',
    this.elastiqueProOptions = '',
    this.autoPitchMode = '',
    this.resamplingQuality = '',
    this.syncType = '',
    this.followActionDurationType = '',
    this.followActionBeats = 0.0,
    this.followActionNumLoops = 0.0,
  });

  void setMuted(bool shouldBeMuted) {
    isMuted = shouldBeMuted;
  }

  bool get isClipMuted => isMuted;

  void setColour(String col) {
    colour = col;
  }

  String get getColour => colour;

  ClipPosition getPosition() {
    var start = clipStart;
    var end = start + length.toTimePosition();
    return ClipPosition.fromTimeRange(
      TimeRange(TimePosition(start.seconds), TimePosition(end.seconds)),
      TimeDuration.fromSeconds(offset.seconds),
    );
  }
}


class ClipArray {
  final List<Clip> _clips = [];

  void add(Clip clip) {
    _clips.add(clip);
  }

  void remove(Clip clip) {
    _clips.remove(clip);
  }

  Clip operator [](int index) => _clips[index];

  void operator []=(int index, Clip value) {
    _clips[index] = value;
  }

  int get length => _clips.length;
}
