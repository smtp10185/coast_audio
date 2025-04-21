import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/daw_providers.dart';
import '../../models/track.dart';

/// 轨道侧边栏 - 显示轨道列表及其控制按钮
class TrackSidebar extends ConsumerWidget {
  const TrackSidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(tracksProvider);
    final tracksNotifier = ref.read(tracksProvider.notifier);
    final config = ref.watch(dawConfigProvider);
    final draggingState = ref.watch(draggingStateProvider);

    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey[300]!)),
        color: Colors.grey[100],
      ),
      child: Column(
        children: [
          // 侧边栏标题
          Container(
            height: config.timelineHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              color: Colors.grey[200],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '轨道',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                // 添加新轨道按钮
                InkWell(
                  onTap: () {
                    // 这里可以添加创建新轨道的功能
                  },
                  child: Icon(
                    Icons.add_circle_outline,
                    size: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          // 轨道列表
          Expanded(
            child: ListView.builder(
              itemCount: tracks.length,
              itemExtent: config.trackHeight,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, trackIndex) {
                final track = tracks[trackIndex];
                final Color trackColor =
                    tracksNotifier.getTrackColor(trackIndex);

                // 如果轨道设置为不可见且正在拖动，则不显示
                if (draggingState.isDragging &&
                    draggingState.activeTrackIndex != null &&
                    trackIndex != draggingState.activeTrackIndex) {
                  return SizedBox(height: 0);
                }

                // 如果轨道不可见，显示半透明样式
                final bool isVisible = track.isVisible;

                return TrackSidebarItem(
                  track: track,
                  trackIndex: trackIndex,
                  trackColor: trackColor,
                  isVisible: isVisible,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 轨道侧边栏项 - 单个轨道的控件
class TrackSidebarItem extends ConsumerWidget {
  final Track track;
  final int trackIndex;
  final Color trackColor;
  final bool isVisible;

  const TrackSidebarItem({
    Key? key,
    required this.track,
    required this.trackIndex,
    required this.trackColor,
    required this.isVisible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(dawConfigProvider);
    final tracksNotifier = ref.read(tracksProvider.notifier);

    return Container(
      height: config.trackHeight,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        color: trackIndex % 2 == 0 ? Colors.grey[50] : Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => tracksNotifier.toggleTrackVisibility(trackIndex),
          onLongPress: () {
            // 可以在这里添加显示轨道更多选项的功能
            // 例如重命名、删除等
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: [
                // 轨道颜色指示器
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: trackColor.withOpacity(isVisible ? 1.0 : 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),

                // 轨道名称
                Expanded(
                  child: Text(
                    track.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color:
                          Colors.grey[800]!.withOpacity(isVisible ? 1.0 : 0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // 可见性按钮
                SizedBox(
                  width: 22,
                  height: 22,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 14,
                    icon: Icon(
                      track.isVisible ? Icons.visibility : Icons.visibility_off,
                      color: track.isVisible
                          ? Colors.blue.withOpacity(0.8)
                          : Colors.grey[400],
                    ),
                    onPressed: () =>
                        tracksNotifier.toggleTrackVisibility(trackIndex),
                  ),
                ),

                // 静音按钮
                SizedBox(
                  width: 22,
                  height: 22,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 14,
                    icon: Icon(
                      track.isMuted ? Icons.volume_off : Icons.volume_up,
                      color: track.isMuted
                          ? Colors.red.withOpacity(isVisible ? 1.0 : 0.5)
                          : Colors.grey[700]!
                              .withOpacity(isVisible ? 1.0 : 0.5),
                    ),
                    onPressed: () => tracksNotifier.toggleTrackMute(trackIndex),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
