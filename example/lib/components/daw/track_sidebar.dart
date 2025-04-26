import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/daw_providers.dart';
import '../../models/track.dart';

/// 轨道侧边栏 - 显示轨道列表及其控制按钮
/// 为移动设备优化的触摸友好设计
class TrackSidebar extends ConsumerWidget {
  const TrackSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(tracksProvider);
    final tracksNotifier = ref.read(tracksProvider.notifier);
    final config = ref.watch(dawConfigProvider);
    final draggingState = ref.watch(draggingStateProvider);

    // 使用SafeArea确保内容不会被系统UI遮挡
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min, // 确保Column只占用必要空间
        children: [
          // 轨道列表标题和添加按钮
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '轨道管理',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                // 添加新轨道按钮
                TextButton.icon(
                  onPressed: () {
                    // 这里可以添加创建新轨道的功能
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加轨道', style: TextStyle(fontSize: 14)),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(80, 32),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 轨道列表 - 使用Expanded确保填充剩余空间但不溢出
          Expanded(
            child: tracks.isEmpty
                ? _buildEmptyState()
                : _buildTrackList(tracks, tracksNotifier, draggingState),
          ),
        ],
      ),
    );
  }

  // 空状态提示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_note, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            '没有轨道',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '点击"添加轨道"按钮',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // 轨道列表
  Widget _buildTrackList(
    List<Track> tracks,
    dynamic tracksNotifier,
    dynamic draggingState,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shrinkWrap: true, // 确保ListView适应内容大小
      itemCount: tracks.length,
      itemBuilder: (context, trackIndex) {
        final track = tracks[trackIndex];
        final Color trackColor = tracksNotifier.getTrackColor(trackIndex);

        // 如果轨道设置为不可见且正在拖动，则不显示
        if (draggingState.isDragging &&
            draggingState.activeTrackIndex != null &&
            trackIndex != draggingState.activeTrackIndex) {
          return const SizedBox();
        }

        // 如果轨道不可见，显示半透明样式
        final bool isVisible = track.isVisible;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: TrackListItem(
            track: track,
            trackIndex: trackIndex,
            trackColor: trackColor,
            isVisible: isVisible,
          ),
        );
      },
    );
  }
}

/// 轨道列表项 - 单个轨道的卡片式显示，触摸友好设计
class TrackListItem extends ConsumerWidget {
  final Track track;
  final int trackIndex;
  final Color trackColor;
  final bool isVisible;

  const TrackListItem({
    Key? key,
    required this.track,
    required this.trackIndex,
    required this.trackColor,
    required this.isVisible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksNotifier = ref.read(tracksProvider.notifier);

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      color: isVisible ? Colors.white : Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: trackColor.withOpacity(isVisible ? 0.8 : 0.3),
          width: 1,
        ),
      ),
      child: SizedBox(
        height: 52, // 进一步减小高度
        child: Row(
          children: [
            // 轨道颜色指示器和名称
            Expanded(
              child: InkWell(
                onTap: () => tracksNotifier.toggleTrackVisibility(trackIndex),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      // 轨道颜色指示器
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: trackColor.withOpacity(isVisible ? 1.0 : 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 轨道信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              track.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800]!
                                    .withOpacity(isVisible ? 1.0 : 0.5),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${track.clips.length} 个片段',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600]!
                                    .withOpacity(isVisible ? 1.0 : 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 控制按钮
            _buildControlButton(
              icon: track.isMuted ? Icons.volume_off : Icons.volume_up,
              color: track.isMuted ? Colors.red : Colors.grey[700]!,
              onTap: () => tracksNotifier.toggleTrackMute(trackIndex),
              tooltip: track.isMuted ? '取消静音' : '静音',
            ),
          ],
        ),
      ),
    );
  }

  // 构建控制按钮
  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        icon: Icon(
          icon,
          size: 20,
          color: color.withOpacity(isVisible ? 1.0 : 0.5),
        ),
        onPressed: onTap,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}
