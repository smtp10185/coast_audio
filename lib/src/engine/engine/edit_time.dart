import 'package:music_core/music_core.dart';

class ClipPosition {
  final TimeRange time;
  final TimeDuration offset;

  ClipPosition({required this.time, this.offset = const TimeDuration(0)});

  // 获取开始时间
  TimePosition getStart() => time.start;

  // 获取结束时间
  TimePosition getEnd() => time.end;

  // 获取长度
  TimeDuration getLength() => time.getLength();

  // 获取偏移
  TimeDuration getOffset() => offset;

  // 获取源材料在时间线上的开始
  TimePosition getStartOfSource() => time.start - offset.toTimePosition();

  // 工厂构造函数：从TimeRange和TimeDuration创建ClipPosition
  factory ClipPosition.fromTimeRange(TimeRange range, TimeDuration offset) {
    return ClipPosition(time: range, offset: offset);
  }

  // 工厂构造函数：从BeatRange和BeatDuration创建ClipPosition
  factory ClipPosition.fromBeatRange(BeatRange range, BeatDuration offset) {
    return ClipPosition(
        offset: TimeDuration(),
        time: TimeRange(TimePosition(), TimePosition()));
  }

  // 比较两个ClipPosition
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClipPosition &&
          runtimeType == other.runtimeType &&
          offset == other.offset &&
          time == other.time;

  @override
  int get hashCode => offset.hashCode ^ time.hashCode;

  // 返回一个以锚点为中心缩放的ClipPosition
  ClipPosition rescaled(TimePosition anchorTime, double factor) {
    var newStart = anchorTime + (time.start - anchorTime) * factor;
    var newEnd = anchorTime + (time.end - anchorTime) * factor;
    var newOffset = offset * factor;
    return ClipPosition(time: TimeRange(newStart, newEnd), offset: newOffset);
  }
}
