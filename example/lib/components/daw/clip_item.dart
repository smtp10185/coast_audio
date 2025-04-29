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
    super.key,
    required this.clip,
    required this.trackIndex,
    required this.rowStartTime,
    required this.rowEndTime,
    required this.viewportWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(dawConfigProvider);
    final draggingState = ref.watch(draggingStateProvider);
    final draggingNotifier = ref.read(draggingStateProvider.notifier);
    final zoomState = ref.watch(zoomProvider);

    // 计算缩放后的每秒像素数
    final double scaledPixelsPerSecond =
        config.pixelsPerSecond * zoomState.scale;

    // 检查片段是否在当前行的范围内
    final clipStartTime = clip.startTime;
    final clipEndTime = clip.startTime + clip.duration;

    // 如果片段完全在当前行之外，就不显示
    if (clipEndTime <= rowStartTime || clipStartTime >= rowEndTime) {
      return const SizedBox();
    }

    // Total width of the clip in pixels based on its duration
    final double totalClipPixelWidth = clip.duration * scaledPixelsPerSecond;
    // Position of the clip's left edge relative to the start of the row in pixels
    final double clipLeftPixel =
        (clip.startTime - rowStartTime) * scaledPixelsPerSecond;

    // 判断是否为当前正在拖动的片段
    final bool isCurrentlyDragging = draggingState.isDragging &&
        draggingState.draggingClipId != null &&
        draggingState.draggingClipId == clip.id;

    // 是否为和弦片段
    final bool isChordClip = clip.type == ClipType.chord;

    return Positioned(
      key: ValueKey('clip_${clip.id}'),
      left: clipLeftPixel,
      top: 4,
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
        onTap: () {
          // 点击和弦片段时显示和弦详情或跳转到和弦编辑页面
          if (isChordClip) {
            // 显示和弦信息的Toast
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('和弦: ${clip.chordValue}'),
                duration: const Duration(seconds: 1),
                action: SnackBarAction(
                  label: '编辑',
                  onPressed: () {
                    // 这里可以添加跳转到和弦编辑页面的逻辑
                    print('编辑和弦 ${clip.chordValue}');
                  },
                ),
              ),
            );
          }
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Container(
            width: totalClipPixelWidth,
            height: config.trackHeight - 10,
            decoration: BoxDecoration(
              color: isChordClip
                  ? Colors.transparent // 和弦片段使用透明背景
                  : clip.color.withOpacity(0.7),
              border: Border.all(
                color: isCurrentlyDragging
                    ? Colors.yellow
                    : isChordClip
                        ? Colors.transparent // 和弦片段不需要边框
                        : clip.color,
                width: isCurrentlyDragging ? 2 : 1,
              ),
              borderRadius:
                  isChordClip ? BorderRadius.zero : BorderRadius.circular(4),
              boxShadow: isCurrentlyDragging && !isChordClip
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(2, 2),
                      )
                    ]
                  : null,
            ),
            child: _buildClipContent(totalClipPixelWidth, isChordClip),
          ),
        ),
      ),
    );
  }

  // 构建片段内容
  Widget _buildClipContent(double clipWidth, bool isChordClip) {
    if (isChordClip) {
      // 定义渲染标记+文本所需的最小宽度 (例如，标记2px + 边距4px + 文本最小空间4px)
      const double minWidthForFullContent = 10.0;

      // 如果可用宽度太小，则只显示起始标记线
      if (clipWidth < minWidthForFullContent) {
        return Container(
          width: 2, // 仅显示起始标记的宽度
          color: Colors.deepPurple,
          alignment: Alignment.centerLeft, // 确保它靠左
        );
      }

      // 如果宽度足够，则显示完整的 Row (标记 + 文本)
      return Row(
        key: const ValueKey(
            'chord_clip_content_row'), // Add key for potential state issues
        children: [
          // 左侧位置标记
          Container(
            width: 2,
            color: Colors.deepPurple,
            margin: const EdgeInsets.only(right: 4),
          ),
          // 和弦文本
          Expanded(
            child: Text(
              clip.chordValue ?? '?',
              style: const TextStyle(
                color: Colors.deepPurple,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      // 普通片段的显示
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
        child: Center(
          child: clipWidth > 40
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
      );
    }
  }
}
