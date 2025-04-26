import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/daw_providers.dart';
import '../../models/track.dart';
import 'clip_item.dart';

/// 轨道项 - 显示单个轨道内容
class TrackItem extends ConsumerWidget {
  final Track track;
  final int trackIndex;
  final double rowStartTime;
  final double rowEndTime;
  final double viewportWidth;

  const TrackItem({
    super.key,
    required this.track,
    required this.trackIndex,
    required this.rowStartTime,
    required this.rowEndTime,
    required this.viewportWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(dawConfigProvider);
    final tracksNotifier = ref.read(tracksProvider.notifier);
    final Color trackColor = track.type == TrackType.chord
        ? Colors.purple // 和弦轨道使用固定的紫色
        : tracksNotifier.getTrackColor(trackIndex);

    final bool isChordTrack = track.type == TrackType.chord;

    return SizedBox(
      height: config.trackHeight,
      width: viewportWidth,
      child: Stack(
        children: [
          // 轨道背景
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
                color: isChordTrack
                    ? Colors.transparent // 和弦轨道使用透明背景
                    : trackIndex % 2 == 0
                        ? Colors.grey[50]
                        : Colors.white,
              ),
              // 左侧边框颜色指示器和标识
              child: Row(
                children: [
                  Container(
                    width: 3,
                    color: trackColor.withOpacity(0.7),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),

          // 绘制轨道上的所有片段
          ...track.clips
              .map((clip) => ClipItem(
                    clip: clip,
                    trackIndex: trackIndex,
                    rowStartTime: rowStartTime,
                    rowEndTime: rowEndTime,
                    viewportWidth: viewportWidth,
                  ))
              .toList(),
        ],
      ),
    );
  }
}
