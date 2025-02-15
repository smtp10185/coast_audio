import 'dart:math';

import 'package:coast_audio/src/engine/midi_message.dart';

class DbTimePair {
  int time = 0;
  double dB = -100.0;

  DbTimePair({this.time = 0, this.dB = -100.0});
}

class LevelMeasurer {
  Mode mode = Mode.peakMode;
  int numActiveChannels = 1;
  bool showMidi = false;
  double levelCacheL = -100.0;
  double levelCacheR = -100.0;
  final List<Client> clients = [];

  LevelMeasurer();

  void processBuffer(List<List<double>> buffer, int start, int numSamples) {
    if (clients.isEmpty) return;

    int numChans = buffer.length.clamp(0, Client.maxNumChannels);
    numActiveChannels = numChans;
    int now = DateTime.now().millisecondsSinceEpoch;

    if (mode == Mode.peakMode) {
      for (int i = 0; i < numChans; i++) {
        double gain = buffer[i]
            .sublist(start, start + numSamples)
            .reduce((a, b) => a > b ? a : b);
        bool overloaded = gain > 0.999;
        double newDB = gainToDb(gain);

        for (var c in clients) {
          c.updateAudioLevel(i, DbTimePair(time: now, dB: newDB));

          if (overloaded) c.setOverload(i, true);

          c.setNumChannelsUsed(numChans);
        }
      }
    } else if (mode == Mode.rmsMode) {
      for (int i = 0; i < numChans; i++) {
        double gain = buffer[i]
                .sublist(start, start + numSamples)
                .reduce((a, b) => a + b) /
            numSamples;
        bool overloaded = gain > 0.999;
        double newDB = gainToDb(gain);

        for (var c in clients) {
          c.updateAudioLevel(i, DbTimePair(time: now, dB: newDB));

          if (overloaded) c.setOverload(i, true);

          c.setNumChannelsUsed(numChans);
        }
      }
    } else {
      double sum = 0, diff = 0;
      getSumAndDiff(buffer, sum, diff, start, numSamples);

      double sumDB = gainToDb(sum);
      double diffDB = gainToDb(diff);

      for (var c in clients) {
        c.updateAudioLevel(0, DbTimePair(time: now, dB: sumDB));
        c.updateAudioLevel(1, DbTimePair(time: now, dB: diffDB));

        if (sum > 0.999) c.setOverload(0, true);
        if (diff > 0.999) c.setOverload(1, true);

        c.setNumChannelsUsed(2);
      }

      numActiveChannels = 2;
    }
  }

  void processMidi(List<MidiMessage> midiBuffer) {
    if (clients.isEmpty || !showMidi) return;

    double max = 0.0;

    for (var m in midiBuffer) {
      if (m.isNoteOn()) {
        max = max > m.velocity ? max : m.velocity;
      }
    }

    int now = DateTime.now().millisecondsSinceEpoch;

    for (var c in clients) {
      c.updateMidiLevel(DbTimePair(time: now, dB: gainToDb(max)));
    }
  }

  void processMidiLevel(double level) {
    if (clients.isEmpty || !showMidi) return;

    int now = DateTime.now().millisecondsSinceEpoch;

    for (var c in clients) {
      c.updateMidiLevel(DbTimePair(time: now, dB: gainToDb(level)));
    }
  }

  void clearOverload() {
    for (var c in clients) {
      c.setClearOverload(true);
    }
  }

  void clearPeak() {
    for (var c in clients) {
      c.setClearPeak(true);
    }
  }

  void clear() {
    for (var c in clients) {
      c.reset();
    }

    levelCacheL = -100.0;
    levelCacheR = -100.0;
    numActiveChannels = 1;
  }

  void setMode(Mode m) {
    clear();
    mode = m;
  }

  void addClient(Client c) {
    if (!clients.contains(c)) {
      clients.add(c);
    }
  }

  void removeClient(Client c) {
    clients.remove(c);
  }

  void setShowMidi(bool show) {
    showMidi = show;
  }

  double gainToDb(double gain) {
    return 20 * (gain > 0 ? log(gain) / log(10) : -100.0);
  }

  void getSumAndDiff(List<List<double>> buffer, double sum, double diff,
      int start, int numSamples) {
    if (buffer.isEmpty) {
      sum = 0;
      diff = 0;
    } else {
      double s = 0;
      double lo = 1.0;
      double hi = 0.0;

      for (var channel in buffer) {
        double mag = channel
            .sublist(start, start + numSamples)
            .reduce((a, b) => a > b ? a : b);
        s += mag;
        lo = lo < mag ? lo : mag;
        hi = hi > mag ? hi : mag;
      }

      sum = s / buffer.length;
      diff = hi - lo;
    }
  }
}

class Client {
  static const int maxNumChannels = 8;
  final List<DbTimePair> audioLevels =
      List.filled(maxNumChannels, DbTimePair());
  final List<bool> overload = List.filled(maxNumChannels, false);
  DbTimePair midiLevels = DbTimePair();
  int numChannelsUsed = 0;
  bool clearOverload = true;
  bool clearPeak = true;

  int getNumChannelsUsed() {
    return numChannelsUsed;
  }

  void reset() {
    for (var l in audioLevels) {
      l.dB = -100.0;
    }

    for (var o in overload) {
      o = false;
    }

    midiLevels.dB = -100.0;
    clearOverload = true;
  }

  bool getAndClearOverload() {
    bool result = clearOverload;
    clearOverload = false;
    return result;
  }

  bool getAndClearPeak() {
    bool result = clearPeak;
    clearPeak = false;
    return result;
  }

  DbTimePair getAndClearMidiLevel() {
    DbTimePair result = midiLevels;
    midiLevels.dB = -100.0;
    return result;
  }

  DbTimePair getAndClearAudioLevel(int chan) {
    assert(chan >= 0 && chan < maxNumChannels);
    DbTimePair result = audioLevels[chan];
    audioLevels[chan].dB = -100.0;
    return result;
  }

  void setNumChannelsUsed(int numChannels) {
    numChannelsUsed = numChannels;
  }

  void setOverload(int channel, bool hasOverloaded) {
    overload[channel] = hasOverloaded;
  }

  void setClearOverload(bool clear) {
    clearOverload = clear;
  }

  void setClearPeak(bool clear) {
    clearPeak = clear;
  }

  void updateAudioLevel(int channel, DbTimePair newAudioLevel) {
    if (newAudioLevel.dB >= audioLevels[channel].dB) {
      audioLevels[channel] = newAudioLevel;
    }
  }

  void updateMidiLevel(DbTimePair newMidiLevel) {
    if (newMidiLevel.dB >= midiLevels.dB) {
      midiLevels = newMidiLevel;
    }
  }
}

enum Mode {
  peakMode,
  rmsMode,
  sumDiffMode,
}
