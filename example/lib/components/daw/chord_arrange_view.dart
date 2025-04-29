import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/track.dart';
import '../../models/clip.dart' as model_clip;
import '../../providers/daw_providers.dart';
import 'timeline_ruler.dart';
import 'track_item.dart';
import 'dart:math' as Math;
import 'package:collection/collection.dart'; // Import for firstWhereOrNull
import '../../utils/note_duration.dart'; // Assuming we create this enum
import '../../utils/time_utils.dart'; // Import TimeContext for duration calculation

/// A Dialog content widget for arranging and editing chords.
class ChordArrangeView extends ConsumerStatefulWidget {
  const ChordArrangeView({super.key});

  @override
  ConsumerState<ChordArrangeView> createState() => _ChordArrangeViewState();
}

class _ChordArrangeViewState extends ConsumerState<ChordArrangeView> {
  model_clip.Clip? _selectedClipForEditing;
  // TextEditingController for inline editing
  final TextEditingController _nameEditingController = TextEditingController();

  @override
  void dispose() {
    _nameEditingController.dispose();
    super.dispose();
  }

  // Find chord track (keep the robust logic)
  Track? _findChordTrack(List<Track> tracks) {
    return tracks.firstWhereOrNull((t) => t.type == TrackType.chord);
  }

  int _findChordTrackIndex(List<Track> tracks) {
    return tracks.indexWhere((t) => t.type == TrackType.chord);
  }

  @override
  Widget build(BuildContext context) {
    final tracks = ref.watch(tracksProvider);
    final chordTrack = _findChordTrack(tracks);
    final chordTrackIndex = _findChordTrackIndex(tracks);
    // Get TimeContext for duration calculations
    final timeContext = ref.read(timeContextProvider.notifier);

    if (chordTrack == null || chordTrackIndex == -1) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('未找到有效的和弦轨道。请确保至少有一个类型为 Chord 的轨道存在。'),
        ),
      );
    }

    // Directly return the editing UI
    return Column(
      children: [
        // --- Main Section: Editing Controls (using ReorderableListView) ---
        Expanded(
          child: Container(
            // Keep background and padding for the main editing area
            color: Colors.white,
            padding: const EdgeInsets.all(8.0),
            // Use ReorderableListView for drag-and-drop chords
            child: ReorderableListView.builder(
              itemCount: chordTrack.clips.length,
              itemBuilder: (context, index) {
                final clip = chordTrack.clips[index];
                final bool isEditing = _selectedClipForEditing?.id == clip.id;

                // --- Build the Chord Card ---
                return Card(
                  key: ValueKey(clip.id),
                  elevation: isEditing ? 4 : 1,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // Edit/Save Button
                        IconButton(
                          icon: Icon(isEditing ? Icons.save : Icons.edit,
                              size: 20),
                          tooltip: isEditing ? '保存名称' : '编辑名称',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _toggleEditMode(clip),
                        ),
                        const SizedBox(width: 8),
                        // Chord Name (Editable)
                        Expanded(
                          child: isEditing
                              ? TextField(
                                  controller: _nameEditingController,
                                  autofocus: true,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: const InputDecoration(
                                      isDense: true, border: InputBorder.none),
                                )
                              : Text(
                                  clip.chordValue ?? clip.name ?? '',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                        const SizedBox(width: 8),
                        // Duration Dropdown
                        DropdownButton<NoteDuration>(
                          value: _calculateNoteDuration(
                              clip.duration, clip.startTime, timeContext),
                          items: NoteDuration.values
                              .map((duration) => DropdownMenuItem(
                                    value: duration,
                                    child: Text(duration.displayName,
                                        style: const TextStyle(fontSize: 12)),
                                  ))
                              .toList(),
                          onChanged: (NoteDuration? newNoteDuration) {
                            if (newNoteDuration != null) {
                              _updateClipDuration(chordTrackIndex, clip,
                                  newNoteDuration, timeContext);
                            }
                          },
                          underline: Container(), // Hide default underline
                          isDense: true,
                          hint:
                              const Text('时值'), // Hint if value is somehow null
                        ),
                        const SizedBox(width: 4),
                        // Delete Button
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          tooltip: '删除和弦',
                          visualDensity: VisualDensity.compact,
                          onPressed: () =>
                              _deleteChord(chordTrackIndex, clip.id),
                        ),
                      ],
                    ),
                  ),
                );
                // --- End Chord Card ---
              },
              onReorder: (oldIndex, newIndex) {
                _reorderChords(chordTrackIndex, oldIndex, newIndex);
              },
              // Optional: Add header/footer or other properties
              header: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('和弦进行 (拖动排序)',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
        // Optional: Add button outside the list
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('添加新和弦'),
            onPressed: () => _addNewChord(chordTrackIndex, chordTrack.clips),
          ),
        ),
      ],
    );
  }

  // --- Helper Methods for Editing Logic ---

  void _toggleEditMode(model_clip.Clip clip) {
    setState(() {
      if (_selectedClipForEditing?.id == clip.id) {
        // Currently editing this clip, so save changes
        final String newName = _nameEditingController.text.trim();
        if (newName.isNotEmpty &&
            newName !=
                (_selectedClipForEditing!.chordValue ??
                    _selectedClipForEditing!.name)) {
          final chordTrackIndex =
              _findChordTrackIndex(ref.read(tracksProvider));
          if (chordTrackIndex != -1) {
            ref.read(tracksProvider.notifier).updateClipInTrack(
                  chordTrackIndex,
                  _selectedClipForEditing!.id,
                  newName: newName,
                  newChordValue:
                      newName, // Update both name and chordValue for consistency
                );
          }
        }
        _selectedClipForEditing = null; // Exit edit mode
      } else {
        // Start editing this clip
        _selectedClipForEditing = clip;
        _nameEditingController.text = clip.chordValue ?? clip.name ?? '';
      }
    });
  }

  void _deleteChord(int trackIndex, String clipId) {
    // Optional: Add confirmation dialog
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('确认删除'),
              content: const Text('确定要删除这个和弦吗？'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消')),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ref
                        .read(tracksProvider.notifier)
                        .deleteClip(trackIndex, clipId);
                    // Also ensure we exit edit mode if the deleted clip was being edited
                    if (_selectedClipForEditing?.id == clipId) {
                      setState(() {
                        _selectedClipForEditing = null;
                      });
                    }
                  },
                  child: const Text('删除', style: TextStyle(color: Colors.red)),
                ),
              ],
            ));
  }

  void _addNewChord(int trackIndex, List<model_clip.Clip> currentClips) {
    if (trackIndex == -1) return;
    final timeContext =
        ref.read(timeContextProvider.notifier); // Need context here too

    // Calculate start time
    double newStartTime = 0.0;
    if (currentClips.isNotEmpty) {
      final lastClip = currentClips.last;
      newStartTime = lastClip.startTime + lastClip.duration;
    }

    // Default to a Quarter Note duration
    double defaultDurationSeconds = 2.0; // Fallback
    final double secondsPerBeat = timeContext.getSecondsPerBeatAt(newStartTime);
    if (secondsPerBeat > 0) {
      defaultDurationSeconds = NoteDuration.quarter.beats * secondsPerBeat;
    }

    final newClip = model_clip.Clip(
        name: 'New Chord',
        startTime: newStartTime,
        duration: defaultDurationSeconds,
        color: Colors.orange,
        type: model_clip.ClipType.chord,
        chordValue: 'C');
    ref.read(tracksProvider.notifier).addClipToTrack(trackIndex, newClip);
  }

  void _reorderChords(int trackIndex, int oldIndex, int newIndex) {
    if (trackIndex == -1) return;
    print("Reorder attempt: old=$oldIndex, new=$newIndex");
    // TODO: Implement the complex logic for reordering and recalculating start times
    // This involves:
    // 1. Getting the current list of clips.
    // 2. Removing the item at oldIndex and inserting it at newIndex.
    // 3. Iterating through the reordered list from the *start* (or at least from the first affected index).
    // 4. For each clip, calculate its startTime based on the *previous* clip's startTime + duration.
    // 5. Calling updateClipInTrack for *each* clip whose startTime changed.
    // This requires access to TimeContext for accurate duration calculations if durations are based on beats.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('拖动排序功能暂未完全实现')),
    );
    // --- Placeholder state update (visual only, no time recalculation) ---
    setState(() {
      final tracks = ref.read(tracksProvider);
      final chordTrack = _findChordTrack(tracks);
      if (chordTrack != null) {
        final clips = List<model_clip.Clip>.from(chordTrack.clips);
        final item = clips.removeAt(oldIndex);
        // Adjust index if item is moved downwards
        final insertIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
        clips.insert(insertIndex, item);
        // This setState visually reorders but doesn't save or recalculate times yet
        // A full implementation needs to call the notifier.
      }
    });
    // --- End Placeholder ---
  }

  // --- Helper Methods ---

  NoteDuration _calculateNoteDuration(
      double durationSeconds, double startTime, TimeContext timeContext) {
    final double secondsPerBeat = timeContext.getSecondsPerBeatAt(startTime);
    if (secondsPerBeat <= 0) {
      print(
          "Warning: Cannot calculate beats, secondsPerBeat is zero or negative at $startTime");
      return NoteDuration.quarter; // Fallback
    }
    final double beats = durationSeconds / secondsPerBeat;
    return NoteDuration.fromBeats(beats);
  }

  void _updateClipDuration(int trackIndex, model_clip.Clip clip,
      NoteDuration newNoteDuration, TimeContext timeContext) {
    final double secondsPerBeat =
        timeContext.getSecondsPerBeatAt(clip.startTime);
    if (secondsPerBeat <= 0) {
      print(
          "Warning: Cannot update duration, secondsPerBeat is zero or negative at ${clip.startTime}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法更新时值：当前速度无效')),
      );
      return; // Can't calculate new duration
    }
    final double newDurationSeconds = newNoteDuration.beats * secondsPerBeat;

    ref.read(tracksProvider.notifier).updateClipInTrack(
          trackIndex,
          clip.id,
          newDuration: newDurationSeconds,
        );
  }
}

// Helper to find chord track index (more robust)
// int findChordTrackIndex(List<Track> tracks) {
//   return tracks.indexWhere((track) => track.type == TrackType.chord);
// }
