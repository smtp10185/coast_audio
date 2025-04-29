import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/daw_providers.dart';
import '../components/daw/transport_controls.dart';
import '../components/daw/track_sidebar.dart';
import '../components/daw/timeline_content.dart';
import '../components/daw/zoom_controls.dart';
import '../components/daw/global_drag_listener.dart';
import '../models/track.dart';
import '../models/clip.dart';
import '../components/daw/chord_arrange_view.dart';

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
          body: const TimelineContent(),
          floatingActionButton: Consumer(builder: (context, ref, child) {
            final playbackState = ref.watch(playbackProvider);
            return FloatingActionButton(
              tooltip: playbackState.isPlaying ? '暂停' : '播放',
              onPressed: () => _togglePlay(ref),
              child: Icon(
                playbackState.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
            );
          }),
          bottomNavigationBar: const TransportControls(),
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
    final chordNameController = TextEditingController();

    // 显示和弦输入对话框
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加和弦标记'),
          content: TextField(
            controller: chordNameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: '输入和弦名称 (例如 Cmaj7)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final chordName = chordNameController.text.trim();
                if (chordName.isNotEmpty) {
                  // 查找和弦轨道 (假设在索引 0)
                  // TODO: 更健壮的方式是查找 type == TrackType.chord 的轨道
                  const chordTrackIndex = 0;

                  // 创建新的 Chord Clip
                  final newChordClip = Clip(
                    name: chordName, // Use chord name as clip name too
                    startTime: startTime,
                    duration: 0.1, // Short duration for marker style
                    color: Colors.purple,
                    type: ClipType.chord,
                    chordValue: chordName,
                  );

                  // 添加 Clip 到 Provider
                  try {
                    ref
                        .read(tracksProvider.notifier)
                        .addClipToTrack(chordTrackIndex, newChordClip);

                    Navigator.pop(context); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              '已在 ${startTime.toStringAsFixed(2)}s 添加和弦: $chordName')),
                    );
                  } catch (e) {
                    Navigator.pop(context); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('添加和弦失败: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入有效的和弦名称')),
                  );
                }
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
    // --- Debug Print: Check tracks state BEFORE opening the sheet ---
    final currentTracks = ref.read(tracksProvider);
    final hasChordTrackBeforeOpening =
        currentTracks.any((t) => t.type == TrackType.chord);
    print("[_editChordProgression] Checking tracks before opening sheet...");
    print(
        "[_editChordProgression] Has Chord Track? $hasChordTrackBeforeOpening");
    print(
        "[_editChordProgression] Current Tracks: ${currentTracks.map((t) => '${t.name}(${t.type.name})').join(', ')}");
    // --- End Debug Print ---

    // Show the ChordArrangeView in a Modal Bottom Sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take up more height
      backgroundColor: Colors.transparent, // Make sheet background transparent
      // elevation: 0, // Optional: remove shadow if needed
      builder: (context) {
        // Wrap ChordArrangeView in a container for background and shape
        return Container(
          margin: const EdgeInsets.only(top: 40), // Add margin from top
          decoration: BoxDecoration(
            color: Colors.grey[100], // Example background color
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ], // Add shadow for better separation
          ),
          // Constrain the height - adjust as needed
          height: MediaQuery.of(context).size.height * 0.8,
          child: const ChordArrangeView(), // Your main content
        );
      },
    );

    /* // Original Dialog code
    showDialog(
      context: context,
      // Make the dialog wider to accommodate the arrange view
      builder: (context) => const AlertDialog(
          // Using AlertDialog for structure, but content is ChordArrangeView
          contentPadding: EdgeInsets.zero, // Remove default padding
          insetPadding:
              EdgeInsets.symmetric(horizontal: 10, vertical: 24),
          // Allow the dialog to determine its own size based on content
          content: ChordArrangeView(),
          // Optional: Add title or actions if needed
          // title: Text('编辑和弦进行'),
          // actions: [
          //   TextButton(
          //     onPressed: () => Navigator.pop(context),
          //     child: const Text('关闭'),
          //   ),
          // ],
          ),
    );
    */
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

  // 开始播放 - Now called by FAB
  void _togglePlay(WidgetRef ref) {
    final playbackNotifier = ref.read(playbackProvider.notifier);
    playbackNotifier.togglePlay();
  }
}
