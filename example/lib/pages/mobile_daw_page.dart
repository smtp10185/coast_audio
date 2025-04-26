import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/daw_providers.dart';
import '../components/daw/transport_controls.dart';
import '../components/daw/track_sidebar.dart';
import '../components/daw/timeline_content.dart';
import '../components/daw/zoom_controls.dart';
import '../components/daw/global_drag_listener.dart';
import '../models/track.dart';

class MobileDawPage extends ConsumerWidget {
  const MobileDawPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听提供者
    final playbackState = ref.watch(playbackProvider);
    final uiControl = ref.watch(uiControlProvider);

    // 使用 LayoutBuilder 获取实际宽度并更新 Provider
    return LayoutBuilder(builder: (context, constraints) {
      // 获取实际可用宽度
      final actualWidth = constraints.maxWidth;

      // 安全地更新视口宽度 - 在布局构建过程中更新
      // 使用 Future.microtask 避免在 build 期间直接修改状态
      Future.microtask(() {
        // 只有在宽度有效且与当前状态不同时才更新
        if (actualWidth > 0 && actualWidth != ref.read(viewportWidthProvider)) {
          ref.read(viewportWidthProvider.notifier).updateWidth(actualWidth);
        }
      });

      // Directly return the main content structure
      return GlobalDragListener(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('DAW'),
            // toolbarHeight: 48.0, // Keep or remove custom height as needed
            actions: [
              // 和弦编辑按钮
              IconButton(
                icon: const Icon(Icons.piano),
                onPressed: () => _showChordOptions(context, ref),
                tooltip: '和弦编辑',
                iconSize: 24,
              ),

              // 缩放控制
              const ZoomControls(),

              // 轨道面板切换按钮
              IconButton(
                icon: const Icon(Icons.layers),
                onPressed: () => _showTrackPanel(context, ref),
                tooltip: '轨道管理',
                iconSize: 24,
              ),
            ],
          ),
          body: Column(
            children: [
              // 主要内容区域 - 占据所有可用空间
              const Expanded(
                child: TimelineContent(),
              ),

              // 播放控制栏 - 移至底部
              const TransportControls(),
            ],
          ),
        ),
      );
    });
  }

  // 显示和弦操作菜单
  void _showChordOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add, color: Colors.purple),
                title: const Text('添加和弦标记'),
                onTap: () {
                  Navigator.pop(context);
                  _addChordMark(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.purple),
                title: const Text('编辑和弦进行'),
                onTap: () {
                  Navigator.pop(context);
                  _editChordProgression(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.purple),
                title: const Text('显示/隐藏和弦轨道'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleChordTrackVisibility(ref);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 添加和弦标记的方法
  void _addChordMark(BuildContext context, WidgetRef ref) {
    // 获取当前播放位置作为和弦标记的起始点
    final playbackState = ref.read(playbackProvider);
    final startTime = playbackState.position;

    // 这里可以显示和弦选择对话框
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加和弦标记'),
          content: const Text('在这里会显示和弦选择器，目前仅作示例'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已添加和弦标记 (示例)')),
                );
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }

  // 编辑和弦进行的方法
  void _editChordProgression(BuildContext context, WidgetRef ref) {
    // 这里可以导航到和弦编辑页面
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('和弦进行编辑器'),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('这里将显示和弦进行编辑器界面'),
                const SizedBox(height: 20),
                const Icon(
                  Icons.piano,
                  size: 80,
                  color: Colors.purple,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  // 切换和弦轨道可见性的方法
  void _toggleChordTrackVisibility(WidgetRef ref) {
    final tracks = ref.read(tracksProvider);
    // 查找和弦轨道索引
    int? chordTrackIndex;
    for (int i = 0; i < tracks.length; i++) {
      if (tracks[i].type == TrackType.chord) {
        chordTrackIndex = i;
        break;
      }
    }

    if (chordTrackIndex != null) {
      // 切换和弦轨道的可见性
      ref.read(tracksProvider.notifier).toggleTrackVisibility(chordTrackIndex);

      // 显示通知
      final track = tracks[chordTrackIndex];
      final newState = !track.isVisible;

      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: Text('${newState ? '显示' : '隐藏'}和弦轨道'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // 显示轨道管理面板
  void _showTrackPanel(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 允许更灵活的高度
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5, // 初始高度为屏幕的50%
          minChildSize: 0.25, // 最小高度为屏幕的25%
          maxChildSize: 0.85, // 最大高度为屏幕的85%
          builder: (context, scrollController) {
            return Column(
              children: [
                // 顶部拖动条
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 轨道管理内容
                Expanded(
                  child: TrackSidebar(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 开始播放 - 已移到TransportControls
  void _togglePlay(WidgetRef ref) {
    final playbackNotifier = ref.read(playbackProvider.notifier);
    playbackNotifier.togglePlay();
  }
}
