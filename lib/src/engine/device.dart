import 'package:music_core/src/time/time.dart';

class InputDeviceInstance {}

class OutputDeviceInstance {}

class MidiOutputDeviceInstance {
  get context => null;

  void prepareToPlay(TimePosition start, bool bool) {}

  void start() {}

  getPendingMessages() {}

  getMidiOutput() {}

  bool sendMessages(pendingBuffer, TimePosition timePosition) {
    return true;
  }
}

class WaveOutputDeviceInstance {
  void prepareToPlay(double sampleRate, int blockSize) {}
}
