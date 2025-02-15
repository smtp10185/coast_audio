import 'dart:async';

import 'package:coast_audio/src/engine/device.dart';
import 'package:coast_audio/src/engine/midi_message.dart';
import 'package:music_core/music_core.dart';

class MidiNoteDispatcher {
  List<DeviceState> devices = [];
  final List<MessageToSend> messagesToSend = [];

  TimePosition masterTime = TimePosition.zero();
  double hiResClockOfMasterTime = 0;
  Timer? timer;

  MidiNoteDispatcher();

  void setMidiDeviceList(List<MidiOutputDeviceInstance> newList) {
    devices = newList.map((d) => DeviceState(d)).toList();

    if (newList.isEmpty) {
      stopTimer();
    } else {
      startTimer();
    }
  }

  void dispatchPendingMessagesForDevices(TimePosition editTime) {
    for (var state in devices) {
      dispatchPendingMessages(state, editTime);
    }
  }

  void masterTimeUpdate(TimePosition editTime) {
    masterTime = editTime;
    hiResClockOfMasterTime = DateTime.now().millisecondsSinceEpoch.toDouble();
  }

  void prepareToPlay(TimePosition editTime) {
    masterTimeUpdate(editTime);
  }

  TimePosition getCurrentTime() {
    return masterTime +
        TimeDuration.fromSeconds(
                (DateTime.now().millisecondsSinceEpoch.toDouble() -
                        hiResClockOfMasterTime) *
                    0.001)
            .toTimePosition();
  }

  void dispatchPendingMessages(DeviceState state, TimePosition editTime) {
    var pendingBuffer = state.device.getPendingMessages();
    state.device.context.masterLevels.processMidi(pendingBuffer, null);
    var delay = state.device.getMidiOutput().getDeviceDelay();

    if (!state.device.sendMessages(pendingBuffer, editTime - delay)) {
      state.buffer.addAll(pendingBuffer);
      pendingBuffer.clear();
    }
  }

  void startTimer() {
    timer =
        Timer.periodic(Duration(milliseconds: 1), (_) => hiResTimerCallback());
  }

  void stopTimer() {
    timer?.cancel();
    timer = null;
  }

  void hiResTimerCallback() {
    messagesToSend.clear();

    for (var d in devices) {
      var device = d.device;
      var buffer = d.buffer;
      var midiOut = device.getMidiOutput();

      if (buffer.isAllNotesOff) {
        midiOut.sendNoteOffMessages();
      }

      while (buffer.isNotEmpty) {
        var message = buffer[0];

        var noteTime = TimePosition.fromSeconds(message.timeStamp);
        var currentTime = getCurrentTime();

        if (noteTime >
            currentTime + TimeDuration.fromSeconds(0.25).toTimePosition()) {
          buffer.remove(0);
        } else if (noteTime <= currentTime) {
          messagesToSend.add(MessageToSend(device, message));
          buffer.remove(0);
        } else {
          break;
        }
      }
    }

    for (var m in messagesToSend) {
      m.device.getMidiOutput().fireMessage(m.message);
    }
  }
}

extension on List<MidiMessage> {
  bool get isAllNotesOff => every((message) => message.isNoteOff() == false);
}

class MessageToSend {
  final MidiOutputDeviceInstance device;
  final MidiMessage message;

  MessageToSend(this.device, this.message);
}

class DeviceState {
  final MidiOutputDeviceInstance device;
  final List<MidiMessage> buffer = [];

  DeviceState(this.device);

  // 在Dart中，我们通常不需要显式的锁定机制
  // 因为Dart的事件循环模型会处理大多数并发问题
}
