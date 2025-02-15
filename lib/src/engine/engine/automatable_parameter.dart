class AutomatableParameter {
  final String paramID;
  final String paramName;
  final AutomatableEditItem automatableEditElement;
  final NormalisableRange valueRange;
  double currentValue = 0.0;
  double currentParameterValue = 0.0;
  double currentBaseValue = 0.0;
  double currentModifierValue = 0.0;
  bool isRecording = false;
  List<Listener> listeners = [];
  AutomationCurve curve = AutomationCurve();

  AutomatableParameter(this.paramID, this.paramName,
      this.automatableEditElement, this.valueRange);

  double getCurrentValue() => currentValue;

  void setParameter(double value, NotificationType nt) {
    currentParameterValue = value;
    setParameterValue(value, false);

    if (nt != NotificationType.dontSendNotification) {
      for (var listener in listeners) {
        listener.parameterChanged(this, currentValue);
      }
    }
  }

  void setParameterValue(double value, bool isFollowingCurve) {
    value = snapToState(valueRange.clipValue(value));
    currentBaseValue = value;

    if (currentModifierValue != 0.0) {
      value = snapToState(valueRange.clipValue(value + currentModifierValue));
    }

    if (currentValue != value) {
      currentValue = value;
      for (var listener in listeners) {
        listener.currentValueChanged(this);
      }
    }
  }

  void addListener(Listener listener) {
    listeners.add(listener);
  }

  void removeListener(Listener listener) {
    listeners.remove(listener);
  }

  double snapToState(double value) {
    // Implement snapping logic if needed
    return value;
  }
}

class NormalisableRange {
  final double start;
  final double end;

  NormalisableRange(this.start, this.end);

  double clipValue(double value) {
    return value.clamp(start, end);
  }
}

class AutomationCurve {
  // Implement curve logic
}

class AutomatableEditItem {
  // Implement edit item logic
}

enum NotificationType {
  dontSendNotification,
  sendNotification,
}

abstract class Listener {
  void parameterChanged(AutomatableParameter param, double newValue);
  void currentValueChanged(AutomatableParameter param);
}
