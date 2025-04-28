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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左侧信息区域 - Wrap with Flexible
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 8), // Reduced left padding
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min, // Shrink row to fit content
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
                          const SizedBox(width: 8), // Reduced spacing

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
                      const SizedBox(
                          width: 16), // Add some space between skip and stop
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

                  // 右侧 - 磁吸和自动滚动控制
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 磁吸按钮
                      Consumer(builder: (context, ref, child) {
                        final snappingState = ref.watch(snappingProvider);
                        return IconButton(
                          icon: Icon(
                            Icons.auto_fix_high,
                            color: snappingState.isEnabled
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[600],
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 36, minHeight: 36),
                          tooltip:
                              '节拍吸附设置 (${snappingState.isEnabled ? snappingState.mode.displayName : "关"})',
                          onPressed: () => _showSnappingOptions(context, ref),
                        );
                      }),
                      const SizedBox(width: 4),
                      // 自动滚动控制
                      InkWell(
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
                    ],
                  )
                ],
              ),
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

  // 显示吸附选项菜单
  void _showSnappingOptions(BuildContext context, WidgetRef ref) {
    final snappingNotifier = ref.read(snappingProvider.notifier);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(builder: (context, ref, child) {
          final snappingState = ref.watch(snappingProvider);

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                  child: Text(
                    '节拍吸附设置',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                // 总开关
                SwitchListTile(
                  title: const Text('启用吸附'),
                  value: snappingState.isEnabled,
                  onChanged: (bool value) {
                    snappingNotifier.toggleEnabled();
                    // Optionally close the sheet immediately after toggling enabled state
                    // Navigator.pop(context);
                  },
                  dense: true,
                ),
                const Divider(),
                // 吸附精度选项
                ...SnappingMode.values
                    .where((mode) =>
                        mode !=
                        SnappingMode.off) // Exclude 'off' from radio options
                    .map((mode) {
                  return RadioListTile<SnappingMode>(
                    title: Text(mode.displayName),
                    value: mode,
                    groupValue: snappingState.isEnabled
                        ? snappingState.mode
                        : null, // Only show selection if enabled
                    onChanged: snappingState.isEnabled
                        ? (SnappingMode? value) {
                            if (value != null) {
                              snappingNotifier.setMode(value);
                              Navigator.pop(
                                  context); // Close sheet after selection
                            }
                          }
                        : null, // Disable options if snapping is off
                    dense: true,
                    controlAffinity: ListTileControlAffinity.trailing,
                  );
                }).toList(),
                // 添加一个明确的"关闭"选项
                ListTile(
                  leading: Icon(Icons.close,
                      color: !snappingState.isEnabled
                          ? Theme.of(context).colorScheme.primary
                          : null),
                  title: const Text('关闭吸附'),
                  onTap: () {
                    snappingNotifier.setMode(
                        SnappingMode.off); // Setting mode to off also disables
                    Navigator.pop(context);
                  },
                  dense: true,
                  selected: !snappingState.isEnabled,
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
