import 'package:coast_audio/src/engine/playhead.dart';
import 'package:coast_audio/src/engine/transport_control.dart';
import 'package:music_core/music_core.dart';

class PlayHeadWrapper {
  final TransportControl transport;

  PlayHeadWrapper(this.transport);

  PlayHead? getNodePlayHead() {
    return transport.playbackContext.getNodePlayHead();
  }

  double getSampleRate() {
    return transport.playbackContext.getSampleRate();
  }

  void play() {
    getNodePlayHead()?.play();
  }

  void playByRange(TimeRange timeRange, bool looped) {
    getNodePlayHead()?.playRange(
        Range.timeRangeToSampleRange(timeRange, getSampleRate()), looped);
  }

  void setRollInToLoop(TimePosition prerollStartTime) {
    getNodePlayHead()?.setRollInToLoop(
        toSamplesFromTimePosition(prerollStartTime, getSampleRate()));
  }

  void stop() {
    getNodePlayHead()?.stop();
  }

  bool isPlaying() {
    if (transport.playbackContext?.isPlayPending() ?? false) {
      return true;
    }
    return getNodePlayHead()?.isPlaying() ?? false;
  }

  TimePosition getLiveTransportPosition() {
    if (getNodePlayHead() != null &&
        transport.playbackContext != null &&
        transport.playbackContext!.isPlaybackGraphAllocated()) {
      return transport.playbackContext!.getAudibleTimelineTime();
    }
    return getPosition();
  }

  TimePosition getPosition() {
    return TimePosition.fromSamples(
        getNodePlayHead()?.getPosition() ?? 0, getSampleRate());
  }

  TimePosition getUnloopedPosition() {
    return TimePosition.fromSamples(
        getNodePlayHead()?.getUnloopedPosition() ?? 0, getSampleRate());
  }

  void setPosition(TimePosition newPos) {
    transport.playbackContext.postPosition(newPos, null);
  }

  void postPlay() {
    transport.playbackContext?.postPlay();
  }

  bool isLooping() {
    return getNodePlayHead()?.isLooping() ?? false;
  }

  TimeRange getLoopTimes() {
    return TimeRange.fromSamples(
        getNodePlayHead()?.getLoopRange() ?? Range(0, 0), getSampleRate());
  }

  void setLoopTimes(bool loop, TimeRange newRange) {
    getNodePlayHead()
        ?.setLoopRange(loop, TimeRange.toSamples(newRange, getSampleRate()));
  }

  void setUserIsDragging(bool isDragging) {
    getNodePlayHead()?.setUserIsDragging(isDragging);
  }
}
