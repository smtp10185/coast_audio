import 'package:coast_audio/coast_audio.dart';
import 'package:coast_audio/src/engine/engine/automatable_parameter.dart';
import 'package:music_core/music_core.dart';
/*
class AutomatableEditItem {
  final Edit edit;
  final Map<String, dynamic> elementState = {};
  List<AutomatableParameter> automatableParams = [];
  List<AutomatableParameter> activeParameters = [];
  bool automationActive = false;
  int systemTimeOfLastPlayedBlock = 0;
  TimePosition lastTime = TimePosition();
  ParameterChangeListeners? parameterChangeListeners;

  AutomatableEditItem(this.edit);

  void flushPluginStateToValueTree() {
    saveChangedParametersToState();
  }

  List<AutomatableParameter> getAutomatableParameters() {
    return List.from(automatableParams);
  }

  int getNumAutomatableParameters() {
    return automatableParams.length;
  }

  AutomatableParameter? getAutomatableParameterByID(String paramID) {
    return automatableParams.firstWhere((p) => p.paramID == paramID, orElse: () => null);
  }

  void visitAllAutomatableParams(void Function(AutomatableParameter) visit) {
    for (var p in automatableParams) {
      visit(p);
    }
  }

  void deleteParameter(AutomatableParameter p) {
    automatableParams.remove(p);
    rebuildParameterTree();
  }

  void deleteAutomatableParameters() {
    automatableParams.clear();
    activeParameters.clear();
    automationActive = false;
    sendListChangeMessage();
  }

  int indexOfAutomatableParameter(AutomatableParameter param) {
    return automatableParams.indexOf(param);
  }

  AutomatableParameterTree getParameterTree() {
    if (!parameterTreeBuilt) {
      buildParameterTree();
      sendListChangeMessage();
    }
    return parameterTree;
  }

  List<AutomatableParameter> getFlattenedParameterTree() {
    return parameterTree.flatten();
  }

  bool isAutomationNeeded() {
    return automationActive;
  }

  void setAutomatableParamPosition(TimePosition time) {
    if (lastTime != time) {
      lastTime = time;
      if (edit.getAutomationRecordManager().isReadingAutomation()) {
        updateAutomatableParamPosition(time);
      }
    }
  }

  bool isBeingActivelyPlayed() {
    return DateTime.now().millisecondsSinceEpoch < systemTimeOfLastPlayedBlock + 150;
  }

  void updateAutomatableParamPosition(TimePosition time) {
    for (var p in automatableParams) {
      if (p.isAutomationActive()) {
        p.updateToFollowCurve(time);
      }
    }
  }

  void updateParameterStreams(TimePosition time) {
    for (var p in activeParameters) {
      p.updateFromAutomationSources(time);
    }
  }

  void resetRecordingStatus() {
    for (var p in automatableParams) {
      p.resetRecordingStatus();
    }
  }

  void buildParameterTree() {
    parameterTree.clear();
    for (var p in automatableParams) {
      parameterTree.addParameter(p);
    }
    parameterTreeBuilt = true;
  }

  void updateLastPlaybackTime() {
    systemTimeOfLastPlayedBlock = DateTime.now().millisecondsSinceEpoch;
  }

  void clearParameterList() {
    automatableParams.clear();
    rebuildParameterTree();
  }

  void addAutomatableParameter(AutomatableParameter param) {
    automatableParams.add(param);
    rebuildParameterTree();
  }

  void rebuildParameterTree() {
    parameterTree.clear();
    parameterTreeBuilt = false;
  }

  void updateActiveParameters() {
    activeParameters = automatableParams.where((p) => p.isAutomationActive()).toList();
    automationActive = activeParameters.isNotEmpty;
    lastTime = TimePosition();
  }

  void saveChangedParametersToState() {
    var changedParams = <String, double>{};
    for (var ap in automatableParams) {
      if (ap.getCurrentValue() != ap.getCurrentExplicitValue()) {
        changedParams[ap.paramID] = ap.getCurrentExplicitValue();
      }
    }
    elementState['parameters'] = changedParams;
  }

  void restoreChangedParametersFromState() {
    var params = elementState['parameters'] as Map<String, double>?;
    if (params != null) {
      for (var entry in params.entries) {
        var ap = getAutomatableParameterByID(entry.key);
        if (ap != null) {
          ap.setParameter(entry.value);
        }
      }
    }
  }

  void sendListChangeMessage() {
    parameterChangeListeners?.triggerAsyncUpdate();
  }

  void addParameterListChangeListener(ParameterListChangeListener l) {
    parameterChangeListeners ??= ParameterChangeListeners(this);
    parameterChangeListeners!.listeners.add(l);
  }

  void removeParameterListChangeListener(ParameterListChangeListener l) {
    parameterChangeListeners?.listeners.remove(l);
  }
}
*/