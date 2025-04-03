import 'package:coast_audio/src/engine/engine/edit.dart';
import 'package:coast_audio/src/engine/engine/tempo_sequence.dart';
import 'package:coast_audio/src/engine/engine/time_sig_setting.dart';
import 'package:music_core/music_core.dart';

class TempoSetting {
  static const double minBPM = 20.0;
  static const double maxBPM = 300.0;

  final TempoSequence ownerSequence;
  BeatPosition startBeatNumber = BeatPosition();
  double bpm = 120;
  double curve = 0.0;
  TimePosition startTime;

  TempoSetting(this.ownerSequence) : startTime = TimePosition();

  Edit getEdit() {
    return ownerSequence.edit;
  }

  String getSelectableDescription() {
    return "Tempo";
  }

  TimePosition getStartTime() {
    ownerSequence.updateTempoDataIfNeeded();
    return startTime;
  }

  void set(BeatPosition newStartBeat, double newBPM, double newCurve,
      bool remapEditPositions) {
    newBPM = newBPM.clamp(minBPM, maxBPM);
    newCurve = newCurve.clamp(-1.0, 1.0);

    if (newBPM != bpm || startBeatNumber != newStartBeat || curve != newCurve) {
      var snap = EditTimecodeRemapperSnapshot();

      if (remapEditPositions) {
        snap.savePreChangeState(getEdit());
      }

      bpm = newBPM;
      curve = newCurve;
      startBeatNumber = newStartBeat;

      changed();

      if (remapEditPositions) {
        snap.remapEdit(getEdit());
      }
    }
  }

  void setStartBeat(BeatPosition b) {
    set(b, bpm, curve, false);
  }

  void setBpm(double newBpm) {
    set(startBeatNumber, newBpm, curve, true);
  }

  void setCurve(double newCurve) {
    set(startBeatNumber, bpm, newCurve, true);
  }

  TimeDuration getApproxBeatLength() {
    return TimeDuration.fromSeconds(
        240.0 / (bpm * getMatchingTimeSig().denominator));
  }

  void removeFromEdit() {
    ownerSequence.removeTempo(ownerSequence.indexOfTempo(this));
  }

  TempoSetting? getPreviousTempo() {
    return ownerSequence.getTempo(ownerSequence.indexOfTempo(this) - 1);
  }

  TimeSigSetting getMatchingTimeSig() {
    return ownerSequence.getTimeSigAtBeat(startBeatNumber);
  }

  int getHash() {
    return (startBeatNumber.inBeats() * 128.0).toInt() ^
        (bpm * 1217.0).toInt() + (curve * 1023.0).toInt();
  }

  void changed() {
    // Notify listeners or update state
  }

  static TempoSetting create(TempoSequence ownerSequence, BeatPosition beatNum,
      double bpm, double curve) {
    var tempoSetting = TempoSetting(ownerSequence);
    tempoSetting.bpm = bpm;
    tempoSetting.curve = curve;
    tempoSetting.startBeatNumber = beatNum;
    return tempoSetting;
  }
}
