import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/daw_providers.dart';

/// 播放指针 - 显示当前播放位置的指示器
class Playhead extends ConsumerWidget {
  final double viewportWidth;
  final double secondsPerRowScaled;

  const Playhead({
    super.key,
    required this.viewportWidth,
    required this.secondsPerRowScaled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(dawConfigProvider);
    final playbackState = ref.watch(playbackProvider);
    final tracks = ref.watch(tracksProvider);
    final draggingState = ref.watch(draggingStateProvider);

    // 如果每行显示的时间太短，不显示播放指针
    if (secondsPerRowScaled < config.minSecondsPerRow) return const SizedBox();

    // 计算当前播放位置所在的行
    final int currentRow =
        (playbackState.position / secondsPerRowScaled).floor();

    // 计算当前行内的位置（秒）
    final double positionInRow =
        playbackState.position - (currentRow * secondsPerRowScaled);

    // 计算每秒对应的像素数
    final double pixelsPerSecond = viewportWidth / secondsPerRowScaled;

    // 计算精确的位置
    final double exactXPosition = positionInRow * pixelsPerSecond;

    // 使用整数对齐避免抗锯齿导致的模糊
    final int pixelX = exactXPosition.round();

    // 计算可见轨道数
    final int visibleTrackCount =
        tracks.where((track) => track.isVisible).length;

    // 计算行的完整高度（包含间距）
    double rowHeight = _calculateVisibleRowHeight(
      config,
      visibleTrackCount,
      draggingState.isDragging,
      draggingState.dragStartTrackIndex,
    );

    // 计算不包含间距的实际内容高度
    double contentHeight;
    if (draggingState.isDragging && draggingState.dragStartTrackIndex != null) {
      // 拖动状态下只有一个轨道
      contentHeight = config.timelineHeight + config.trackHeight;
    } else {
      // 正常状态下是所有可见轨道
      contentHeight =
          config.timelineHeight + (visibleTrackCount * config.trackHeight);
    }

    // 计算当前行的垂直位置
    final double yPosition = currentRow * rowHeight;

    return Positioned(
      left: pixelX.toDouble(),
      top: yPosition,
      child: Column(
        children: [
          // 顶部圆点标记
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          // 垂直线 - 精确计算高度，不延伸到间距
          Container(
            width: 1,
            height: contentHeight - 5, // 减去圆点高度，且不包含行间距
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  // 计算可见行高
  double _calculateVisibleRowHeight(final config, int visibleTrackCount,
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
