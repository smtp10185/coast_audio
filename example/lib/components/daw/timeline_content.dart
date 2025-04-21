import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/daw_providers.dart';
import 'dart:math' as Math;
import 'timeline_ruler.dart';
import 'track_item.dart';
import 'playhead.dart';

/// 时间线内容 - 显示时间轴和轨道内容的主要区域
class TimelineContent extends ConsumerWidget {
  const TimelineContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      draggingState.activeTrackIndex,
    );

    // 构建时间线滚动视图内容
    return Stack(
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
            child: SizedBox(
              height: rowHeight * rowCount,
              child: Stack(
                children: [
                  // 生成所有行
                  Column(
                    children: List.generate(rowCount, (rowIndex) {
                      // 计算当前行的时间范围
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

                              // 为当前行添加一个高亮指示器，方便调试
                              // 如果是当前拖动片段所在的行，显示高亮背景
                              if (draggingState.isDragging &&
                                  draggingState.draggingClip != null &&
                                  rowIndex ==
                                      (draggingState.draggingClip!.startTime /
                                              secondsPerRowScaled)
                                          .floor())
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.yellow.withOpacity(0.1),
                                  ),
                                ),
                            ],
                          ),

                          // 轨道内容 - 移除左侧的轨道名称，只显示内容部分
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
            draggingState.activeTrackIndex != null &&
            trackIndex != draggingState.activeTrackIndex) {
          return const SizedBox(height: 0); // 返回高度为0的轨道占位
        }

        return TrackItem(
          track: track,
          trackIndex: trackIndex,
          rowStartTime: rowStartTime,
          rowEndTime: rowEndTime,
          viewportWidth: viewportWidth,
        );
      }),
    );
  }

  // 生成正在拖动的片段位置指示器
  Widget _buildDraggingPositionIndicator(WidgetRef ref) {
    final draggingState = ref.watch(draggingStateProvider);

    if (!draggingState.isDragging || draggingState.draggingClip == null) {
      return const SizedBox();
    }

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
          '${draggingState.draggingClip!.name}: ${draggingState.draggingClip!.startTime.toStringAsFixed(2)}s',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  // 计算可见行高
  double _calculateVisibleRowHeight(final config, int visibleTrackCount,
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
