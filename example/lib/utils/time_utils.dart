import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:collection'; // For SplayTreeMap
import 'package:collection/collection.dart'; // For firstWhereOrNull

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

  /// 计算一拍的时长(秒)
  double get secondsPerBeat => bpm <= 0 ? double.infinity : 60.0 / bpm;

  /// 计算一小节的时长(秒)
  double get secondsPerBar => secondsPerBeat * beatsPerBar;

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
    // 处理负数秒
    if (seconds < 0) {
      seconds = 0;
    }
    if (secondsPerBar <= 0) {
      return {
        'bar': 1,
        'beat': 1,
        'ticks': 0,
        'secondsPerBar': secondsPerBar,
        'secondsPerBeat': secondsPerBeat,
      };
    }

    // 计算小节数 (从1开始)
    final int bar = (seconds / secondsPerBar).floor() + 1;

    // 计算小节内的剩余秒数
    final double remainingSeconds = seconds % secondsPerBar;

    // 计算拍数 (从1开始)
    final int beat = secondsPerBeat <= 0
        ? 1
        : (remainingSeconds / secondsPerBeat).floor() + 1;

    // 计算拍内的剩余秒数
    final double remainingBeatSeconds =
        secondsPerBeat <= 0 ? 0 : remainingSeconds % secondsPerBeat;

    // 将拍内剩余时间转换为0-99的细分值
    final int ticks = secondsPerBeat <= 0
        ? 0
        : (remainingBeatSeconds / secondsPerBeat * 100).floor();

    return {
      'bar': bar,
      'beat': beat,
      'ticks': ticks,
      'secondsPerBar': secondsPerBar,
      'secondsPerBeat': secondsPerBeat,
    };
  }

  /// 格式化小节显示文本，根据小节数自动选择合适的显示格式
  /// [bar] - 小节数
  /// 返回格式化的文本
  String formatBarDisplay(int bar) {
    if (bar > 999) {
      // 超过999小节时，显示为"1k"、"1.2k"的格式
      return '${(bar / 1000).toStringAsFixed(1)}k';
    } else if (bar > 99) {
      // 超过99小节时，简单显示数字
      return '$bar';
    } else {
      // 99小节以内，显示为"小节X"的格式
      return '$bar';
    }
  }

  /// 计算指定秒数包含多少个完整小节
  /// [seconds] - 秒数
  /// 返回完整小节数
  int calculateBars(double seconds) {
    return secondsPerBar <= 0 ? 0 : (seconds / secondsPerBar).floor();
  }

  /// 小节信息转换为秒数
  /// [bar] - 小节数 (从1开始)
  /// [beat] - 拍数 (从1开始)
  /// [ticks] - 细分 (0-99)
  /// 返回对应的秒数
  double barToSeconds(int bar, int beat, int ticks) {
    if (secondsPerBar <= 0 || secondsPerBeat <= 0) return 0.0;
    // 小节部分的秒数 (小节从1开始，所以要减1)
    final double barSeconds = (bar - 1) * secondsPerBar;

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

// Tempo Change Event
class TempoEvent {
  final double timeSeconds; // Time in seconds when the tempo changes
  final double bpm; // Beats per minute at this time
  final int beatsPerBar; // Beats per bar at this time

  TempoEvent({
    required this.timeSeconds,
    required this.bpm,
    this.beatsPerBar = 4,
  });
}

// Time Signature Change Event (Similar structure if needed)
// class TimeSignatureEvent { ... }

// Musical Time Representation
class MusicalTime {
  final int bar;
  final int beat;
  final int tick; // Assuming 100 ticks per beat (like percentage)

  MusicalTime({required this.bar, required this.beat, required this.tick});

  @override
  String toString() => '$bar.$beat.$tick';
}

// TimeContext State Notifier - Manages time conversions with tempo changes
class TimeContext extends StateNotifier<List<TempoEvent>> {
  // Use SplayTreeMap for efficient lookup based on time
  final SplayTreeMap<double, TempoEvent> _tempoMap;

  // Constructor initializes with a default tempo event at time 0
  TimeContext([List<TempoEvent>? initialEvents])
      : _tempoMap = SplayTreeMap<double, TempoEvent>(),
        super(initialEvents ??
            [TempoEvent(timeSeconds: 0, bpm: 120, beatsPerBar: 4)]) {
    // Default state
    // Populate the SplayTreeMap from initial events
    if (initialEvents != null) {
      for (var event in initialEvents) {
        _tempoMap[event.timeSeconds] = event;
      }
    } else {
      // Ensure the default event is in the map
      _tempoMap[0.0] = state.first;
    }
  }

  // --- Tempo Management ---

  // Add or update a tempo event
  void setTempo(double timeSeconds, double bpm, {int beatsPerBar = 4}) {
    final newEvent = TempoEvent(
        timeSeconds: timeSeconds, bpm: bpm, beatsPerBar: beatsPerBar);
    _tempoMap[timeSeconds] = newEvent;
    // Update the state (Riverpod will notify listeners)
    // Create a new list from the map values, sorted by time implicitly by SplayTreeMap
    state = _tempoMap.values.toList();
  }

  // Get the active tempo event at a specific time
  TempoEvent getTempoEventAt(double timeSeconds) {
    // Find the latest tempo event at or before the given time
    // Add a small epsilon to handle exact matches correctly with lastKeyBefore
    final entryKey = _tempoMap.lastKeyBefore(timeSeconds + 0.00001);
    if (entryKey != null) {
      return _tempoMap[entryKey]!;
    }
    // If no key before (e.g., timeSeconds is negative or before the first event), use the first event
    // Assumes there's always at least one event (typically at time 0)
    return _tempoMap.values.first;
  }

  // --- Conversion Methods ---

  // Get MusicalTime (Bar, Beat, Tick) from seconds
  MusicalTime getMusicalTime(double timeSeconds) {
    if (timeSeconds < 0) timeSeconds = 0;

    double accumulatedTime = 0.0;
    double musicalTimeBars = 0.0; // Use double for accumulation

    TempoEvent? lastEvent = null;

    // Iterate through tempo events sorted by time (guaranteed by SplayTreeMap)
    for (final entry in _tempoMap.entries) {
      final eventTime = entry.key;
      final event = entry.value;

      if (lastEvent != null) {
        // Calculate time delta from last event
        final double segmentStartTime = lastEvent.timeSeconds;
        // Determine the end of the current calculation segment
        // It's either the start of the next event or the target time, whichever comes first
        double segmentEndTime =
            eventTime < timeSeconds ? eventTime : timeSeconds;

        // Duration of the relevant part of this segment
        final double durationInSegment = segmentEndTime - segmentStartTime;

        if (durationInSegment > 0) {
          // Calculate properties based on the *previous* event's tempo
          final double lastBpm = lastEvent.bpm;
          final int lastBeatsPerBar = lastEvent.beatsPerBar;
          if (lastBpm > 0 && lastBeatsPerBar > 0) {
            final double lastSecondsPerBar = (60.0 / lastBpm) * lastBeatsPerBar;
            if (lastSecondsPerBar > 0) {
              musicalTimeBars += durationInSegment / lastSecondsPerBar;
            }
          }
          accumulatedTime += durationInSegment;
        }
      }

      lastEvent = event;

      // Stop if we've processed the segment containing or ending at the target time
      if (eventTime >= timeSeconds) break;
    }

    // Handle remaining time if target time is after the last defined tempo event
    if (accumulatedTime < timeSeconds && lastEvent != null) {
      final double remainingDuration = timeSeconds - accumulatedTime;
      final double lastBpm = lastEvent.bpm;
      final int lastBeatsPerBar = lastEvent.beatsPerBar;
      if (lastBpm > 0 && lastBeatsPerBar > 0) {
        final double lastSecondsPerBar = (60.0 / lastBpm) * lastBeatsPerBar;
        if (lastSecondsPerBar > 0) {
          musicalTimeBars += remainingDuration / lastSecondsPerBar;
        }
      }
    }

    // Now convert accumulated musicalTimeBars into Bar/Beat/Tick
    // Use the properties of the tempo active AT the target time for the final conversion
    final TempoEvent finalEvent = getTempoEventAt(timeSeconds);
    final int finalBeatsPerBar = finalEvent.beatsPerBar;
    final double finalBpm = finalEvent.bpm;

    if (finalBpm <= 0 || finalBeatsPerBar <= 0) {
      // Avoid division by zero or nonsensical results if tempo/signature is invalid
      return MusicalTime(bar: 1, beat: 1, tick: 0);
    }

    final int finalBar = musicalTimeBars.floor() + 1;
    // Fractional part represents progress into the final bar (0.0 to <1.0)
    final double fractionalBar = musicalTimeBars - (finalBar - 1);

    // Calculate beat within the bar
    final double beatsIntoBar = fractionalBar * finalBeatsPerBar;
    final int finalBeat = beatsIntoBar.floor() + 1;
    // Fractional part represents progress into the final beat (0.0 to <1.0)
    final double fractionalBeat = beatsIntoBar - (finalBeat - 1);

    // Calculate tick within the beat
    final int finalTick = (fractionalBeat * 100).floor().clamp(0, 99);

    return MusicalTime(bar: finalBar, beat: finalBeat, tick: finalTick);
  }

  // Get time in seconds from MusicalTime
  double musicalTimeToSeconds(MusicalTime musicalTime) {
    if (musicalTime.bar <= 0) return 0.0; // Handle invalid input

    double accumulatedTime = 0.0;
    double currentMusicalBars = 0.0; // Start from bar 0 (time 0)
    TempoEvent? lastEvent = null;
    final targetBarStartMusical =
        (musicalTime.bar - 1.0); // Target bar start (0-based index)

    // Iterate through tempo events to find the start time of the target bar
    for (final entry in _tempoMap.entries) {
      final eventTime = entry.key;
      final event = entry.value;

      if (lastEvent != null) {
        final double segmentStartTime = lastEvent.timeSeconds;
        final double lastBpm = lastEvent.bpm;
        final int lastBeatsPerBar = lastEvent.beatsPerBar;

        if (lastBpm > 0 && lastBeatsPerBar > 0) {
          final double lastSecondsPerBar = (60.0 / lastBpm) * lastBeatsPerBar;

          // Calculate how many bars *could* pass in this tempo segment
          double timeAvailableInSegment = eventTime - segmentStartTime;
          double barsInSegment = timeAvailableInSegment / lastSecondsPerBar;

          // How many bars are needed to reach the target bar start?
          double barsNeeded = targetBarStartMusical - currentMusicalBars;

          if (barsNeeded <= 0) break; // Already passed or reached target

          if (barsNeeded <= barsInSegment) {
            // Target bar start is reached within this segment
            double timeToReachTarget = barsNeeded * lastSecondsPerBar;
            accumulatedTime = segmentStartTime + timeToReachTarget;
            currentMusicalBars = targetBarStartMusical; // Exactly reached
            break; // Found the start time
          } else {
            // Use up the whole segment without reaching the target bar start
            accumulatedTime = eventTime;
            currentMusicalBars += barsInSegment;
          }
        } else {
          // If tempo is invalid, we can't progress time based on bars
          // Move time to the next event, but musical bars don't advance
          accumulatedTime = eventTime;
        }
      }
      lastEvent = event;
      if (currentMusicalBars >= targetBarStartMusical)
        break; // Exit if target reached
    }

    // Handle case where target bar start is after the last tempo event
    if (currentMusicalBars < targetBarStartMusical && lastEvent != null) {
      final double lastBpm = lastEvent.bpm;
      final int lastBeatsPerBar = lastEvent.beatsPerBar;
      if (lastBpm > 0 && lastBeatsPerBar > 0) {
        final double lastSecondsPerBar = (60.0 / lastBpm) * lastBeatsPerBar;
        double barsNeeded = targetBarStartMusical - currentMusicalBars;
        double timeToCoverNeededBars = barsNeeded * lastSecondsPerBar;
        accumulatedTime +=
            timeToCoverNeededBars; // Add time needed at the last known tempo
      }
      // If last tempo invalid, accumulatedTime remains at the last event time
    }

    // Now 'accumulatedTime' is the approximate start time of the target bar.
    // Add time for beats and ticks based on the tempo active *at that start time*.
    final TempoEvent activeEventAtBarStart = getTempoEventAt(accumulatedTime);
    final double activeBpm = activeEventAtBarStart.bpm;
    final int activeBeatsPerBar = activeEventAtBarStart
        .beatsPerBar; // Not directly needed here, but good context

    if (activeBpm <= 0) {
      // If tempo at bar start is invalid, cannot calculate beat/tick time
      return accumulatedTime; // Return the calculated bar start time
    }

    final double secondsPerBeat = 60.0 / activeBpm;

    double finalTime = accumulatedTime;
    // Add time for full beats (musicalTime.beat is 1-based)
    finalTime += (musicalTime.beat - 1) * secondsPerBeat;
    // Add time for ticks (musicalTime.tick is 0-99)
    finalTime += (musicalTime.tick / 100.0) * secondsPerBeat;

    return finalTime;
  }

  // Helper to get seconds per beat at a specific time
  double getSecondsPerBeatAt(double timeSeconds) {
    final event = getTempoEventAt(timeSeconds);
    return event.bpm <= 0 ? double.infinity : 60.0 / event.bpm;
  }

  // Helper to get seconds per bar at a specific time
  double getSecondsPerBarAt(double timeSeconds) {
    final event = getTempoEventAt(timeSeconds);
    final secondsPerBeat = getSecondsPerBeatAt(timeSeconds);
    // Ensure beatsPerBar is positive, otherwise secondsPerBar is meaningless
    return (secondsPerBeat == double.infinity || event.beatsPerBar <= 0)
        ? double.infinity
        : secondsPerBeat * event.beatsPerBar;
  }
}

// Riverpod Provider for TimeContext
final timeContextProvider =
    StateNotifierProvider<TimeContext, List<TempoEvent>>((ref) {
  // Initialize with a default tempo or load from storage/config
  return TimeContext([
    TempoEvent(timeSeconds: 0, bpm: 120, beatsPerBar: 4),
    // Add more initial tempo changes if needed
    // TempoEvent(timeSeconds: 60, bpm: 140), // Example: Change tempo at 60s
  ]);
});
