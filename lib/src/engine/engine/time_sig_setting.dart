import 'package:coast_audio/src/engine/engine/edit_time.dart';
import 'package:coast_audio/src/engine/engine/tempo_sequence.dart';
import 'package:music_core/music_core.dart';

class TimeSigSetting {
  final TempoSequence ownerSequence;
  BeatPosition startBeatNumber;
  int numerator;
  int denominator;
  bool triplets;
  TimePosition startTime;
  TimePosition endTime;

  TimeSigSetting({
    required this.ownerSequence,
    this.numerator = 4,
    this.denominator = 4,
    this.triplets = false,
  })  : startTime = TimePosition.zero(),
        endTime = TimePosition.zero(),
        startBeatNumber = BeatPosition();

  String getSelectableDescription() {
    return "Time Signature";
  }

  String getStringTimeSig() {
    return "$numerator/$denominator";
  }

  void setStringTimeSig(String s) {
    if (s.contains('/')) {
      var parts = s.split('/');
      if (parts.length == 2) {
        numerator = int.tryParse(parts[0].trim()) ?? numerator;
        denominator = int.tryParse(parts[1].trim()) ?? denominator;
      }
    }
  }

  void removeFromEdit() {
    ownerSequence.removeTimeSig(ownerSequence.indexOfTimeSig(this));
  }

  /*
  Track? getTrack() {
    return ownerSequence.edit.getTempoTrack();
  }*/

  ClipPosition getPosition() {
    ownerSequence.updateTempoDataIfNeeded();
    var s = startTime;

    var nextTimeSig =
        ownerSequence.getTimeSig(ownerSequence.indexOfTimeSig(this) + 1);
    if (nextTimeSig != null) {
      return ClipPosition(
          time: TimeRange(s, nextTimeSig.startTime), offset: TimeDuration());
    }

    return ClipPosition(
        time: TimeRange(s, s + TimePosition(1.0)), offset: TimeDuration());
  }

  String getName() {
    return getStringTimeSig();
  }

  void changed() {
    // Notify listeners or update state
  }
}
