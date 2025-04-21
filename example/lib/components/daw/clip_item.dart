import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/daw_providers.dart';
import '../../models/clip.dart';

/// 音频片段项 - 显示单个音频片段
class ClipItem extends ConsumerWidget {
  final Clip clip;
  final int trackIndex;
  final double rowStartTime;
  final double rowEndTime;
  final double viewportWidth;

  const ClipItem({
    Key? key,
    required this.clip,
    required this.trackIndex,
    required this.rowStartTime,
    required this.rowEndTime,
    required this.viewportWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(dawConfigProvider);
    final draggingState = ref.watch(draggingStateProvider);
    final draggingNotifier = ref.read(draggingStateProvider.notifier);
    final zoomState = ref.watch(zoomProvider);

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

    // 检查片段是否在当前行的范围内
    final clipStartTime = clip.startTime;
    final clipEndTime = clip.startTime + clip.duration;

    // 如果片段完全在当前行之外，就不显示
    if (clipEndTime <= rowStartTime || clipStartTime >= rowEndTime) {
      return const SizedBox();
    }

    // 计算片段在当前行中的开始和结束时间
    final double startInRow =
        (clipStartTime > rowStartTime) ? clipStartTime - rowStartTime : 0;
    final double endInRow = (clipEndTime < rowEndTime)
        ? clipEndTime - rowStartTime
        : rowEndTime - rowStartTime;

    // 计算片段在当前行中的宽度（根据视口宽度自适应）
    final double clipWidthInRow =
        (endInRow - startInRow) / (rowEndTime - rowStartTime) * viewportWidth;

    // 计算片段在当前行中的位置（根据视口宽度自适应）
    final double clipLeftInRow =
        startInRow / (rowEndTime - rowStartTime) * viewportWidth;

    // 判断是否为当前正在拖动的片段
    final bool isCurrentlyDragging = draggingState.isDragging &&
        draggingState.draggingClip != null &&
        draggingState.draggingClip!.name == clip.name &&
        draggingState.draggingClip!.type == clip.type &&
        draggingState.draggingClip!.color == clip.color;

    return Positioned(
      key: ValueKey('clip_${clip.name}_${clip.startTime}'), // 添加key确保刷新
      left: clipLeftInRow,
      top: 4, // 调整位置，不再需要为轨道名称留空间
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // 确保即使在透明区域也能捕获事件
        onPanStart: (details) {
          // 添加轻微触觉反馈
          HapticFeedback.lightImpact();
          draggingNotifier.startDragging(
              clip, trackIndex, details.globalPosition);
        },
        onPanUpdate: (details) {
          if (isCurrentlyDragging) {
            draggingNotifier.updateDragging(details.globalPosition);
          }
        },
        onPanEnd: (details) {
          if (isCurrentlyDragging) {
            // 添加触觉反馈，表示拖动结束
            HapticFeedback.mediumImpact();
            draggingNotifier.endDragging();
          }
        },
        // 保留原有的长按处理以兼容移动设备
        onLongPressStart: (details) {
          // 添加触觉反馈，表示长按开始
          HapticFeedback.mediumImpact();
          draggingNotifier.startDragging(
              clip, trackIndex, details.globalPosition);
        },
        onLongPressMoveUpdate: (details) {
          if (isCurrentlyDragging) {
            draggingNotifier.updateDragging(details.globalPosition);
          }
        },
        onLongPressEnd: (details) {
          if (isCurrentlyDragging) {
            draggingNotifier.endDragging();
          }
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Container(
            width: clipWidthInRow,
            height: config.trackHeight - 10, // 调整高度，更贴近轨道高度
            decoration: BoxDecoration(
              color: clip.color.withOpacity(0.7),
              border: Border.all(
                color: isCurrentlyDragging ? Colors.yellow : clip.color,
                width: isCurrentlyDragging ? 2 : 1,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(clipStartTime >= rowStartTime ? 4 : 0),
                bottomLeft:
                    Radius.circular(clipStartTime >= rowStartTime ? 4 : 0),
                topRight: Radius.circular(clipEndTime <= rowEndTime ? 4 : 0),
                bottomRight: Radius.circular(clipEndTime <= rowEndTime ? 4 : 0),
              ),
              // 拖动时添加阴影效果
              boxShadow: isCurrentlyDragging
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(2, 2),
                      )
                    ]
                  : null,
            ),
            // 简化内容显示
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
              child: Center(
                child: clipWidthInRow > 40
                    ? Text(
                        '${clip.name} (${clip.startTime.toStringAsFixed(1)}s)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : const SizedBox(), // 宽度不足时不显示文本
              ),
            ),
          ),
        ),
      ),
    );
  }
}
