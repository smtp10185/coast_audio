import 'package:music_core/music_core.dart';

class ClipPosition {
  final TimePosition start;
  final TimePosition end;

  ClipPosition({required this.start, required this.end});
}

class TempoSequenceSection {
  double bpm;
  TimePosition startTime;
  BeatPosition startBeat;
  double secondsPerBeat;
  double beatsPerSecond;
  double ppqAtStart;
  TimePosition timeOfFirstBar;
  BeatDuration beatsUntilFirstBar;
  int barNumberOfFirstBar;
  int numerator;
  int prevNumerator;
  int denominator;
  bool triplets;
  Key key;

  TempoSequenceSection({
    required this.bpm,
    required this.startTime,
    required this.startBeat,
    required this.secondsPerBeat,
    required this.beatsPerSecond,
    required this.ppqAtStart,
    required this.timeOfFirstBar,
    required this.beatsUntilFirstBar,
    required this.barNumberOfFirstBar,
    required this.numerator,
    required this.prevNumerator,
    required this.denominator,
    required this.triplets,
    required this.key,
  });
}

class TempoSequencePosition {
  final Sequence sequence;
  TimePosition time;
  int index = 0;

  TempoSequencePosition(this.sequence, this.time);

  double getTempo() {
    return sequence.sections[index].bpm;
  }

  TimeSignature getTimeSignature() {
    var it = sequence.sections[index];
    return TimeSignature(numerator: it.numerator, denominator: it.denominator);
  }

  Key getKey() {
    var it = sequence.sections[index];
    return it.key;
  }

  void set(TimePosition t) {
    final maxIndex = sequence.sections.length - 1;

    if (index > maxIndex) {
      index = maxIndex;
      time = sequence.sections[index].startTime;
    }

    if (t >= time) {
      while (index < maxIndex && sequence.sections[index + 1].startTime <= t) {
        ++index;
      }
    } else {
      while (index > 0 && sequence.sections[index].startTime > t) {
        --index;
      }
    }

    time = t;
  }

  TimePosition setBeat(BeatPosition t) {
    set(sequence.toTime(t));
    return time;
  }

  TimePosition addBars(int bars) {
    if (bars > 0) {
      while (--bars >= 0) {
        add(BeatDuration.fromBeats(
            sequence.sections[index].numerator.toDouble()));
      }
    } else {
      while (++bars <= 0) {
        add(BeatDuration.fromBeats(
            -sequence.sections[index].numerator.toDouble()));
      }
    }

    return time;
  }

  bool next() {
    final maxIndex = sequence.sections.length - 1;

    if (index == maxIndex) return false;

    time = sequence.sections[++index].startTime;
    return true;
  }

  TimePosition add(BeatDuration beats) {
    if (beats > BeatDuration()) {
      for (;;) {
        final maxIndex = sequence.sections.length - 1;
        final it = sequence.sections[index];
        final beatTime = TimePosition(it.secondsPerBeat.value * beats.beats);

        if (index >= maxIndex ||
            sequence.sections[index + 1].startTime > (time + beatTime)) {
          time = time + beatTime;
          break;
        }

        ++index;
        final nextStart = sequence.sections[index].startTime;
        beats =
            beats - (nextStart - time).toDuration() * it.beatsPerSecond.value;
        time = nextStart;
      }
    } else {
      for (;;) {
        final it = sequence.sections[index];
        final beatTime = it.secondsPerBeat.value * beats.beats;

        if (index <= 0 ||
            sequence.sections[index].startTime <=
                (time + TimePosition(beatTime))) {
          time = time + TimePosition(beatTime);
          break;
        }

        beats = beats +
            (time - it.startTime).toDuration() * it.beatsPerSecond.value;
        time = sequence.sections[index].startTime;
        --index;
      }
    }

    return time;
  }

  TimePosition addDuration(TimeDuration d) {
    set(time + d.toTimePosition());
    return time;
  }

  TimePosition getTimeOfNextChange() {
    if (sequence.sections.isEmpty) {
      throw Exception("No sections available in the sequence.");
    }

    final currentSectionTime = sequence.sections[index].startTime;

    for (var i = index + 1; i < sequence.sections.length; ++i) {
      if (sequence.sections[i].startTime > currentSectionTime) {
        return sequence.sections[i].startTime;
      }
    }

    return currentSectionTime;
  }

  BeatPosition getBeats() {
    final section = sequence.sections[index];
    return section.startBeat +
        ((time - section.startTime) * section.beatsPerSecond.value)
            .inBeatsPosition();
  }
}
