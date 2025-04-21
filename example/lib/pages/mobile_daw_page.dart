import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/daw_providers.dart';
import '../components/daw/transport_controls.dart';
import '../components/daw/track_sidebar.dart';
import '../components/daw/timeline_content.dart';
import '../components/daw/zoom_controls.dart';
import '../components/daw/global_drag_listener.dart';

class MobileDawPage extends ConsumerWidget {
  const MobileDawPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听提供者
    final playbackState = ref.watch(playbackProvider);
    final uiControl = ref.watch(uiControlProvider);

    // 安全地更新视口宽度
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(viewportWidthProvider.notifier)
          .updateWidth(MediaQuery.of(context).size.width);
    });

    return GlobalDragListener(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('移动 DAW'),
          actions: [
            // 缩放控制
            const ZoomControls(),

            // 播放控制按钮
            IconButton(
              icon: Icon(
                  playbackState.isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () => _togglePlay(ref),
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () => ref.read(playbackProvider.notifier).stop(),
            ),

            // 侧边栏折叠/展开按钮
            IconButton(
              icon: Icon(
                uiControl.isTrackPanelExpanded
                    ? Icons.chevron_left
                    : Icons.chevron_right,
              ),
              onPressed: () =>
                  ref.read(uiControlProvider.notifier).toggleTrackPanel(),
              tooltip: uiControl.isTrackPanelExpanded ? '收起轨道面板' : '展开轨道面板',
            ),
          ],
        ),
        body: Column(
          children: [
            // 播放控制
            const TransportControls(),

            // 主要内容区域 - 使用Row布局分为侧边栏和时间线内容
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧轨道信息边栏 - 根据展开状态控制显示
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: uiControl.isTrackPanelExpanded ? 100.0 : 0, // 折叠/展开
                    child: uiControl.isTrackPanelExpanded
                        ? const TrackSidebar()
                        : const SizedBox(),
                  ),

                  // 右侧时间线和轨道内容
                  const Expanded(
                    child: TimelineContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 开始播放
  void _togglePlay(WidgetRef ref) {
    final playbackNotifier = ref.read(playbackProvider.notifier);
    playbackNotifier.togglePlay();
  }
}
