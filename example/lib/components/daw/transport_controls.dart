import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/daw_providers.dart';
import '../../utils/time_utils.dart';

/// 播放控制组件 - 显示时间码和提供播放控制功能
class TransportControls extends ConsumerWidget {
  const TransportControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(dawConfigProvider);
    final playbackState = ref.watch(playbackProvider);
    final playbackNotifier = ref.read(playbackProvider.notifier);
    final timeUtils = ref.watch(timeUtilsProvider);

    // 将秒数转换为小节信息
    final barInfo = timeUtils.secondsToBarInfo(playbackState.position);

    // 创建时间码显示
    final String barTimeDisplay =
        "${barInfo['bar']}.${barInfo['beat']}.${barInfo['ticks'].toString().padLeft(2, '0')}";
    final String secondsDisplay = _formatTime(playbackState.position);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 回到开头按钮
          IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: () => playbackNotifier.seekTo(0.0),
            tooltip: '回到开头',
            iconSize: 20,
          ),

          // 播放/暂停按钮
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                  playbackState.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Theme.of(context).primaryColor),
              onPressed: () => _togglePlay(ref),
              iconSize: 28,
              tooltip: playbackState.isPlaying ? '暂停' : '播放',
            ),
          ),

          // 停止按钮
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () => playbackNotifier.stop(),
            tooltip: '停止',
            iconSize: 20,
          ),

          const SizedBox(width: 12),

          // 浅色主题的DAW时间显示面板
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 小节显示
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: Row(
                  children: [
                    // 小节图标
                    Icon(
                      Icons.music_note,
                      color: Colors.green[600],
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    // 小节文本
                    Text(
                      barTimeDisplay,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        color: Colors.grey[800],
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 时间显示
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: Row(
                  children: [
                    // 时钟图标
                    Icon(
                      Icons.timer,
                      color: Colors.blue[600],
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    // 时间文本
                    Text(
                      secondsDisplay,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        color: Colors.grey[800],
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),

          // BPM显示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            margin: const EdgeInsets.only(right: 8.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Row(
              children: [
                Text(
                  "BPM",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "${timeUtils.bpm.toStringAsFixed(1)}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),

          // 添加自动滚动切换按钮
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: Icon(
                playbackState.disableAutoScroll
                    ? Icons.lock_outline
                    : Icons.lock_open_outlined,
                color: playbackState.disableAutoScroll
                    ? Colors.red.shade400
                    : Colors.green.shade700,
                size: 20,
              ),
              tooltip: playbackState.disableAutoScroll ? '启用自动滚动' : '禁用自动滚动',
              onPressed: () =>
                  ref.read(playbackProvider.notifier).toggleAutoScroll(),
            ),
          ),
        ],
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
