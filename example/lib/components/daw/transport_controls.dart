import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/daw_providers.dart';
import '../../utils/time_utils.dart';

/// 播放控制组件 - 显示时间码和提供播放控制功能
/// 作为底部控制栏使用，设计更加紧凑
class TransportControls extends ConsumerWidget {
  const TransportControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackProvider);
    final playbackNotifier = ref.read(playbackProvider.notifier);
    final timeUtils = ref.watch(timeUtilsProvider);

    // 将秒数转换为小节信息
    final barInfo = timeUtils.secondsToBarInfo(playbackState.position);

    // 创建时间码显示
    final String barTimeDisplay =
        "${barInfo['bar']}.${barInfo['beat']}.${barInfo['ticks'].toString().padLeft(2, '0')}";
    final String secondsDisplay = _formatTime(playbackState.position);
    final String bpmDisplay = timeUtils.bpm.toStringAsFixed(1);

    return Material(
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.only(top: 6, bottom: 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 主要控制按钮行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左侧信息区域
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(
                      children: [
                        // 小节显示
                        Icon(
                          Icons.music_note,
                          size: 14,
                          color: Colors.green[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          barTimeDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 12),

                        // BPM显示
                        Icon(
                          Icons.speed,
                          size: 14,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$bpmDisplay",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 中间播放控制按钮组
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 回到开头按钮
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        onPressed: () => playbackNotifier.seekTo(0.0),
                        tooltip: '回到开头',
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        color: Colors.grey[800],
                      ),

                      // 播放/暂停按钮
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            playbackState.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () => _togglePlay(ref),
                          iconSize: 28,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                          tooltip: playbackState.isPlaying ? '暂停' : '播放',
                        ),
                      ),

                      // 停止按钮
                      IconButton(
                        icon: const Icon(Icons.stop),
                        onPressed: () => playbackNotifier.stop(),
                        tooltip: '停止',
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        color: Colors.grey[800],
                      ),
                    ],
                  ),

                  // 右侧自动滚动控制
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: InkWell(
                      onTap: () => ref
                          .read(playbackProvider.notifier)
                          .toggleAutoScroll(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              playbackState.disableAutoScroll
                                  ? Icons.lock_outline
                                  : Icons.lock_open_outlined,
                              size: 14,
                              color: playbackState.disableAutoScroll
                                  ? Colors.red.shade400
                                  : Colors.green.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              playbackState.disableAutoScroll ? '锁定' : '滚动',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 时间显示，以文本形式显示在底部
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  secondsDisplay,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 格式化时间为 MM:SS 格式
  String _formatTime(double seconds) {
    final int mins = (seconds / 60).floor();
    final int secs = (seconds % 60).floor();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // 开始播放
  void _togglePlay(WidgetRef ref) {
    final playbackNotifier = ref.read(playbackProvider.notifier);
    playbackNotifier.togglePlay();
  }
}
