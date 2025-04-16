import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/clip.dart';
import '../models/track.dart';
import '../utils/time_utils.dart';

// 时间线配置常量提供者
final dawConfigProvider = Provider<DawConfig>((ref) {
  return const DawConfig(
    totalSeconds: 60.0,
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
      final updatedClips = track.clips.map((c) {
        if (c == clip) {
          final updatedClip = Clip(
            name: c.name,
            startTime: newStartTime,
            duration: c.duration,
            color: c.color,
            type: c.type,
          );
          return updatedClip;
        }
        return c;
      }).toList();

      // 检查clips是否有更新
      bool hasUpdates = false;
      for (int i = 0; i < track.clips.length; i++) {
        if (i < updatedClips.length &&
            track.clips[i].startTime != updatedClips[i].startTime) {
          hasUpdates = true;
          break;
        }
      }

      if (hasUpdates) {
        return Track(
          name: track.name,
          clips: updatedClips,
          isVisible: track.isVisible,
          isMuted: track.isMuted,
          isSolo: track.isSolo,
          volume: track.volume,
          pan: track.pan,
        );
      }
      return track;
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
}

final tracksProvider =
    StateNotifierProvider<TracksNotifier, List<Track>>((ref) {
  return TracksNotifier();
});

// 播放状态控制
class PlaybackState {
  final bool isPlaying;
  final double position;

  PlaybackState({required this.isPlaying, required this.position});

  PlaybackState copyWith({bool? isPlaying, double? position}) {
    return PlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
    );
  }
}

class PlaybackNotifier extends StateNotifier<PlaybackState> {
  Timer? _playTimer;
  final double totalSeconds;
  final Function onPositionChanged;

  PlaybackNotifier(this.totalSeconds, this.onPositionChanged)
      : super(PlaybackState(isPlaying: false, position: 0.0));

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
    state = PlaybackState(isPlaying: false, position: 0.0);
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

    // 计算行高
    double rowHeight = _calculateRowHeight(
      config,
      tracks.where((track) => track.isVisible).length,
      draggingState.isDragging,
      draggingState.activeTrackIndex,
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

    // 平滑滚动到目标位置
    if (state.hasClients) {
      state.animateTo(
        scrollTarget,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // 计算行高
  double _calculateRowHeight(DawConfig config, int visibleTrackCount,
      bool isDragging, int? activeTrackIndex) {
    if (isDragging && activeTrackIndex != null) {
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
  final Clip? draggingClip;
  final Offset? dragStartPosition;
  final int? dragStartTrackIndex;
  final double? dragStartTime;
  final Offset? currentDragPosition;
  final int? activeTrackIndex;

  DraggingState({
    required this.isDragging,
    this.draggingClip,
    this.dragStartPosition,
    this.dragStartTrackIndex,
    this.dragStartTime,
    this.currentDragPosition,
    this.activeTrackIndex,
  });

  DraggingState copyWith({
    bool? isDragging,
    Clip? draggingClip,
    Offset? dragStartPosition,
    int? dragStartTrackIndex,
    double? dragStartTime,
    Offset? currentDragPosition,
    int? activeTrackIndex,
  }) {
    return DraggingState(
      isDragging: isDragging ?? this.isDragging,
      draggingClip: draggingClip ?? this.draggingClip,
      dragStartPosition: dragStartPosition ?? this.dragStartPosition,
      dragStartTrackIndex: dragStartTrackIndex ?? this.dragStartTrackIndex,
      dragStartTime: dragStartTime ?? this.dragStartTime,
      currentDragPosition: currentDragPosition ?? this.currentDragPosition,
      activeTrackIndex: activeTrackIndex ?? this.activeTrackIndex,
    );
  }

  // 清除拖动状态
  DraggingState clear() {
    return DraggingState(
      isDragging: false,
      draggingClip: null,
      dragStartPosition: null,
      dragStartTrackIndex: null,
      dragStartTime: null,
      currentDragPosition: null,
      activeTrackIndex: null,
    );
  }
}

class DraggingNotifier extends StateNotifier<DraggingState> {
  final Ref _ref;

  DraggingNotifier(this._ref) : super(DraggingState(isDragging: false));

  // 开始拖动
  void startDragging(Clip clip, int trackIndex, Offset globalPosition) {
    if (state.isDragging) {
      endDragging();
    }

    state = DraggingState(
      isDragging: true,
      draggingClip: clip,
      dragStartPosition: globalPosition,
      currentDragPosition: globalPosition,
      dragStartTrackIndex: trackIndex,
      dragStartTime: clip.startTime,
      activeTrackIndex: trackIndex,
    );
  }

  // 更新拖动位置
  void updateDragging(Offset globalPosition) {
    if (!state.isDragging ||
        state.draggingClip == null ||
        state.dragStartPosition == null) {
      return;
    }

    final config = _ref.read(dawConfigProvider);
    final zoom = _ref.read(zoomProvider);
    final tracksNotifier = _ref.read(tracksProvider.notifier);
    final viewportWidth = _ref.read(viewportWidthProvider);

    final double scaledPixelsPerSecond = config.pixelsPerSecond * zoom.scale;

    // 根据可用宽度计算每行可显示的秒数
    final double adaptiveSecondsPerRow =
        (viewportWidth / scaledPixelsPerSecond).floor().toDouble();
    final double secondsPerRowScaled =
        adaptiveSecondsPerRow > config.minSecondsPerRow
            ? adaptiveSecondsPerRow
            : config.minSecondsPerRow;

    // 计算位移
    final delta = globalPosition - state.dragStartPosition!;

    // 计算水平方向的时间偏移 - 直接使用更简单的方法计算
    final double pixelsPerSecond = viewportWidth / secondsPerRowScaled;
    final double timeDelta = delta.dx / pixelsPerSecond;

    // 计算垂直方向的行偏移
    final double rowHeight = _calculateRowHeight();
    final double rowDelta = delta.dy / rowHeight;
    final int rowOffset = rowDelta.round();

    // 获取当前Clip的实际引用 - 重要修复
    Clip? currentClip;
    int? trackIndex;

    // 在所有轨道中查找匹配的片段
    final tracks = _ref.read(tracksProvider);
    for (int i = 0; i < tracks.length; i++) {
      for (var c in tracks[i].clips) {
        if (c.name == state.draggingClip!.name &&
            c.type == state.draggingClip!.type &&
            c.color == state.draggingClip!.color) {
          currentClip = c;
          trackIndex = i;
          break;
        }
      }
      if (currentClip != null) break;
    }

    if (currentClip == null) {
      return;
    }

    // 计算新的开始时间 - 简化计算
    double newStartTime = state.dragStartTime! + timeDelta;

    // 考虑行偏移
    if (rowOffset != 0) {
      newStartTime += rowOffset * secondsPerRowScaled;
    }

    // 限制在合法范围内
    newStartTime =
        newStartTime.clamp(0, config.totalSeconds - currentClip.duration);

    // 使用找到的真实片段引用更新位置
    tracksNotifier.updateClipPosition(currentClip, newStartTime);

    // 确保视图跟随 - 使视图跟随优化为只在必要时滚动
    if (_shouldEnsureVisible(newStartTime)) {
      _ensureVisibleWhenDragging(newStartTime);
    }

    // 更新拖动状态，使用找到的真实轨道索引
    state = state.copyWith(
      currentDragPosition: globalPosition,
      draggingClip: currentClip, // 使用找到的真实片段引用
      activeTrackIndex: trackIndex,
    );
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

  // 结束拖动
  void endDragging() {
    final lastClip = state.draggingClip;
    final lastPos = state.currentDragPosition;
    final lastStart = state.dragStartPosition;

    if (lastClip != null && lastPos != null && lastStart != null) {
      // 最后一次拖动结束时的处理
    }

    state = state.clear();
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

    if (state.isDragging && state.activeTrackIndex != null) {
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
