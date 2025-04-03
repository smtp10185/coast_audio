import 'package:coast_audio/coast_audio.dart';
import 'package:coast_audio/src/engine/engine/automatable_edit_item.dart';
import 'package:coast_audio/src/engine/engine/track.dart';
/*
List<AutomatableEditItem> getAllAutomatableEditItems(Edit edit) {
  List<AutomatableEditItem> destArray = [];

  var globalMacroList = edit.getGlobalMacros().getMacroParameterList();
  if (globalMacroList != null) {
    destArray.add(globalMacroList);
  }

  edit.visitAllTracksRecursive((Track t) {
    if (t is MacroParameterElement) {
      var macroList = t.getMacroParameterList();
      if (macroList != null) {
        destArray.add(macroList);
      }
    }

    destArray.addAll(t.getAllAutomatableEditItems());
    return true;
  });

  for (var plugin in edit.getMasterPluginList()) {
    var macroList = plugin.getMacroParameterList();
    if (macroList != null) {
      destArray.add(macroList);
    }
    destArray.add(plugin);
  }

  for (var rackType in edit.getRackList().getTypes()) {
    for (var plugin in rackType.getPlugins()) {
      destArray.add(plugin);

      var macroList = plugin.getMacroParameterList();
      if (macroList != null) {
        destArray.add(macroList);
      }
    }

    var rackMacroList = rackType.getMacroParameterList();
    if (rackMacroList != null) {
      destArray.add(rackMacroList);
    }

    destArray.addAll(rackType.getModifierList().getModifiers());
  }

  var masterVolumePlugin = edit.getMasterVolumePlugin();
  if (masterVolumePlugin != null) {
    destArray.add(masterVolumePlugin);
  }

  return destArray;
}*/