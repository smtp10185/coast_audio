import 'package:coast_audio/src/engine/transport_control.dart';
import 'package:music_core/music_core.dart';

class TransportState {
  bool playing = false;
  bool recording = false;
  bool safeRecording = false;
  bool discardRecordings = false;
  bool clearDevices = false;
  bool justSendMMCIfEnabled = false;
  bool canSendMMCStop = false;
  bool allowRecordingIfNoInputsArmed = false;
  bool clearDevicesOnStop = false;
  bool userDragging = false;
  bool forceVideoJump = false;
  bool rewindButtonDown = false;
  bool fastForwardButtonDown = false;
  bool updatingFromPlayHead = false;
  int lastUserDragTime = 0;
  TimePosition startTime = TimePosition(0);
  TimePosition endTime = TimePosition(0);
  double videoPosition = 0.0;
  int reallocationInhibitors = 0;
  int playbackContextAllocation = 0;
  int nudgeLeftCount = 0;
  int nudgeRightCount = 0;

  final TransportControl transport;

  TransportState(this.transport);

  void setVideoPosition(double time, bool forceJump) {
    forceVideoJump = forceJump;
    videoPosition = time;
  }

  void play(bool justSendMMCIfEnabled) {
    this.justSendMMCIfEnabled = justSendMMCIfEnabled;
    playing = true;
    transport.performPlay();
  }

  void record(bool justSendMMCIfEnabled, bool allowRecordingIfNoInputsArmed) {
    this.justSendMMCIfEnabled = justSendMMCIfEnabled;
    this.allowRecordingIfNoInputsArmed = allowRecordingIfNoInputsArmed;
    recording = true;
  }

  void stop(bool discardRecordings, bool clearDevices, bool canSendMMCStop) {
    this.discardRecordings = discardRecordings;
    this.clearDevices = clearDevices;
    this.canSendMMCStop = canSendMMCStop;
    playing = false;
  }

  void updatePositionFromPlayhead(double newPosition) {
    updatingFromPlayHead = true;
    // Update position logic here
    updatingFromPlayHead = false;
  }

  void nudgeLeft() {
    nudgeLeftCount = (nudgeLeftCount + 1) % 2;
  }

  void nudgeRight() {
    nudgeRightCount = (nudgeRightCount + 1) % 2;
  }

  // Add other methods and logic as needed
}
