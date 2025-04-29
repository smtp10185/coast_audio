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

/// A Dialog content widget for arranging and editing chords using ReorderableListView.
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
            color: Colors.white,
            padding: const EdgeInsets.all(8.0),
            // Switch back to ReorderableListView.builder
            child: ReorderableListView.builder(
              itemCount: chordTrack.clips.length,
              itemBuilder: (context, index) {
                final clip = chordTrack.clips[index];
                // Build the card directly here or call the helper
                // Ensure the Card has the key!
                return _buildChordCard(
                    context, clip, timeContext, chordTrackIndex);
              },
              onReorder: (oldIndex, newIndex) {
                _reorderChords(chordTrackIndex, oldIndex, newIndex);
              },
              // Restore the header
              header: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('和弦进行 (拖动排序)',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
        // Add New Chord Button remains the same
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

  // --- Chord Card Builder (Simplified for ListView) ---
  Widget _buildChordCard(BuildContext context, model_clip.Clip clip,
      TimeContext timeContext, int chordTrackIndex) {
    final bool isEditing = _selectedClipForEditing?.id == clip.id;

    // Return the Card widget directly, ensure it has the ValueKey
    return Card(
      key: ValueKey(clip.id), // CRITICAL for ReorderableListView
      elevation: isEditing ? 4 : 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          // Use Row layout for ListView items
          children: [
            // Edit/Save Button
            IconButton(
              icon: Icon(isEditing ? Icons.save : Icons.edit, size: 20),
              tooltip: isEditing ? '保存名称' : '编辑名称',
              visualDensity: VisualDensity.compact,
              onPressed: () => _toggleEditMode(clip),
            ),
            const SizedBox(width: 8),
            // Chord Name (Editable)
            Expanded(
              child: isEditing
                  ? SizedBox(
                      height: 24, // Keep height constraint for consistency?
                      child: TextField(
                        controller: _nameEditingController,
                        autofocus: true,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                    )
                  : Text(
                      clip.chordValue ?? clip.name ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                  _updateClipDuration(
                      chordTrackIndex, clip, newNoteDuration, timeContext);
                }
              },
              underline: Container(),
              isDense: true,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              hint: const Text('时值'),
            ),
            const SizedBox(width: 4),
            // Delete Button
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              tooltip: '删除和弦',
              visualDensity: VisualDensity.compact,
              onPressed: () => _deleteChord(chordTrackIndex, clip.id),
            ),
          ],
        ),
      ),
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
    final timeContext = ref.read(timeContextProvider.notifier);

    double newStartTime = 0.0;
    if (currentClips.isNotEmpty) {
      final lastClip = currentClips.last;
      newStartTime = lastClip.startTime + lastClip.duration;
    }

    final double secondsPerBeat = timeContext.getSecondsPerBeatAt(newStartTime);
    double defaultDurationSeconds = 1.0; // Fallback

    if (secondsPerBeat > 0 && secondsPerBeat != double.infinity) {
      // Directly access the .beats property from NoteDuration
      try {
        final double quarterNoteBeats = NoteDuration.quarter.beats;
        defaultDurationSeconds = quarterNoteBeats * secondsPerBeat;
      } catch (e) {
        // This catch might not be strictly necessary anymore if NoteDuration structure is known
        print("Error getting default duration: ${e}. Using fallback.");
        defaultDurationSeconds = 1.0; // Ensure fallback
      }
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

    final tracksNotifier = ref.read(tracksProvider.notifier);

    // --- 1. Get original list and create reordered list in memory ---
    final originalClips =
        List<model_clip.Clip>.from(ref.read(tracksProvider)[trackIndex].clips);
    if (oldIndex < 0 || oldIndex >= originalClips.length) {
      print("Reorder error: oldIndex out of bounds");
      return;
    }

    final reorderedClipsInMemory = List<model_clip.Clip>.from(originalClips);
    final item = reorderedClipsInMemory.removeAt(oldIndex);
    final insertIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
    if (insertIndex < 0 || insertIndex > reorderedClipsInMemory.length) {
      print("Reorder error: insertIndex out of bounds");
      return;
    }
    reorderedClipsInMemory.insert(insertIndex, item);

    // --- 2. Update the provider state with the new visual order ---
    tracksNotifier.reorderClipsInTrack(trackIndex, reorderedClipsInMemory);

    // --- 3. Recalculate start times using the helper method ---
    _recalculateStartTimes(trackIndex);
  }

  // --- Helper method to recalculate start times for all clips in a track ---
  void _recalculateStartTimes(int trackIndex) {
    if (trackIndex == -1) return;

    final tracksNotifier = ref.read(tracksProvider.notifier);
    // Read the latest state *after* potential reordering or duration change
    final currentClips = ref.read(tracksProvider)[trackIndex].clips;

    double cumulativeTime = 0.0;
    bool timeUpdated = false;

    // Iterate through the clips in the current order
    for (final clip in currentClips) {
      final expectedStartTime = cumulativeTime;

      // Check if the startTime needs updating (use tolerance)
      if ((clip.startTime - expectedStartTime).abs() > 0.001) {
        // Call updateClipInTrack to *only* change the startTime
        tracksNotifier.updateClipInTrack(
          trackIndex,
          clip.id,
          newStartTime: expectedStartTime,
        );
        timeUpdated = true;
      }
      // Add the duration of the *current clip* to the cumulative time
      cumulativeTime += clip.duration;
    }

    if (timeUpdated) {
      print("Recalculated start times for track $trackIndex.");
    }
  }

  // --- Logic for Duration Calculation & Update ---
  NoteDuration _calculateNoteDuration(
      double durationInSeconds, double startTime, TimeContext timeContext) {
    final TempoEvent activeEvent = timeContext.getTempoEventAt(startTime);
    final double bpm = activeEvent.bpm;

    if (bpm <= 0) {
      return NoteDuration.quarter; // Fallback
    }

    final double secondsPerBeat = 60.0 / bpm;
    final double durationInBeats = durationInSeconds / secondsPerBeat;

    // Find closest NoteDuration using the .beats property
    NoteDuration closestDuration = NoteDuration.quarter; // Default
    double minDifference = (closestDuration.beats - durationInBeats).abs();

    for (var noteDur in NoteDuration.values) {
      // Access .beats directly
      final double noteBeatsValue = noteDur.beats;
      final double difference = (noteBeatsValue - durationInBeats).abs();

      // Add a small tolerance for floating point comparison
      if (difference < minDifference - 0.01) {
        minDifference = difference;
        closestDuration = noteDur;
      } else if ((difference - minDifference).abs() < 0.01) {
        // If difference is almost the same, prefer simpler durations (e.g., quarter over dotted eighth?)
        // For now, just take the first closest one found or the existing one.
        // Or maybe prefer the one with fewer beats if difference is equal?
        // Keep it simple: update if strictly smaller difference found.
      }
    }
    // Optional: Use the static method for potentially cleaner code, though logic is similar
    // return NoteDuration.fromBeats(durationInBeats);
    return closestDuration;
  }

  void _updateClipDuration(int trackIndex, model_clip.Clip clip,
      NoteDuration newNoteDuration, TimeContext timeContext) {
    final double secondsPerBeat =
        timeContext.getSecondsPerBeatAt(clip.startTime);

    if (secondsPerBeat <= 0 || secondsPerBeat == double.infinity) {
      debugPrint(
          "Cannot update duration: Invalid tempo at clip start time ${clip.startTime}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法更新时值：当前速度无效')),
      );
      return;
    }

    // Calculate new duration using the .beats property
    final double noteBeatsValue = newNoteDuration.beats;
    final double newDurationInSeconds = noteBeatsValue * secondsPerBeat;

    debugPrint(
        "Updating duration for clip ${clip.id}: NoteDuration=$newNoteDuration -> seconds=$newDurationInSeconds (at ${clip.startTime}s where 1 beat = ${secondsPerBeat.toStringAsFixed(3)}s)");

    if (newDurationInSeconds > 0) {
      ref.read(tracksProvider.notifier).updateClipInTrack(
            trackIndex,
            clip.id,
            newDuration: newDurationInSeconds,
          );

      _recalculateStartTimes(trackIndex);
    } else {
      debugPrint("Calculated duration is zero or negative, skipping update.");
    }
  }
}

// Helper to find chord track index (more robust)
// int findChordTrackIndex(List<Track> tracks) {
//   return tracks.indexWhere((track) => track.type == TrackType.chord);
// }
