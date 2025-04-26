import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/clip.dart';
import '../models/track.dart';
import '../utils/time_utils.dart';
import 'dart:math' as Math;

// --- Debugging Flag ---
const bool _kDebugDragging = false; // Set to true to enable dragging logs
// ---------------------

// 时间线配置常量提供者
final dawConfigProvider = Provider<DawConfig>((ref) {
  return const DawConfig(
    totalSeconds: 240.0,
    pixelsPerSecond: 50.0,
    minSecondsPerRow: 5.0,
    trackHeight: 50.0,
    timelineHeight: 24.0,
    rowSpacing: 4.0,
  );
});

// 时间工具提供者
final timeUtilsProvider = Provider<TimeUtils>((ref) {
  return TimeUtils(bpm: 120.0, beatsPerBar: 4);
});

// DAW配置类
class DawConfig {
  final double totalSeconds;
  final double pixelsPerSecond;
  final double minSecondsPerRow;
  final double trackHeight;
  final double timelineHeight;
  final double rowSpacing;

  const DawConfig({
    required this.totalSeconds,
    required this.pixelsPerSecond,
    required this.minSecondsPerRow,
    required this.trackHeight,
    required this.timelineHeight,
    required this.rowSpacing,
  });
}

// 轨道列表状态提供者
class TracksNotifier extends StateNotifier<List<Track>> {
  TracksNotifier()
      : super([
          // 和弦轨道放在第一位
          Track(
            name: '和弦轨道',
            type: TrackType.chord,
            clips: [
              Clip(
                name: 'Cmaj7',
                startTime: 1.0,
                duration: 2.0,
                color: Colors.purple,
                type: ClipType.chord,
                chordValue: 'Cmaj7',
              ),
              Clip(
                name: 'Dm7',
                startTime: 3.0,
                duration: 2.0,
                color: Colors.purple,
                type: ClipType.chord,
                chordValue: 'Dm7',
              ),
              Clip(
                name: 'G7',
                startTime: 5.0,
                duration: 2.0,
                color: Colors.purple,
                type: ClipType.chord,
                chordValue: 'G7',
              ),
              Clip(
                name: 'Cmaj7',
                startTime: 7.0,
                duration: 2.0,
                color: Colors.purple,
                type: ClipType.chord,
                chordValue: 'Cmaj7',
              ),
            ],
          ),
          Track(
            name: '轨道 1',
            clips: [
              Clip(
                name: 'Clip 1',
                startTime: 1.5,
                duration: 3.0,
                color: Colors.blue,
                type: ClipType.wav,
              ),
              Clip(
                name: 'Clip 2',
                startTime: 8.0,
                duration: 5.0,
                color: Colors.green,
                type: ClipType.midi,
              ),
            ],
          ),
          Track(
            name: '轨道 2',
            clips: [
              Clip(
                name: 'Clip 3',
                startTime: 4.0,
                duration: 7.0,
                color: Colors.red,
                type: ClipType.wav,
              ),
            ],
          ),
          Track(
            name: '轨道 3',
            clips: [],
          ),
        ]);

  // 切换轨道可见性
  void toggleTrackVisibility(int index) {
    state = state.asMap().entries.map((entry) {
      if (entry.key == index) {
        final track = entry.value;
        return Track(
          name: track.name,
          clips: track.clips,
          isVisible: !track.isVisible,
          isMuted: track.isMuted,
          isSolo: track.isSolo,
          volume: track.volume,
          pan: track.pan,
        );
      }
      return entry.value;
    }).toList();
  }

  // 切换轨道静音状态
  void toggleTrackMute(int index) {
    state = state.asMap().entries.map((entry) {
      if (entry.key == index) {
        final track = entry.value;
        return Track(
          name: track.name,
          clips: track.clips,
          isVisible: track.isVisible,
          isMuted: !track.isMuted,
          isSolo: track.isSolo,
          volume: track.volume,
          pan: track.pan,
        );
      }
      return entry.value;
    }).toList();
  }

  // 更新Clip位置
  void updateClipPosition(Clip clip, double newStartTime) {
    if ((clip.startTime - newStartTime).abs() < 0.001) {
      return; // 如果变化太小，不更新
    }

    state = state.map((track) {
      // 寻找包含目标 Clip 的轨道
      bool trackContainsClip = track.clips.any((c) => c == clip);
      if (!trackContainsClip) {
        return track; // 如果当前轨道不包含该 Clip，直接返回
      }

      final updatedClips = track.clips.map((c) {
        // 如果是目标 Clip，创建一个包含新 startTime 和保留其他属性（包括 chordValue）的新实例
        if (c == clip) {
          final updatedClip = Clip(
            name: c.name,
            startTime: newStartTime,
            duration: c.duration,
            color: c.color,
            type: c.type,
            chordValue: c.chordValue, // 确保 chordValue 被复制过来
          );
          // Only print if the debug flag is true
          if (_kDebugDragging) {
            print(
                'Updating clip: ${c.toString()} -> ${updatedClip.toString()}'); // Debugging
          }
          return updatedClip;
        }
        return c;
      }).toList();

      // 创建更新后的 Track 实例
      return Track(
        name: track.name,
        clips: updatedClips,
        type: track.type, // 确保保留 track 类型
        isVisible: track.isVisible,
        isMuted: track.isMuted,
        isSolo: track.isSolo,
        volume: track.volume,
        pan: track.pan,
      );
    }).toList();
  }

  // 计算可见轨道数量
  int getVisibleTrackCount() {
    return state.where((track) => track.isVisible).length;
  }

  // 获取轨道颜色
  Color getTrackColor(int index) {
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    return colors[index % colors.length];
  }

  // Update Clip position using its unique ID
  void updateClipPositionById(String clipId, double newStartTime) {
    // Find the track and clip indices
    int? targetTrackIndex;
    int? targetClipIndex;
    Clip? originalClip;

    for (int i = 0; i < state.length; i++) {
      try {
        targetClipIndex = state[i].clips.indexWhere((c) => c.id == clipId);
        if (targetClipIndex != -1) {
          targetTrackIndex = i;
          originalClip = state[i].clips[targetClipIndex];
          break;
        }
      } catch (e) {
        /* Should not happen with indexWhere, but belt and suspenders */
      }
    }

    // If clip not found, do nothing
    if (targetTrackIndex == null ||
        targetClipIndex == null ||
        originalClip == null) {
      print("Error in updateClipPositionById: Clip with ID $clipId not found.");
      return;
    }

    // Avoid update if time hasn't changed significantly
    if ((originalClip.startTime - newStartTime).abs() < 0.001) {
      return;
    }

    // Create the updated Clip instance
    final updatedClip = Clip(
      id: originalClip.id, // Preserve the ID
      name: originalClip.name,
      startTime: newStartTime,
      duration: originalClip.duration,
      color: originalClip.color,
      type: originalClip.type,
      chordValue: originalClip.chordValue,
    );

    // Create a new list of tracks with the updated clip
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == targetTrackIndex)
          // Create a new Track instance with the updated clips list
          Track(
            name: state[i].name,
            type: state[i].type,
            isVisible: state[i].isVisible,
            isMuted: state[i].isMuted,
            isSolo: state[i].isSolo,
            volume: state[i].volume,
            pan: state[i].pan,
            clips: [
              ...state[i].clips.sublist(0, targetClipIndex),
              updatedClip, // Insert the updated clip
              ...state[i].clips.sublist(targetClipIndex + 1),
            ],
          )
        else
          state[i] // Keep other tracks as they are (same reference)
    ];

    // Optional debug log
    if (_kDebugDragging) {
      print(
          'Updated clip by ID: ${originalClip.toString()} -> ${updatedClip.toString()}');
    }
  }
}

final tracksProvider =
    StateNotifierProvider<TracksNotifier, List<Track>>((ref) {
  return TracksNotifier();
});

// 播放状态控制
class PlaybackState {
  final bool isPlaying;
  final double position;
  final bool disableAutoScroll;

  PlaybackState({
    required this.isPlaying,
    required this.position,
    this.disableAutoScroll = false,
  });

  PlaybackState copyWith({
    bool? isPlaying,
    double? position,
    bool? disableAutoScroll,
  }) {
    return PlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      disableAutoScroll: disableAutoScroll ?? this.disableAutoScroll,
    );
  }
}

class PlaybackNotifier extends StateNotifier<PlaybackState> {
  Timer? _playTimer;
  final double totalSeconds;
  final Function onPositionChanged;

  PlaybackNotifier(this.totalSeconds, this.onPositionChanged)
      : super(PlaybackState(
            isPlaying: false, position: 0.0, disableAutoScroll: false));

  @override
  void dispose() {
    _playTimer?.cancel();
    super.dispose();
  }

  void togglePlay() {
    if (state.isPlaying) {
      _stopTimer();
      state = state.copyWith(isPlaying: false);
    } else {
      state = state.copyWith(isPlaying: true);
      _startTimer();
    }
  }

  void stop() {
    _stopTimer();
    state = PlaybackState(
        isPlaying: false, position: 0.0, disableAutoScroll: false);
  }

  void seekTo(double position) {
    state = state.copyWith(position: position.clamp(0.0, totalSeconds));
  }

  void _startTimer() {
    _playTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      double newPosition = state.position + 0.1;
      if (newPosition >= totalSeconds) {
        newPosition = 0.0;
      }
      state = state.copyWith(position: newPosition);
      onPositionChanged();
    });
  }

  void _stopTimer() {
    _playTimer?.cancel();
    _playTimer = null;
  }

  // 切换自动滚动状态
  void toggleAutoScroll() {
    state = state.copyWith(disableAutoScroll: !state.disableAutoScroll);
  }

  // 设置自动滚动状态
  void setAutoScroll(bool enable) {
    state = state.copyWith(disableAutoScroll: !enable);
  }
}

final playbackProvider =
    StateNotifierProvider.autoDispose<PlaybackNotifier, PlaybackState>((ref) {
  final config = ref.watch(dawConfigProvider);
  return PlaybackNotifier(
    config.totalSeconds,
    () => ref.read(scrollControllerProvider.notifier).scrollToPlayPosition(),
  );
});

// 缩放控制
class ZoomState {
  final double scale;

  ZoomState({required this.scale});
}

class ZoomNotifier extends StateNotifier<ZoomState> {
  ZoomNotifier() : super(ZoomState(scale: 1.0));

  void setScale(double scale) {
    state = ZoomState(scale: scale.clamp(0.5, 2.0));
  }

  void zoomIn() {
    setScale(state.scale + 0.1);
  }

  void zoomOut() {
    setScale(state.scale - 0.1);
  }
}

final zoomProvider = StateNotifierProvider<ZoomNotifier, ZoomState>((ref) {
  return ZoomNotifier();
});

// UI控制状态
class UIControlState {
  final bool isTrackPanelExpanded;

  UIControlState({required this.isTrackPanelExpanded});

  UIControlState copyWith({bool? isTrackPanelExpanded}) {
    return UIControlState(
      isTrackPanelExpanded: isTrackPanelExpanded ?? this.isTrackPanelExpanded,
    );
  }
}

class UIControlNotifier extends StateNotifier<UIControlState> {
  UIControlNotifier() : super(UIControlState(isTrackPanelExpanded: false));

  void toggleTrackPanel() {
    state = state.copyWith(isTrackPanelExpanded: !state.isTrackPanelExpanded);
  }
}

final uiControlProvider =
    StateNotifierProvider<UIControlNotifier, UIControlState>((ref) {
  return UIControlNotifier();
});

// 滚动控制器提供者
class ScrollControllerNotifier extends StateNotifier<ScrollController> {
  final Ref _ref;

  ScrollControllerNotifier(this._ref) : super(ScrollController());

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  // 滚动到播放位置
  void scrollToPlayPosition() {
    final config = _ref.read(dawConfigProvider);
    final playbackState = _ref.read(playbackProvider);
    final zoom = _ref.read(zoomProvider);
    final tracks = _ref.read(tracksProvider);
    final draggingState = _ref.read(draggingStateProvider);

    // 如果不应该自动滚动，直接返回
    if (playbackState.disableAutoScroll) {
      return;
    }

    // 计算行高
    double rowHeight = _calculateRowHeight(
      config,
      tracks.where((track) => track.isVisible).length,
      draggingState.isDragging,
      draggingState.dragStartTrackIndex,
    );

    // 计算每行可显示的秒数
    final double viewportWidth = _ref.read(viewportWidthProvider);
    final double scaledPixelsPerSecond = config.pixelsPerSecond * zoom.scale;
    final double adaptiveSecondsPerRow =
        (viewportWidth / scaledPixelsPerSecond).floor().toDouble();
    final double secondsPerRowScaled =
        adaptiveSecondsPerRow > config.minSecondsPerRow
            ? adaptiveSecondsPerRow
            : config.minSecondsPerRow;

    // 计算当前播放位置所在的行
    final int currentRow =
        (playbackState.position / secondsPerRowScaled).floor();
    final double scrollTarget = currentRow * rowHeight;

    // 检查播放指针是否已经在视图外
    if (state.hasClients) {
      final double scrollTop = state.offset;
      final double viewportHeight = state.position.viewportDimension;
      final double scrollBottom = scrollTop + viewportHeight;

      // 只有当播放指针不在当前视图中时才滚动
      if (scrollTarget < scrollTop || scrollTarget > scrollBottom - rowHeight) {
        state.animateTo(
          scrollTarget,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  // 计算行高
  double _calculateRowHeight(DawConfig config, int visibleTrackCount,
      bool isDragging, int? dragStartTrackIndex) {
    if (isDragging && dragStartTrackIndex != null) {
      // 拖动状态下，行高只计算时间轴+活跃轨道+间距
      return config.timelineHeight + config.trackHeight + config.rowSpacing;
    } else {
      // 正常状态下，行高为时间轴+可见轨道+间距
      return config.timelineHeight +
          (visibleTrackCount * config.trackHeight) +
          config.rowSpacing;
    }
  }
}

final scrollControllerProvider =
    StateNotifierProvider<ScrollControllerNotifier, ScrollController>((ref) {
  return ScrollControllerNotifier(ref);
});

// 存储视口宽度的状态与管理类
class ViewportWidthNotifier extends StateNotifier<double> {
  ViewportWidthNotifier() : super(500.0); // 默认宽度

  // 安全地更新视口宽度，可以被调用
  void updateWidth(double width) {
    // 如果宽度与当前状态相同，不进行更新
    if (width == state) return;

    // 使用Future.microtask确保在构建完成后更新
    Future.microtask(() {
      state = width;
    });
  }
}

// 更新存储视口宽度的状态提供者为StateNotifierProvider
final viewportWidthProvider =
    StateNotifierProvider<ViewportWidthNotifier, double>((ref) {
  return ViewportWidthNotifier();
});

// 拖动操作状态
class DraggingState {
  final bool isDragging;
  final String? draggingClipId;
  final Offset? dragStartPosition;
  final int? dragStartTrackIndex;
  final double? dragStartTime;
  final Offset? currentDragPosition;

  DraggingState({
    required this.isDragging,
    this.draggingClipId,
    this.dragStartPosition,
    this.dragStartTrackIndex,
    this.dragStartTime,
    this.currentDragPosition,
  });

  DraggingState copyWith({
    bool? isDragging,
    String? draggingClipId,
    Offset? dragStartPosition,
    int? dragStartTrackIndex,
    double? dragStartTime,
    Offset? currentDragPosition,
  }) {
    return DraggingState(
      isDragging: isDragging ?? this.isDragging,
      draggingClipId: draggingClipId ?? this.draggingClipId,
      dragStartPosition: dragStartPosition ?? this.dragStartPosition,
      dragStartTrackIndex: dragStartTrackIndex ?? this.dragStartTrackIndex,
      dragStartTime: dragStartTime ?? this.dragStartTime,
      currentDragPosition: currentDragPosition ?? this.currentDragPosition,
    );
  }

  // 清除拖动状态
  DraggingState clear() {
    return DraggingState(
      isDragging: false,
      draggingClipId: null,
      dragStartPosition: null,
      dragStartTrackIndex: null,
      dragStartTime: null,
      currentDragPosition: null,
    );
  }
}

class DraggingNotifier extends StateNotifier<DraggingState> {
  final Ref _ref;

  DraggingNotifier(this._ref) : super(DraggingState(isDragging: false));

  // 开始拖动
  void startDragging(Clip clip, int trackIndex, Offset globalPosition) {
    if (state.isDragging) {
      // If somehow a drag is already active, end it first.
      print(
          "Warning: Starting a new drag while another was active. Ending previous.");
      endDragging();
    }

    print("Starting drag for Clip ID: ${clip.id}"); // Debug
    state = DraggingState(
      isDragging: true,
      draggingClipId: clip.id, // Store the ID
      dragStartPosition: globalPosition,
      currentDragPosition: globalPosition,
      dragStartTrackIndex: trackIndex,
      dragStartTime: clip.startTime,
    );
  }

  // 更新拖动位置
  void updateDragging(Offset globalPosition) {
    if (!state.isDragging ||
        state.draggingClipId == null || // Check ID
        state.dragStartPosition == null) {
      return;
    }

    final config = _ref.read(dawConfigProvider);
    final zoom = _ref.read(zoomProvider);
    final tracksNotifier = _ref.read(tracksProvider.notifier);
    final viewportWidth = _ref.read(viewportWidthProvider);

    final double scaledPixelsPerSecond = config.pixelsPerSecond * zoom.scale;
    final double adaptiveSecondsPerRow =
        (viewportWidth / scaledPixelsPerSecond).floor().toDouble();
    final double secondsPerRowScaled =
        adaptiveSecondsPerRow > config.minSecondsPerRow
            ? adaptiveSecondsPerRow
            : config.minSecondsPerRow;

    final delta = globalPosition - state.dragStartPosition!;
    final double pixelsPerSecond = viewportWidth / secondsPerRowScaled;
    final double timeDelta = delta.dx / pixelsPerSecond;

    // ----- Find the clip being dragged based on the stored ID -----
    Clip? currentClip;
    int? trackIndex = state.dragStartTrackIndex;
    final tracks = _ref.read(tracksProvider);

    if (trackIndex != null && trackIndex < tracks.length) {
      final targetTrack = tracks[trackIndex];
      try {
        // Find the clip using its unique ID
        currentClip =
            targetTrack.clips.firstWhere((c) => c.id == state.draggingClipId);
      } catch (e) {
        // Could happen if the clip was somehow removed between drag updates
        print(
            "Error: Clip with ID ${state.draggingClipId} not found in track $trackIndex. Aborting update.");
        // Optionally try a global search, but ID should be reliable
        // If not found, currentClip remains null
      }
    } else {
      print(
          "Error: Invalid dragStartTrackIndex ${state.dragStartTrackIndex}. Aborting update.");
    }

    // 如果找不到 Clip，则停止处理
    if (currentClip == null) {
      // No need to print again, error handled above
      return; // Abort the update
    }
    // ----- End finding clip -----

    // --- Calculate new position (logic mostly unchanged) ---
    final double rowHeight = _calculateRowHeight();
    final double rowDelta = delta.dy / rowHeight;
    int rowOffset = rowDelta.round();

    final int currentRow = (state.dragStartTime! / secondsPerRowScaled).floor();
    final int totalRows = (config.totalSeconds / secondsPerRowScaled).ceil();
    final int lastRow = totalRows - 1;

    if (currentRow + rowOffset < 0)
      rowOffset = -currentRow;
    else if (currentRow + rowOffset > lastRow) rowOffset = lastRow - currentRow;

    double newStartTime = state.dragStartTime! + timeDelta;
    final double maxAllowedStartTime =
        config.totalSeconds - currentClip.duration;

    // Boundary checks (keep previous logic for now)
    if (newStartTime > maxAllowedStartTime * 0.95) {
      if (rowOffset > 0 && currentRow + rowOffset >= lastRow) {
        final double lastRowStartTime = lastRow * secondsPerRowScaled;
        final double maxOffsetInLastRow =
            maxAllowedStartTime - lastRowStartTime;
        if (maxOffsetInLastRow > 0) {
          newStartTime = lastRowStartTime +
              Math.min(maxOffsetInLastRow * 0.9, secondsPerRowScaled * 0.5);
        } else {
          newStartTime = Math.max(0, maxAllowedStartTime - 0.1);
        }
        rowOffset = 0;
      }
    }
    if (rowOffset != 0) {
      double potentialNewTime =
          newStartTime + (rowOffset * secondsPerRowScaled);
      if (potentialNewTime < 0 || potentialNewTime > maxAllowedStartTime) {
        rowOffset = 0;
      } else {
        newStartTime = potentialNewTime;
      }
    }
    newStartTime = Math.max(0, Math.min(maxAllowedStartTime, newStartTime));
    final int newRow = (newStartTime / secondsPerRowScaled).floor();
    if (currentRow == lastRow && newRow < lastRow - 1)
      newStartTime = (lastRow - 1) * secondsPerRowScaled + 0.1;
    else if (newRow > lastRow)
      newStartTime = lastRow * secondsPerRowScaled + 0.1;
    // --- End calculating new position ---

    // 使用找到的 Clip 引用和新时间更新位置
    // Pass the ID to updateClipPosition for reliable finding there too
    tracksNotifier.updateClipPositionById(state.draggingClipId!, newStartTime);

    // Update dragging state (no need to update draggingClip reference anymore)
    state = state.copyWith(currentDragPosition: globalPosition);

    // Ensure visible scroll logic (remains the same)
    if (_shouldEnsureVisible(newStartTime)) {
      _ensureVisibleWhenDragging(newStartTime);
    }
  }

  // 结束拖动
  void endDragging() {
    // Use ID if needed for final actions
    final lastClipId = state.draggingClipId;
    final lastPos = state.currentDragPosition;

    if (lastClipId != null) {
      print("Ending drag for Clip ID: $lastClipId"); // Debug
      // Perform any final actions based on ID and position
    }

    state = state.clear();
  }

  // 辅助方法：判断是否需要确保可见
  bool _shouldEnsureVisible(double clipStartTime) {
    final config = _ref.read(dawConfigProvider);
    final zoom = _ref.read(zoomProvider);
    final scrollController = _ref.read(scrollControllerProvider);
    final viewportWidth = _ref.read(viewportWidthProvider);

    if (!scrollController.hasClients) return false;

    // 计算参数
    final double scaledPixelsPerSecond = config.pixelsPerSecond * zoom.scale;
    final double adaptiveSecondsPerRow =
        (viewportWidth / scaledPixelsPerSecond).floor().toDouble();
    final double secondsPerRowScaled =
        adaptiveSecondsPerRow > config.minSecondsPerRow
            ? adaptiveSecondsPerRow
            : config.minSecondsPerRow;

    // 计算Clip所在的行
    final int currentRow = (clipStartTime / secondsPerRowScaled).floor();

    // 计算行高
    final double rowHeight = _calculateRowHeight();
    final double rowPosition = currentRow * rowHeight;

    // 当前可视区域
    final double scrollTop = scrollController.offset;
    final double viewportHeight = scrollController.position.viewportDimension;
    final double scrollBottom = scrollTop + viewportHeight;

    // 只有当行不在可视区域的中间部分时才需要滚动
    final double visibleMargin = viewportHeight * 0.2; // 20%的边距
    return rowPosition < scrollTop + visibleMargin ||
        rowPosition > scrollBottom - rowHeight - visibleMargin;
  }

  // 确保拖动时Clip始终可见
  void _ensureVisibleWhenDragging(double clipStartTime) {
    final config = _ref.read(dawConfigProvider);
    final zoom = _ref.read(zoomProvider);
    final scrollController = _ref.read(scrollControllerProvider);
    final viewportWidth = _ref.read(viewportWidthProvider);

    // 计算参数
    final double scaledPixelsPerSecond = config.pixelsPerSecond * zoom.scale;
    final double adaptiveSecondsPerRow =
        (viewportWidth / scaledPixelsPerSecond).floor().toDouble();
    final double secondsPerRowScaled =
        adaptiveSecondsPerRow > config.minSecondsPerRow
            ? adaptiveSecondsPerRow
            : config.minSecondsPerRow;

    // 计算Clip所在的行
    final int currentRow = (clipStartTime / secondsPerRowScaled).floor();

    // 计算行高
    final double rowHeight = _calculateRowHeight();
    final double rowPosition = currentRow * rowHeight;

    // 当前可视区域
    if (scrollController.hasClients) {
      final double scrollTop = scrollController.offset;
      final double viewportHeight = scrollController.position.viewportDimension;
      final double scrollBottom = scrollTop + viewportHeight;

      // 计算理想的滚动位置 - 让当前行在可视区域的中间
      double targetScrollPosition =
          rowPosition - (viewportHeight / 2) + (config.trackHeight / 2);

      // 限制在有效范围内
      targetScrollPosition = targetScrollPosition.clamp(
          0.0, scrollController.position.maxScrollExtent);

      // 如果当前行不在可视区域内，或者离边缘太近，滚动到该行
      final double visibleMargin = config.trackHeight * 1.5;
      final bool needsScroll = rowPosition < scrollTop + visibleMargin ||
          rowPosition > scrollBottom - rowHeight - visibleMargin;

      if (needsScroll) {
        scrollController.animateTo(
          targetScrollPosition,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  // 计算行高
  double _calculateRowHeight() {
    final config = _ref.read(dawConfigProvider);
    final tracks = _ref.read(tracksProvider);

    if (state.isDragging && state.dragStartTrackIndex != null) {
      // 拖动状态下，行高只计算时间轴+活跃轨道+间距
      return config.timelineHeight + config.trackHeight + config.rowSpacing;
    } else {
      // 正常状态下，行高为时间轴+可见轨道+间距
      final visibleTrackCount = tracks.where((track) => track.isVisible).length;
      return config.timelineHeight +
          (visibleTrackCount * config.trackHeight) +
          config.rowSpacing;
    }
  }
}

final draggingStateProvider =
    StateNotifierProvider<DraggingNotifier, DraggingState>((ref) {
  return DraggingNotifier(ref);
});
