import 'dart:io';

import 'package:coast_audio/src/engine/engine/tempo_sequence.dart';
import 'package:coast_audio/src/engine/engine/transport_control.dart';
import 'package:coast_audio/src/engine/track.dart';
import 'package:coast_audio/src/engine/track_list.dart';
import 'package:music_core/music_core.dart';
import 'package:synchronized/synchronized.dart';

typedef FileRetriever = File Function();
typedef FilePathResolver = File Function(String path);

class Edit {
  static double maximumLength = 48.0 * 60.0 * 60.0;

  FileRetriever editFileRetriever = _defaultEditFileRetriever;
  FilePathResolver filePathResolver = _defaultFilePathResolver;

  final TrackList trackList;
  final EditRole editRole;

  TimePosition clickMark1Time = TimePosition.zero();
  TimePosition clickMark2Time = TimePosition.zero();

  late TempoSequence tempoSequence;
  late TransportControl transportControl;

  final List<ModifierTimer> modifierTimers = [];
  final Lock _lock = Lock();

  Edit.newEdit()
      : trackList = TrackList(),
        editRole = EditRole.playEnabled;

  Edit({required this.trackList, required this.editRole}) {
    tempoSequence = TempoSequence(this);
  }

  get engine => null;

  bool shouldPlay() {
    return editRole == EditRole.playDisabled ? true : false;
  }

  static TimePosition getMaximumEditEnd() {
    return getMaximumEditTimeRange().getEnd();
  }

  static TimeRange getMaximumEditTimeRange() {
    return TimeRange(TimePosition(), TimePosition(maximumLength));
  }

  static TimeDuration getMaximumLength() {
    return TimeDuration(maximumLength);
  }

  void updateModifierTimers(TimePosition editTime, int numSamples) {
    // 在Dart中，List的操作是线程安全的，不需要显式锁定
    for (var mt in modifierTimers) {
      mt.updateStreamTime(editTime, numSamples);
    }
  }

  void setClickTrackRange(TimeRange newTimes) {
    clickMark1Time = newTimes.getStart();
    clickMark2Time = newTimes.getEnd();
  }

  void addModifierTimer(ModifierTimer timer) {
    _lock.synchronized(() {
      modifierTimers.add(timer);
    });
  }

  Track? getTempoTrack() {}

  void getTransport() {
    return transportControl;
  }

  void getAllAutomatableEditItems() {}

  static File _defaultEditFileRetriever() {
    // 在这里实现获取编辑文件的默认逻辑
    // 例如，返回一个默认的文件路径
    return File('/path/to/default/edit/file.txt');
  }

  static File _defaultFilePathResolver(String path) {
    if (path.isEmpty) {
      throw ArgumentError('Path cannot be empty');
    }

    if (File(path).isAbsolute) {
      return File(path);
    }

    // 使用默认的editFileRetriever来解析相对路径
    var editFile = _defaultEditFileRetriever();
    return File('${editFile.parent.path}/$path');
  }

  getClipTracks() {}

  /**
   * void updateModifierTimers(double editTime, int numSamples) {
    _lock.synchronized(() {
      for (var timer in modifierTimers) {
        timer.updateStreamTime(editTime, numSamples);
      }
    });
  } */
}

enum EditRole { playEnabled, playDisabled, recordEnabled, recordDisabled }

class ModifierTimer {
  void updateStreamTime(TimePosition editTime, int numSamples) {
    // 更新流时间的逻辑
  }
}

/*
List<ClipTrack> getClipTracks(Edit edit) {
  return getTracksOfType<ClipTrack>(edit, true);
}

List<T> getTracksOfType<T extends Track>(Edit edit, bool recursive) {
  List<T> result = [];

  edit.visitAllTracks((Track t) {
    if (t is T) {
      result.add(t);
    }
  }, recursive);

  return result;
}*/