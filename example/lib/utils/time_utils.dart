/// 时间工具类，用于处理时间和小节的相互转换
class TimeUtils {
  /// 每分钟节拍数
  final double bpm;

  /// 每小节拍数
  final int beatsPerBar;

  /// 以四分音符为一拍
  final int beatUnit = 4;

  TimeUtils({
    this.bpm = 120.0,
    this.beatsPerBar = 4,
  });

  /// 将秒数转换为小节格式的字符串 (例如: "1.1.00")
  /// [seconds] - 秒数
  /// 返回格式为 "小节.拍.细分" 的字符串
  String secondsToBarString(double seconds) {
    // 计算小节、拍和细分
    final Map<String, dynamic> barInfo = secondsToBarInfo(seconds);

    // 格式化为 "1.1.00" 格式的字符串
    return '${barInfo['bar']}.${barInfo['beat']}.${barInfo['ticks'].toString().padLeft(2, '0')}';
  }

  /// 将秒数转换为小节信息
  /// [seconds] - 秒数
  /// 返回包含小节、拍和细分的Map
  Map<String, dynamic> secondsToBarInfo(double seconds) {
    // 计算一拍的时长(秒)
    final double secondsPerBeat = 60.0 / bpm;

    // 计算一小节的时长(秒)
    final double secondsPerBar = secondsPerBeat * beatsPerBar;

    // 计算小节数 (从1开始)
    final int bar = (seconds / secondsPerBar).floor() + 1;

    // 计算小节内的剩余秒数
    final double remainingSeconds = seconds % secondsPerBar;

    // 计算拍数 (从1开始)
    final int beat = (remainingSeconds / secondsPerBeat).floor() + 1;

    // 计算拍内的剩余秒数
    final double remainingBeatSeconds = remainingSeconds % secondsPerBeat;

    // 将拍内剩余时间转换为0-99的细分值
    final int ticks = (remainingBeatSeconds / secondsPerBeat * 100).floor();

    return {
      'bar': bar,
      'beat': beat,
      'ticks': ticks,
    };
  }

  /// 小节信息转换为秒数
  /// [bar] - 小节数 (从1开始)
  /// [beat] - 拍数 (从1开始)
  /// [ticks] - 细分 (0-99)
  /// 返回对应的秒数
  double barToSeconds(int bar, int beat, int ticks) {
    // 计算一拍的时长(秒)
    final double secondsPerBeat = 60.0 / bpm;

    // 小节部分的秒数 (小节从1开始，所以要减1)
    final double barSeconds = (bar - 1) * beatsPerBar * secondsPerBeat;

    // 拍部分的秒数 (拍从1开始，所以要减1)
    final double beatSeconds = (beat - 1) * secondsPerBeat;

    // 细分部分的秒数
    final double tickSeconds = ticks * secondsPerBeat / 100;

    return barSeconds + beatSeconds + tickSeconds;
  }

  /// 将秒数转换为时间格式字符串 (例如: "01:23.45")
  /// [seconds] - 秒数
  /// 返回格式化的时间字符串
  String secondsToTimeString(double seconds) {
    final int minutes = seconds ~/ 60;
    final int secs = (seconds % 60).floor();
    final int millisecs = ((seconds % 1) * 100).floor();

    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}.${millisecs.toString().padLeft(2, '0')}';
  }
}
