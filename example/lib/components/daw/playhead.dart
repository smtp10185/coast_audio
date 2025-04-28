import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/daw_providers.dart';
import '../../utils/time_utils.dart';
import 'dart:math' as Math;

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

    // final snappingState = ref.watch(snappingProvider);

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

    // Use Transform.translate to position the intrinsically sized Column
    return Transform.translate(
      offset: Offset(exactXPosition, yPosition),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap the triangle in a Transform.translate to center it over the line
          Transform.translate(
            offset: const Offset(-4.5,
                0), // (Line width / 2) - (Triangle width / 2) = 0.5 - 5 = -4.5
            child: CustomPaint(
              size: const Size(10, 6),
              painter: TrianglePainter(color: Colors.red),
            ),
          ),
          // 垂直线 - 精确计算高度，不延伸到间距
          Container(
            width: 1,
            height: contentHeight - 6, // Adjust for triangle height
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  // Copied from original Playhead - kept inside the State class
  double _calculateVisibleRowHeight(
    DawConfig config, // Use DawConfig type
    int visibleTrackCount,
    bool isDragging,
    int? dragStartTrackIndex,
  ) {
    if (isDragging && dragStartTrackIndex != null) {
      return config.timelineHeight + config.trackHeight + config.rowSpacing;
    } else {
      return config.timelineHeight +
          (visibleTrackCount * config.trackHeight) +
          config.rowSpacing;
    }
  }
}

// Simple triangle painter for the playhead marker
class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, size.height); // Bottom center
    path.lineTo(0, 0); // Top left
    path.lineTo(size.width, 0); // Top right
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
