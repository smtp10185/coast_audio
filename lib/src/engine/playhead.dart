import 'package:music_core/music_core.dart';

class SplitTimelineRange {
  final Range<int> timelineRange1;
  final Range<int>? timelineRange2;
  final bool isSplit;

  // 构造函数，只有一个时间线范围
  SplitTimelineRange.single(this.timelineRange1)
      : timelineRange2 = null,
        isSplit = false;

  // 构造函数，有两个时间线范围
  SplitTimelineRange.split(this.timelineRange1, this.timelineRange2)
      : isSplit = true;
}

class PlayHead {
  // int _position = 0;
  int _speed = 0;
  bool _looping = false;
  bool _userDragging = false;
  bool _rollInToLoop = false;
  int _scrubbingBlockLength = (0.08 * 44100).toInt();
  DateTime _userInteractionTime = DateTime.now();
  Range<int> _timelinePlayRange = Range(0, 0);
  Range<int> _referenceSampleRange = Range(0, 0);
  SyncPositions _syncPositions = SyncPositions();

  PlayHead();

  void setPosition(int newPosition) {
    if (newPosition != getPosition()) {
      _userInteraction();
    }
    overridePosition(newPosition);
  }

  void playRange(Range<int> rangeToPlay, bool looped) {
    _timelinePlayRange = rangeToPlay;
    _looping = looped && (rangeToPlay.length > 50);
    setPosition(rangeToPlay.start);
    _speed = 1;
  }

  void play() {
    setPosition(getPosition());
    _speed = 1;
  }

  void playSyncedToRange(Range<int> rangeToPlay) {
    playRange(rangeToPlay, false);
    _setSyncPositions(SyncPositions());
  }

  void stop() {
    var t = getPosition();
    _speed = 0;
    setPosition(t);
  }

  int getPosition() {
    return referenceSamplePositionToTimelinePosition(
        _referenceSampleRange.start);
  }

  int getUnloopedPosition() {
    return referenceSamplePositionToTimelinePositionUnlooped(
        _referenceSampleRange.start);
  }

  void overridePosition(int newPosition) {
    if (_looping && _rollInToLoop) {
      newPosition = newPosition.clamp(0, _timelinePlayRange.end);
    } else if (_looping) {
      newPosition = _timelinePlayRange.clipValue(newPosition);
    }

    _syncPositions = SyncPositions(
      referenceSyncPosition: _referenceSampleRange.start,
      playoutSyncPosition: newPosition,
    );
  }

  bool isPlaying() => _speed != 0;
  bool isStopped() => _speed == 0;
  bool isLooping() => _looping;
  bool isRollingIntoLoop() => _rollInToLoop;
  Range<int> getLoopRange() => _timelinePlayRange;

  void setLoopRange(bool loop, Range<int> loopRange,
      {bool updatePosition = true}) {
    if (_looping != loop || (loop && loopRange != getLoopRange())) {
      var lastPos = getPosition();
      _looping = loop;
      _timelinePlayRange = loopRange;

      if (updatePosition) {
        setPosition(lastPos);
      }
    }
  }

  void setRollInToLoop(int position) {
    _rollInToLoop = true;
    _syncPositions = SyncPositions(
      referenceSyncPosition: _referenceSampleRange.start,
      playoutSyncPosition: position.clamp(0, _timelinePlayRange.end),
    );
  }

  void setUserIsDragging(bool dragging) {
    _userInteraction();
    _userDragging = dragging;
  }

  bool isUserDragging() => _userDragging;
  DateTime getLastUserInteractionTime() => _userInteractionTime;

  void setScrubbingBlockLength(int numSamples) {
    _scrubbingBlockLength = numSamples;
  }

  int getScrubbingBlockLength() => _scrubbingBlockLength;

  int referenceSamplePositionToTimelinePosition(int referenceSamplePosition) {
    if (_userDragging) {
      return _syncPositions.playoutSyncPosition +
          ((referenceSamplePosition - _syncPositions.referenceSyncPosition) %
              _scrubbingBlockLength);
    }

    if (_looping && !_rollInToLoop) {
      return linearPositionToLoopPosition(
          referenceSamplePositionToTimelinePositionUnlooped(
              referenceSamplePosition),
          _timelinePlayRange);
    }

    return referenceSamplePositionToTimelinePositionUnlooped(
        referenceSamplePosition);
  }

  int referenceSamplePositionToTimelinePositionUnlooped(
      int referenceSamplePosition) {
    return _syncPositions.playoutSyncPosition +
        (referenceSamplePosition - _syncPositions.referenceSyncPosition) *
            _speed;
  }

  Range<int> referenceSampleRangeToSourceRangeUnlooped(
      Range<int> sourceReferenceSampleRange) {
    final syncPos = getSyncPositions();
    final start = syncPos.playoutSyncPosition +
        ((sourceReferenceSampleRange.start - syncPos.referenceSyncPosition) *
                _speed)
            .toInt();
    final end = syncPos.playoutSyncPosition +
        ((sourceReferenceSampleRange.end - syncPos.referenceSyncPosition) *
                _speed)
            .toInt();
    return Range(start, end);
  }

  static int linearPositionToLoopPosition(int position, Range<int> loopRange) {
    var loopStart = loopRange.start;
    return loopStart + ((position - loopStart) % loopRange.length);
  }

  void setReferenceSampleRange(Range<int> sampleRange) {
    _referenceSampleRange = sampleRange;

    if (_rollInToLoop && getPosition() >= _timelinePlayRange.start) {
      _rollInToLoop = false;
    }
  }

  Range<int> getReferenceSampleRange() => _referenceSampleRange;
  int getPlayoutSyncPosition() => _syncPositions.playoutSyncPosition;

  void _userInteraction() {
    _userInteractionTime = DateTime.now();
  }

  void _setSyncPositions(SyncPositions newPositions) {
    _syncPositions = newPositions;
  }

  getSyncPositions() {}
}

SplitTimelineRange referenceSampleRangeToSplitTimelineRange(
    PlayHead playHead, Range<int> referenceSampleRange) {
  final unloopedRange =
      playHead.referenceSampleRangeToSourceRangeUnlooped(referenceSampleRange);
  var s = unloopedRange.start;
  var e = unloopedRange.end;

  if (playHead.isUserDragging()) {
    final loopStart = playHead.getPlayoutSyncPosition();
    final loopLen = playHead.getScrubbingBlockLength();
    final loopEnd = loopStart + loopLen;

    s = PlayHead.linearPositionToLoopPosition(
        s, Range(loopStart, loopStart + loopLen));
    e = PlayHead.linearPositionToLoopPosition(
        e, Range(loopStart, loopStart + loopLen));

    if (s > e) {
      if (s >= loopEnd) return SplitTimelineRange.single(Range(loopStart, e));
      if (e <= loopStart) return SplitTimelineRange.single(Range(s, loopEnd));

      return SplitTimelineRange.split(Range(s, loopEnd), Range(loopStart, e));
    }
  }

  if (playHead.isLooping() && !playHead.isRollingIntoLoop()) {
    final pr = playHead.getLoopRange();
    s = PlayHead.linearPositionToLoopPosition(s, pr);
    e = PlayHead.linearPositionToLoopPosition(e, pr);

    if (s > e) {
      if (s >= pr.end) return SplitTimelineRange.single(Range(pr.start, e));
      if (e <= pr.start) return SplitTimelineRange.single(Range(s, pr.end));

      return SplitTimelineRange.split(Range(s, pr.end), Range(pr.start, e));
    }
  }

  return SplitTimelineRange.single(Range(s, e));
}

class SyncPositions {
  final int referenceSyncPosition;
  final int playoutSyncPosition;

  SyncPositions({this.referenceSyncPosition = 0, this.playoutSyncPosition = 0});
}
