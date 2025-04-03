import 'package:coast_audio/coast_audio.dart';
import 'package:coast_audio/src/engine/automation_curve.dart';
import 'package:coast_audio/src/engine/clip.dart';
import 'package:coast_audio/src/engine/clip_owner.dart';
import 'package:coast_audio/src/engine/core/tempo.dart';
import 'package:coast_audio/src/engine/engine/tempo_setting.dart';
import 'package:coast_audio/src/engine/engine/time_sig_setting.dart';

import 'package:music_core/music_core.dart';
// ignore: implementation_imports

class TempoSequence {
  late Edit edit;

  List<TempoSetting> tempos = [];
  List<TimeSigSetting> timeSigs = [];

  // 初始化 internalSequence
  Sequence internalSequence = Sequence(
    tempoChanges: [
      TempoChange(
        startBeat: BeatPosition(),
        bpm: 120.0,
        curve: 0.0,
      )
    ],
    // tempoChanges
    timeSigChanges: [
      TimeSigChange(
        startBeat: BeatPosition(),
        numerator: 4,
        denominator: 4,
        triplets: false,
      )
    ], // timeSigChanges

    keyChanges: [
      KeyChange(
        startBeat: BeatPosition(),
        key: Key(),
      )
    ], // keyChanges
    lengthOfOneBeat: LengthOfOneBeat.dependsOnTimeSignature, // lengthOfOneBeat
  );

  TempoSequence(this.edit);

  int getNumTempos() => tempos.length;
  int getNumTimeSigs() => timeSigs.length;

  TempoSetting getTempo(int index) => tempos[index];
  TimeSigSetting getTimeSig(int index) => timeSigs[index];

  double getBpmAt(TimePosition time) {
    if (tempos.isEmpty) return 120.0; // Default BPM
    return tempos
        .lastWhere((t) => t.startBeatNumber.inBeats() <= time.inSeconds())
        .bpm;
  }

  void removeTempo(int index) {
    if (index > 0 && index < tempos.length) {
      tempos.removeAt(index);
    }
  }

  void removeTimeSig(int index) {
    if (index > 0 && index < timeSigs.length) {
      timeSigs.removeAt(index);
    }
  }

  BeatPosition toBeats(TimePosition time) {
    return BeatPosition(time.inSeconds() * getBpmAt(time) / 60.0);
  }

  TimePosition toTime(BeatPosition beats) {
    return TimePosition(beats.inBeats() * 60.0 / getBpmAt(TimePosition(0)));
  }

  TimeSigSetting getTimeSigAt(TimePosition time) {
    return timeSigs[indexOfTimeSigAt(time)];
  }

  int indexOfTimeSigAt(TimePosition t) {
    for (int i = getNumTimeSigs() - 1; i >= 0; i--) {
      if (timeSigs[i].startTime <= t) {
        return i;
      }
    }
    assert(timeSigs.isNotEmpty);
    return 0;
  }

  TimeSigSetting getTimeSigAtBeat(BeatPosition startBeatNumber) {
    for (var i = timeSigs.length - 1; i >= 0; i--) {
      if (timeSigs[i].startBeatNumber <= startBeatNumber) {
        return timeSigs[i];
      }
    }
    return timeSigs.first;
  }

  TempoSetting getTempoAt(TimePosition time) {
    if (tempos.isEmpty) return TempoSetting(this);
    return tempos.lastWhere(
        (t) => t.startBeatNumber.inBeats() <= toBeats(time).inBeats());
  }

  // 插入节拍，使用时间
  TempoSetting insertTempo(
      {TimePosition? time, BeatPosition? beatNum, double? bpm, double? curve}) {
    if (time != null) {
      bpm ??= getBpmAt(time);
      double defaultCurve = 1.0;

      if (getNumTempos() > 0) {
        return _insertTempo(
            roundToNearestBeat(toBeats(time)), bpm, defaultCurve);
      }

      return _insertTempo(BeatPosition(), bpm, defaultCurve);
    } else if (beatNum != null && bpm != null && curve != null) {
      return _insertTempo(beatNum, bpm, curve);
    } else {
      throw ArgumentError('Invalid arguments for insertTempo');
    }
  }

  // 内部方法用于插入节拍
  TempoSetting _insertTempo(BeatPosition beatNum, double bpm, double curve) {
    int index = tempos.indexWhere((t) => t.startBeatNumber > beatNum);

    TempoSetting newTempo = TempoSetting.create(this, beatNum, bpm, curve);

    if (index == -1) {
      tempos.add(newTempo);
    } else {
      tempos.insert(index, newTempo);
    }

    return getTempoAtBeat(beatNum);
  }

  void insertTimeSig(
      BeatPosition beatNum, int numerator, int denominator, bool triplets) {
    //addTimeSig(beatNum, numerator, denominator, triplets);
  }

  void updateTempo(int index, double bpm, double curve) {
    if (index >= 0 && index < tempos.length) {
      tempos[index].bpm = bpm;
      tempos[index].curve = curve;
    }
  }

  void updateTimeSig(int index, int numerator, int denominator, bool triplets) {
    if (index >= 0 && index < timeSigs.length) {
      timeSigs[index].numerator = numerator;
      timeSigs[index].denominator = denominator;
      timeSigs[index].triplets = triplets;
    }
  }

  int createHashForTemposInRange(TimeRange range) {
    int hash = 0;
    for (var tempo in tempos) {
      if (range.containsPosition(toTime(tempo.startBeatNumber))) {
        hash ^= tempo.hashCode;
      }
    }
    return hash;
  }

  void updateTempoDataIfNeeded() {
    // Implement logic to update tempo data if needed
  }

  int indexOfTempo(TempoSetting tempoSetting) {
    return tempos.indexOf(tempoSetting);
  }

  Sequence getInternalSequence() {
    return internalSequence;
  }

  void updateTempoData() {
    // 确保有节拍和时间签名
    assert(getNumTempos() > 0 && getNumTimeSigs() > 0);

    // 构建新的序列
    List<TempoChange> tempoChanges = [];
    List<TimeSigChange> timeSigChanges = [];
    List<KeyChange> keyChanges = [];

    // 复制变化事件
    for (var ts in tempos) {
      tempoChanges.add(TempoChange(
        startBeat: ts.startBeatNumber,
        bpm: ts.bpm,
        curve: ts.curve,
      ));
    }

    for (var ts in timeSigs) {
      timeSigChanges.add(TimeSigChange(
        startBeat: ts.startBeatNumber,
        numerator: ts.numerator,
        denominator: ts.denominator,
        triplets: ts.triplets,
      ));
    }

    /*
    for (var pc in edit.pitchSequence.getPitches()) {
      keyChanges.add(KeyChange(
        startBeat: pc.startBeat,
        key: Key(pc.pitch, pc.scale),
      ));
    }*/

    bool useDenominator = edit.engine
        .getEngineBehaviour()
        .lengthOfOneBeatDependsOnTimeSignature();
    Sequence newSeq = Sequence(
      tempoChanges: tempoChanges,
      timeSigChanges: timeSigChanges,
      keyChanges: keyChanges,
      lengthOfOneBeat: useDenominator
          ? LengthOfOneBeat.dependsOnTimeSignature
          : LengthOfOneBeat.isAlwaysACrotchet,
    );

    // 更新模型对象的startTime属性
    for (var ts in tempos) {
      ts.startTime = newSeq.toTime(ts.startBeatNumber);
    }

    for (var ts in timeSigs) {
      ts.startTime = newSeq.toTime(ts.startBeatNumber);
    }

    assert(getNumTempos() > 0 && getNumTimeSigs() > 0);

    // 更新内部序列
    internalSequence = newSeq;
  }

  int indexOfTimeSig(TimeSigSetting timeSigSetting) {
    return timeSigs.indexOf(timeSigSetting);
  }

  TempoSetting getTempoAtBeat(BeatPosition beat) {
    for (var i = tempos.length - 1; i >= 0; i--) {
      if (tempos[i].startBeatNumber <= beat) {
        return tempos[i];
      }
    }

    assert(tempos.isNotEmpty);
    return tempos.first;
  }
  // Additional methods to manipulate tempos and time signatures
}

class EditTimecodeRemapperSnapshot {
  List<ClipPos> clips = [];
  List<AutomationPos> automation = [];
  late BeatRange loopPositionBeats;
  late BeatPosition startPositionBeats;

  void savePreChangeState(Edit edit) {
    var tempoSequence = edit.tempoSequence;
    clips.clear();

    void addClip(Clip clip) {
      var pos = clip.getPosition();

      var cp = ClipPos(
        clip: clip,
        startBeat: tempoSequence.toBeats(pos.start),
        endBeat: tempoSequence.toBeats(pos.end),
        contentStartBeat: tempoSequence.toBeats(pos.startOfSource).toDuration(),
      );

      clips.add(cp);
    }

    for (var track in edit.getClipTracks()) {
      for (var clip in track.getClips()) {
        addClip(clip);

        if (clip is ClipOwner) {
          for (var childClip in clip.getClips()) {
            addClip(childClip);
          }
        }
      }

      /* Live逻辑 暂时不用 */
      /*
      if (track is AudioTrack) {
        for (var slot in track.getClipSlotList().getClipSlots()) {
          var cc = slot.getClip();
          if (cc != null) {
            addClip(cc);
          }
        }
      }*/
    }

    automation.clear();

    /* 控制器逻辑 暂时不用 */
    /*
    for (var aei in edit.getAllAutomatableEditItems()) {
      if (aei == null) continue;

      for (var ap in aei.getAutomatableParameters()) {
        if (!ap.automatableEditElement.remapOnTempoChange) continue;

        var curve = ap.getCurve();
        var numPoints = curve.getNumPoints();

        if (numPoints == 0) continue;

        var beats = <BeatPosition>[];
        for (var p = 0; p < numPoints; ++p) {
          beats.add(tempoSequence.toBeats(curve.getPoint(p).time));
        }

        automation.add(AutomationPos(curve: curve, beats: beats));
      }
    }*/

    var loopRange = edit.getTransport().getLoopRange();
    loopPositionBeats = BeatRange(
      tempoSequence.toBeats(loopRange.start),
      tempoSequence.toBeats(loopRange.end),
    );

    startPositionBeats =
        tempoSequence.toBeats(edit.getTransport().startPosition);
  }

  void remapEdit(Edit edit) {
    var transport = edit.getTransport();
    var tempoSequence = edit.tempoSequence;
    tempoSequence.updateTempoData();

    transport.startPosition = tempoSequence.toTime(startPositionBeats);
    transport.setLoopRange(
      TimeRange(
        tempoSequence.toTime(loopPositionBeats.start),
        tempoSequence.toTime(loopPositionBeats.end),
      ),
    );

    for (var cp in clips) {
      var c = cp.clip;
      if (c != null) {
        var newStart = tempoSequence.toTime(cp.startBeat);
        var newEnd = tempoSequence.toTime(cp.endBeat);
        var newOffset = newStart - tempoSequence.toTime(cp.contentStartBeat);

        var pos = c.getPosition();

        if ((pos.start - newStart).inSeconds.abs() +
                (pos.end - newEnd).inSeconds.abs() +
                (pos.offset - newOffset).inSeconds.abs() >
            0.001) {
          if (c.getSyncType() == Clip.syncAbsolute) continue;

          if (c.type == TrackItemType.wave) {
            var ac = c as AudioClipBase?;

            if (ac != null && ac.getAutoTempo()) {
              c.setPosition(TempoSequencePosition(newStart, newEnd, newOffset));
            } else {
              c.setStart(newStart, false, true);
            }
          } else {
            c.setPosition(TempoSequencePosition(newStart, newEnd, newOffset));
          }
        }
      }
    }

    for (var a in automation) {
      for (var i = a.beats.length - 1; i >= 0; i--) {
        a.curve.setPointTime(i, tempoSequence.toTime(a.beats[i]));
      }
    }
  }
}

class AudioTrack {}

class ClipPos {
  Clip clip;
  BeatPosition startBeat;
  BeatPosition endBeat;
  BeatDuration contentStartBeat;

  ClipPos(
      {required this.clip,
      required this.startBeat,
      required this.endBeat,
      required this.contentStartBeat});
}

class AutomationPos {
  AutomationCurve curve;
  List<BeatPosition> beats;

  AutomationPos({required this.curve, required this.beats});
}
