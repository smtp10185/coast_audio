import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/daw_providers.dart';
import 'dart:math' as Math;
import '../../utils/time_utils.dart' as tu;
import 'timeline_ruler.dart';
import 'track_item.dart';
import 'playhead.dart';
import '../../models/track.dart';

/// 时间线内容 - 显示时间轴和轨道内容的主要区域
class TimelineContent extends ConsumerStatefulWidget {
  const TimelineContent({super.key});

  @override
  ConsumerState<TimelineContent> createState() => _TimelineContentState();
}

class _TimelineContentState extends ConsumerState<TimelineContent> {
  final GlobalKey _timelineAreaKey = GlobalKey(); // Key to get RenderBox info
  double? _dragStartTime; // Store original time for snap-back during drag

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(dawConfigProvider);
    final tracks = ref.watch(tracksProvider);
    final playbackState = ref.watch(playbackProvider);
    final zoomState = ref.watch(zoomProvider);
    final viewportWidth = ref.watch(viewportWidthProvider);
    final draggingState = ref.watch(draggingStateProvider);
    final scrollController = ref.watch(scrollControllerProvider);

    // 安全检查
    if (viewportWidth <= 0) {
      return const Center(child: CircularProgressIndicator());
    }

    // 计算缩放后的每秒像素数
    final double scaledPixelsPerSecond =
        config.pixelsPerSecond * zoomState.scale;

    // 计算每行可显示的秒数（自适应）
    final double adaptiveSecondsPerRow =
        (viewportWidth / scaledPixelsPerSecond).floor().toDouble();
    final double secondsPerRowScaled =
        adaptiveSecondsPerRow > config.minSecondsPerRow
            ? adaptiveSecondsPerRow
            : config.minSecondsPerRow;

    // 计算总所需行数
    final int totalDuration = tracks.fold(
        0,
        (max, track) => Math.max(
            max.toInt(),
            track.clips.fold(
                0,
                (maxTime, clip) => Math.max(maxTime.toInt(),
                    (clip.startTime + clip.duration).toInt()))));

    final int rowCount =
        (totalDuration / secondsPerRowScaled).ceil() + 1; // 额外添加一行作为缓冲

    // 计算行的高度
    double rowHeight = _calculateVisibleRowHeight(
      config,
      tracks.where((track) => track.isVisible).length,
      draggingState.isDragging,
      draggingState.dragStartTrackIndex,
    );

    // 获取 TimelineContent 区域的 RenderBox，用于计算全局坐标
    RenderBox? timelineRenderBox =
        _timelineAreaKey.currentContext?.findRenderObject() as RenderBox?;
    Offset timelineOffset =
        timelineRenderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    // 构建时间线滚动视图内容
    return Stack(
      key: _timelineAreaKey, // Assign key to the Stack
      children: [
        // 滚动视图
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            final playbackNotifier = ref.read(playbackProvider.notifier);

            // 检测用户手动滚动
            if (notification is ScrollUpdateNotification) {
              // 如果是用户拖动（而非程序触发的动画滚动）
              if (notification.dragDetails != null) {
                // 检测到用户手动滚动，禁用自动滚动
                if (!playbackState.disableAutoScroll) {
                  // 将自动滚动状态设置为禁用
                  playbackNotifier.setAutoScroll(false);
                  // 显示提示
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已禁用自动滚动，播放指针不会再自动滚动'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            }
            return false;
          },
          child: SingleChildScrollView(
            controller: scrollController,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (details) {
                _handlePlayheadPositionUpdate(details.globalPosition,
                    isDragging: false);
              },
              onPanStart: (details) {
                _dragStartTime = ref.read(playbackProvider).position;
                _handlePlayheadPositionUpdate(details.globalPosition,
                    isDragging: true);
                print("Global pan start: Time=$_dragStartTime");
              },
              onPanUpdate: (details) {
                _handlePlayheadPositionUpdate(details.globalPosition,
                    isDragging: true);
              },
              onPanEnd: (details) {
                print(
                    "Global pan end: Final Time=${ref.read(playbackProvider).position}");
                _dragStartTime = null;
              },
              child: SizedBox(
                height: rowHeight * rowCount,
                child: Stack(
                  children: [
                    // 生成所有行
                    Column(
                      children: List.generate(rowCount, (rowIndex) {
                        final double rowStartTime =
                            rowIndex * secondsPerRowScaled;
                        final double rowEndTime =
                            rowStartTime + secondsPerRowScaled;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 时间轴标尺
                            Stack(
                              children: [
                                TimelineRuler(
                                  rowStartTime: rowStartTime,
                                  rowEndTime: rowEndTime,
                                  rowIndex: rowIndex,
                                  rowCount: rowCount,
                                  viewportWidth: viewportWidth,
                                ),
                              ],
                            ),
                            // 轨道内容
                            _buildTracks(
                              ref,
                              rowStartTime: rowStartTime,
                              rowEndTime: rowEndTime,
                              viewportWidth: viewportWidth,
                            ),
                            // 行间距
                            SizedBox(height: config.rowSpacing),
                          ],
                        );
                      }),
                    ),
                    // 播放指针
                    Playhead(
                      viewportWidth: viewportWidth,
                      secondsPerRowScaled: secondsPerRowScaled,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 拖动状态指示器
        _buildDraggingPositionIndicator(ref),
      ],
    );
  }

  // 构建轨道内容
  Widget _buildTracks(
    WidgetRef ref, {
    required double rowStartTime,
    required double rowEndTime,
    required double viewportWidth,
  }) {
    final tracks = ref.watch(tracksProvider);
    final draggingState = ref.watch(draggingStateProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(tracks.length, (trackIndex) {
        final track = tracks[trackIndex];

        // 如果轨道设置为不可见，则不显示
        if (!track.isVisible) {
          return const SizedBox();
        }

        // 如果正在拖动且不是活跃轨道，则不显示
        if (draggingState.isDragging &&
            draggingState.dragStartTrackIndex != null &&
            trackIndex != draggingState.dragStartTrackIndex) {
          return const SizedBox(height: 0); // 返回高度为0的轨道占位
        }

        // --- Always use TrackItem for all visible tracks ---
        return TrackItem(
          key: ValueKey(
              'track_${trackIndex}_${rowStartTime}'), // Use consistent key naming
          track: track,
          trackIndex: trackIndex,
          rowStartTime: rowStartTime,
          rowEndTime: rowEndTime,
          viewportWidth: viewportWidth,
        );
        // --- End change ---
      }),
    );
  }

  // 生成正在拖动的片段位置指示器
  Widget _buildDraggingPositionIndicator(WidgetRef ref) {
    final draggingState = ref.watch(draggingStateProvider);

    // Check isDragging and if we have a current drag position
    if (!draggingState.isDragging ||
        draggingState.currentDragPosition == null) {
      return const SizedBox();
    }

    // Calculate the approximate time based on drag position if needed
    // (For now, just show a generic dragging indicator or use dragStartTime)
    final startTimeStr = draggingState.dragStartTime?.toStringAsFixed(2) ?? '?';

    return Positioned(
      top: 4,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          // Simplify: Show only start time or a generic message
          'Dragging from: ${startTimeStr}s',
          // '${draggingState.draggingClip!.name}: ${draggingState.draggingClip!.startTime.toStringAsFixed(2)}s', // Old code causing error
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  // 计算可见行高 - Use dragStartTrackIndex
  double _calculateVisibleRowHeight(DawConfig config, int visibleTrackCount,
      bool isDragging, int? dragStartTrackIndex) {
    // Parameter renamed
    if (isDragging && dragStartTrackIndex != null) {
      // Check renamed parameter
      // 拖动状态下，行高只计算时间轴+活跃轨道+间距
      return config.timelineHeight + config.trackHeight + config.rowSpacing;
    } else {
      // 正常状态下，行高为时间轴+可见轨道+间距
      return config.timelineHeight +
          (visibleTrackCount * config.trackHeight) +
          config.rowSpacing;
    }
  }

  // Helper function to handle both tap and drag updates for playhead position
  void _handlePlayheadPositionUpdate(Offset globalPosition,
      {required bool isDragging}) {
    final config = ref.read(dawConfigProvider);
    final zoomState = ref.read(zoomProvider);
    final snappingState = ref.read(snappingProvider);
    final timeContext = ref.read(tu.timeContextProvider.notifier);
    final viewportWidth = ref.read(viewportWidthProvider);
    final scrollController = ref.read(scrollControllerProvider);
    final playbackNotifier = ref.read(playbackProvider.notifier);
    final tracks = ref.read(tracksProvider);
    final draggingState = ref.read(draggingStateProvider);

    // Get RenderBox info again (might have changed)
    RenderBox? timelineRenderBox =
        _timelineAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (timelineRenderBox == null || viewportWidth <= 0)
      return; // Need context and width
    Offset timelineOffset = timelineRenderBox.localToGlobal(Offset.zero);

    // Calculate scaled pixels per second and seconds per row
    final double scaledPixelsPerSecond =
        config.pixelsPerSecond * zoomState.scale;
    final double adaptiveSecondsPerRow =
        (viewportWidth / scaledPixelsPerSecond).floor().toDouble();
    final double secondsPerRowScaled =
        adaptiveSecondsPerRow > config.minSecondsPerRow
            ? adaptiveSecondsPerRow
            : config.minSecondsPerRow;

    // Calculate row height (needs to be consistent)
    final int visibleTrackCount =
        tracks.where((track) => track.isVisible).length;
    // Note: Use the _calculateVisibleRowHeight from this class, not Playhead's
    final double rowHeight = _calculateVisibleRowHeight(
        config,
        visibleTrackCount,
        draggingState.isDragging,
        draggingState.dragStartTrackIndex);
    if (rowHeight <= 0) return; // Avoid division by zero

    // Calculate vertical position within the scrollable content
    final double contentY =
        globalPosition.dy - timelineOffset.dy + scrollController.offset;

    // Calculate the target row index
    int targetRowIndex = (contentY / rowHeight).floor();
    // Clamp row index
    // final int maxRowIndex = (config.totalSeconds / secondsPerRowScaled).ceil();
    // targetRowIndex = targetRowIndex.clamp(0, maxRowIndex);

    // Calculate horizontal position within the viewport
    final double contentX = globalPosition.dx - timelineOffset.dx;

    // Calculate time within that row
    final double timeInRow = (contentX / viewportWidth) * secondsPerRowScaled;

    // Calculate the target row's start time
    final double targetRowStartTime = targetRowIndex * secondsPerRowScaled;

    // Calculate raw target time
    double rawTargetTime = targetRowStartTime + timeInRow;

    // Apply snapping
    double finalTargetTime = _applyGlobalSnapping(
      rawTargetTime,
      isDragging ? _dragStartTime : null, // Pass original time only for drag
      snappingState,
      timeContext,
    );

    // Clamp final time
    finalTargetTime = finalTargetTime.clamp(0.0, config.totalSeconds);

    // --- Update Playback Position ---
    // Only seek if the time actually changed (avoid redundant seeks)
    if ((finalTargetTime - ref.read(playbackProvider).position).abs() > 0.001) {
      playbackNotifier.seekTo(finalTargetTime);
    }

    // Disable auto-scroll on tap or drag start
    if (!isDragging || _dragStartTime != null) {
      // Apply on tap or first drag update
      playbackNotifier.setAutoScroll(true); // Disable
    }

    // Debug print (optional)
    // print("Handle Update: Global=(${globalPosition.dx.toStringAsFixed(1)}, ${globalPosition.dy.toStringAsFixed(1)}) Offset=${scrollController.offset.toStringAsFixed(1)} -> Row=$targetRowIndex, X=$contentX -> RawT=${rawTargetTime.toStringAsFixed(3)}, FinalT=${finalTargetTime.toStringAsFixed(3)}");
  }

  // Helper function for global snapping logic
  double _applyGlobalSnapping(
    double rawTime,
    double? originalTime, // Nullable, only used for drag snap-back
    SnappingState snappingState,
    tu.TimeContext timeContext,
  ) {
    if (!snappingState.isEnabled) {
      return rawTime; // Snapping disabled
    }

    double snappingIntervalSeconds;
    switch (snappingState.mode) {
      case SnappingMode.bar:
        snappingIntervalSeconds = timeContext.getSecondsPerBarAt(rawTime);
        break;
      case SnappingMode.beat:
        snappingIntervalSeconds = timeContext.getSecondsPerBeatAt(rawTime);
        break;
      case SnappingMode.halfBeat:
        snappingIntervalSeconds =
            timeContext.getSecondsPerBeatAt(rawTime) / 2.0;
        break;
      case SnappingMode.quarterBeat:
        snappingIntervalSeconds =
            timeContext.getSecondsPerBeatAt(rawTime) / 4.0;
        break;
      case SnappingMode.off:
        return rawTime;
    }

    if (snappingIntervalSeconds <= 0) {
      return rawTime; // Invalid interval
    }

    // Snap Back to Origin Logic (Only during drag)
    if (originalTime != null) {
      final double snapBackToleranceSeconds = snappingIntervalSeconds * 0.25;
      if ((rawTime - originalTime).abs() <= snapBackToleranceSeconds) {
        return originalTime;
      }
    }

    // Normal Snapping
    final int nearestSnapPointIndex =
        (rawTime / snappingIntervalSeconds).round();
    final double snappedTime = nearestSnapPointIndex * snappingIntervalSeconds;
    return snappedTime;
  }
}
