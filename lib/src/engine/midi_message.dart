class MidiMessage {
  double timeStamp;
  int noteNumber;
  double velocity;

  MidiMessage(this.timeStamp, this.noteNumber, this.velocity);

  bool isNoteOn() {
    // Implementation
    return false;
  }

  bool isNoteOff() {
    return false;
  }

  bool isNoteOnOrOff() {
    // 判断是否为Note On或Note Off消息的逻辑
    return true; // 示例值
  }

  void addToTimeStamp(double delta) {
    timeStamp += delta;
  }

  void setNoteNumber(int newNoteNumber) {
    noteNumber = newNoteNumber;
  }

  void multiplyVelocity(double factor) {
    velocity *= factor;
  }
}

class MidiMessageWithSource {
  final MidiMessage message;
  final MPESourceID mpeSourceID;

  MidiMessageWithSource(this.message, this.mpeSourceID);

  void setTimeStamp(double time) {
    message.timeStamp = time;
  }

  void addToTimeStamp(double delta) {
    message.addToTimeStamp(delta);
  }

  bool isNoteOnOrOff() {
    return message.isNoteOnOrOff();
  }
}

class MPESourceID {
  // MPESourceID的实现
}

class MidiMessageArray {
  final List<MidiMessageWithSource> messages = [];
  bool isAllNotesOff = false;

  bool isEmpty() => messages.isEmpty;
  bool isNotEmpty() => messages.isNotEmpty;
  int size() => messages.length;

  MidiMessageWithSource operator [](int i) => messages[i];

  void remove(int index) {
    messages.removeAt(index);
  }

  void swapWith(MidiMessageArray other) {
    final tempIsAllNotesOff = isAllNotesOff;
    isAllNotesOff = other.isAllNotesOff;
    other.isAllNotesOff = tempIsAllNotesOff;

    final tempMessages = List<MidiMessageWithSource>.from(messages);
    messages.clear();
    messages.addAll(other.messages);
    other.messages.clear();
    other.messages.addAll(tempMessages);
  }

  void clear() {
    isAllNotesOff = false;
    messages.clear();
  }

  void addMidiMessage(MidiMessage m, MPESourceID mpeSourceID) {
    messages.add(MidiMessageWithSource(m, mpeSourceID));
  }

  void addMidiMessageWithTime(
      MidiMessage m, double time, MPESourceID mpeSourceID) {
    final messageWithSource = MidiMessageWithSource(m, mpeSourceID);
    messageWithSource.setTimeStamp(time);
    messages.add(messageWithSource);
  }

  void add(MidiMessageWithSource m) {
    messages.add(m);
  }

  void addWithTime(MidiMessageWithSource m, double time) {
    m.setTimeStamp(time);
    messages.add(m);
  }

  void copyFrom(MidiMessageArray source) {
    clear();
    mergeFrom(source);
  }

  void mergeFrom(MidiMessageArray source) {
    isAllNotesOff = isAllNotesOff || source.isAllNotesOff;
    if (source.isEmpty()) return;
    messages.addAll(source.messages);
  }

  void mergeFromWithOffset(MidiMessageArray source, double delta) {
    isAllNotesOff = isAllNotesOff || source.isAllNotesOff;
    if (source.isEmpty()) return;
    for (var m in source.messages) {
      final copy = MidiMessageWithSource(m.message, m.mpeSourceID);
      copy.addToTimeStamp(delta);
      messages.add(copy);
    }
  }

  void mergeFromAndClear(MidiMessageArray source) {
    isAllNotesOff = isAllNotesOff || source.isAllNotesOff;
    if (isEmpty()) {
      swapWith(source);
    } else {
      messages.addAll(source.messages);
    }
    source.clear();
  }

  void mergeFromAndClearWithOffset(MidiMessageArray source, double delta) {
    isAllNotesOff = isAllNotesOff || source.isAllNotesOff;
    if (isEmpty()) {
      swapWith(source);
      addToTimestamps(delta);
    } else {
      for (var m in source.messages) {
        m.addToTimeStamp(delta);
        messages.add(m);
      }
    }
    source.clear();
  }

  void mergeFromAndClearWithOffsetAndLimit(
      MidiMessageArray source, double delta, int numItemsToTake) {
    if (numItemsToTake >= source.size()) {
      mergeFromAndClearWithOffset(source, delta);
      return;
    }
    isAllNotesOff = isAllNotesOff || source.isAllNotesOff;
    for (var i = 0; i < numItemsToTake; ++i) {
      final m = source.messages[i];
      m.addToTimeStamp(delta);
      messages.add(m);
    }
    source.messages.removeRange(0, numItemsToTake);
  }

  void removeNoteOnsAndOffs() {
    messages.removeWhere((m) => m.isNoteOnOrOff());
  }

  void addToTimestamps(double delta) {
    for (var m in messages) {
      m.addToTimeStamp(delta);
    }
  }

  void addToNoteNumbers(int delta) {
    for (var m in messages) {
      m.message.setNoteNumber(m.message.noteNumber + delta);
    }
  }

  void multiplyVelocities(double factor) {
    for (var m in messages) {
      m.message.multiplyVelocity(factor);
    }
  }

  void sortByTimestamp() {
    messages.sort((a, b) {
      final t1 = a.message.timeStamp;
      final t2 = b.message.timeStamp;
      if (t1 == t2) {
        if (a.message.isNoteOnOrOff() && !b.message.isNoteOnOrOff()) return -1;
        if (!a.message.isNoteOnOrOff() && b.message.isNoteOnOrOff()) return 1;
      }
      return t1.compareTo(t2);
    });
  }
}
