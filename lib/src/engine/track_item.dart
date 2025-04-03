import 'package:coast_audio/src/engine/edit_time.dart';
import 'package:coast_audio/src/engine/track.dart';
import 'package:music_core/music_core.dart';

enum TrackItemType {
  unknown,
  wave,
  midi,
  edit,
  step,
  marker,
  pitch,
  timeSig,
  collection,
  video,
  recording,
  chord,
  arranger,
  container
}

abstract class TrackItem {
  final String id;
  final TrackItemType type;

  TrackItem(this.id, this.type);

  // 定义类型枚举

  // 获取轨道
  Track getTrack();

  // 获取位置
  ClipPosition getPosition();

  // 其他方法
  bool isGrouped() => false;
  TrackItem? getGroupParent() => null;
  BeatRange getEditBeatRange();
  BeatPosition getStartBeat();
  BeatPosition getContentStartBeat();
  BeatPosition getEndBeat();
  BeatDuration getLengthInBeats();
  TimePosition getTimeOfRelativeBeat(BeatDuration);
  BeatPosition getBeatOfRelativeTime(TimeDuration);
  BeatDuration getOffsetInBeats();
  String getTrackID();
}
