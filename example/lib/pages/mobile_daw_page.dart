import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 导入用于触觉反馈
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/clip.dart';
import '../models/track.dart';
import '../providers/daw_providers.dart';
import '../utils/time_utils.dart';
import 'dart:math' as Math;

class MobileDawPage extends ConsumerWidget {
  const MobileDawPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听提供者
    final config = ref.watch(dawConfigProvider);
    final tracks = ref.watch(tracksProvider);
    final playbackState = ref.watch(playbackProvider);
    final zoomState = ref.watch(zoomProvider);
    final zoomNotifier = ref.read(zoomProvider.notifier);
    final uiControl = ref.watch(uiControlProvider);
    final draggingState = ref.watch(draggingStateProvider);
    final scrollController = ref.watch(scrollControllerProvider);

    // 安全地更新视口宽度
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(viewportWidthProvider.notifier)
          .updateWidth(MediaQuery.of(context).size.width);
    });

    // 使用全局拖动监听器包装整个页面
    return _buildDragListener(
      ref,
      Scaffold(
        appBar: AppBar(
          title: const Text('移动 DAW'),
          actions: [
            // 缩放控制 - 直接放在顶部操作栏
            Container(
              margin: const EdgeInsets.only(right: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 缩小按钮
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(3.0),
                      ),
                    ),
                    child: InkWell(
                      onTap: () => zoomNotifier.zoomOut(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.0, vertical: 2.0),
                        child: Icon(Icons.remove, size: 14),
                      ),
                    ),
                  ),
                  // 显示缩放值
                  Container(
                    color: Colors.grey[100],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4.0, vertical: 2.0),
                    child: Text(
                      '${zoomState.scale.toStringAsFixed(1)}x',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  // 放大按钮
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(3.0),
                      ),
                    ),
                    child: InkWell(
                      onTap: () => zoomNotifier.zoomIn(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.0, vertical: 2.0),
                        child: Icon(Icons.add, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

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
            // 添加侧边栏折叠/展开按钮
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
            _buildTransportControls(ref),

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
                        ? _buildTrackSidebar(ref)
                        : const SizedBox(),
                  ),

                  // 右侧时间线和轨道内容
                  Expanded(
                    child: _buildTimelineContent(ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建全局拖动监听器
  Widget _buildDragListener(WidgetRef ref, Widget child) {
    final draggingNotifier = ref.read(draggingStateProvider.notifier);
    final draggingState = ref.watch(draggingStateProvider);

    return Listener(
      behavior: HitTestBehavior.translucent, // 确保能捕获所有事件
      onPointerMove: (event) {
        if (draggingState.isDragging) {
          // print('Dragging: PointerMove detected at ${event.position}');
          draggingNotifier.updateDragging(event.position);
        }
      },
      onPointerUp: (event) {
        if (draggingState.isDragging) {
          // print('Dragging: PointerUp detected');
          draggingNotifier.endDragging();
        }
      },
      onPointerCancel: (event) {
        if (draggingState.isDragging) {
          // print('Dragging: PointerCancel detected');
          draggingNotifier.endDragging();
        }
      },
      child: child,
    );
  }

  // 播放控制组件
  Widget _buildTransportControls(WidgetRef ref) {
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
              color: Theme.of(ref.context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                  playbackState.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Theme.of(ref.context).primaryColor),
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

  // 新增：构建轨道侧边栏 - 优化版本
  Widget _buildTrackSidebar(WidgetRef ref) {
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

                return Container(
                  height: config.trackHeight,
                  decoration: BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: Colors.grey[300]!)),
                    color: trackIndex % 2 == 0 ? Colors.grey[50] : Colors.white,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          tracksNotifier.toggleTrackVisibility(trackIndex),
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
                                color: trackColor
                                    .withOpacity(isVisible ? 1.0 : 0.4),
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
                                  color: Colors.grey[800]!
                                      .withOpacity(isVisible ? 1.0 : 0.5),
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
                                  track.isVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: track.isVisible
                                      ? Colors.blue.withOpacity(0.8)
                                      : Colors.grey[400],
                                ),
                                onPressed: () => tracksNotifier
                                    .toggleTrackVisibility(trackIndex),
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
                                  track.isMuted
                                      ? Icons.volume_off
                                      : Icons.volume_up,
                                  color: track.isMuted
                                      ? Colors.red
                                          .withOpacity(isVisible ? 1.0 : 0.5)
                                      : Colors.grey[700]!
                                          .withOpacity(isVisible ? 1.0 : 0.5),
                                ),
                                onPressed: () =>
                                    tracksNotifier.toggleTrackMute(trackIndex),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 构建轨道内容
  Widget _buildTracks(
    WidgetRef ref, {
    required double rowStartTime,
    required double rowEndTime,
    required double viewportWidth,
  }) {
    final tracks = ref.watch(tracksProvider);
    final draggingState = ref.watch(draggingStateProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(tracks.length, (trackIndex) {
        final track = tracks[trackIndex];

        // 如果轨道设置为不可见，则不显示
        if (!track.isVisible) {
          return const SizedBox();
        }

        // 如果正在拖动且不是活跃轨道，则不显示
        if (draggingState.isDragging &&
            draggingState.activeTrackIndex != null &&
            trackIndex != draggingState.activeTrackIndex) {
          return const SizedBox(height: 0); // 返回高度为0的轨道占位
        }

        return _buildTrackItem(
          ref,
          track: track,
          trackIndex: trackIndex,
          rowStartTime: rowStartTime,
          rowEndTime: rowEndTime,
          viewportWidth: viewportWidth,
        );
      }),
    );
  }

  // 构建单个轨道项
  Widget _buildTrackItem(
    WidgetRef ref, {
    required Track track,
    required int trackIndex,
    required double rowStartTime,
    required double rowEndTime,
    required double viewportWidth,
  }) {
    final config = ref.watch(dawConfigProvider);
    final tracksNotifier = ref.read(tracksProvider.notifier);
    final Color trackColor = tracksNotifier.getTrackColor(trackIndex);

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
                color: trackIndex % 2 == 0 ? Colors.grey[50] : Colors.white,
              ),
              // 左侧边框颜色指示器
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
              .map((clip) => _buildClip(
                    ref,
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

  // 构建单个片段
  Widget _buildClip(
    WidgetRef ref, {
    required Clip clip,
    required int trackIndex,
    required double rowStartTime,
    required double rowEndTime,
    required double viewportWidth,
  }) {
    final config = ref.watch(dawConfigProvider);
    final draggingState = ref.watch(draggingStateProvider);
    final draggingNotifier = ref.read(draggingStateProvider.notifier);
    final zoomState = ref.watch(zoomProvider);

    // 计算缩放后的每秒像素数
    final double scaledPixelsPerSecond =
        config.pixelsPerSecond * zoomState.scale;

    // 计算每行可显示的秒数（自适应）
    final double adaptiveSecondsPerRow =
        (viewportWidth / scaledPixelsPerSecond).floor().toDouble();
    final double secondsPerRowScaled =
        adaptiveSecondsPerRow > config.minSecondsPerRow
            ? adaptiveSecondsPerRow
            : config.minSecondsPerRow;

    // 检查片段是否在当前行的范围内
    final clipStartTime = clip.startTime;
    final clipEndTime = clip.startTime + clip.duration;

    // 如果片段完全在当前行之外，就不显示
    if (clipEndTime <= rowStartTime || clipStartTime >= rowEndTime) {
      return const SizedBox();
    }

    // 计算片段在当前行中的开始和结束时间
    final double startInRow =
        (clipStartTime > rowStartTime) ? clipStartTime - rowStartTime : 0;
    final double endInRow = (clipEndTime < rowEndTime)
        ? clipEndTime - rowStartTime
        : rowEndTime - rowStartTime;

    // 计算片段在当前行中的宽度（根据视口宽度自适应）
    final double clipWidthInRow =
        (endInRow - startInRow) / (rowEndTime - rowStartTime) * viewportWidth;

    // 计算片段在当前行中的位置（根据视口宽度自适应）
    final double clipLeftInRow =
        startInRow / (rowEndTime - rowStartTime) * viewportWidth;

    // 判断是否为当前正在拖动的片段
    final bool isCurrentlyDragging = draggingState.isDragging &&
        draggingState.draggingClip != null &&
        draggingState.draggingClip!.name == clip.name &&
        draggingState.draggingClip!.type == clip.type &&
        draggingState.draggingClip!.color == clip.color;

    return Positioned(
      key: ValueKey('clip_${clip.name}_${clip.startTime}'), // 添加key确保刷新
      left: clipLeftInRow,
      top: 4, // 调整位置，不再需要为轨道名称留空间
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
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Container(
            width: clipWidthInRow,
            height: config.trackHeight - 10, // 调整高度，更贴近轨道高度
            decoration: BoxDecoration(
              color: clip.color.withOpacity(0.7),
              border: Border.all(
                color: isCurrentlyDragging ? Colors.yellow : clip.color,
                width: isCurrentlyDragging ? 2 : 1,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(clipStartTime >= rowStartTime ? 4 : 0),
                bottomLeft:
                    Radius.circular(clipStartTime >= rowStartTime ? 4 : 0),
                topRight: Radius.circular(clipEndTime <= rowEndTime ? 4 : 0),
                bottomRight: Radius.circular(clipEndTime <= rowEndTime ? 4 : 0),
              ),
              // 拖动时添加阴影效果
              boxShadow: isCurrentlyDragging
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(2, 2),
                      )
                    ]
                  : null,
            ),
            // 简化内容显示
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
              child: Center(
                child: clipWidthInRow > 40
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
            ),
          ),
        ),
      ),
    );
  }

  // 修改时间线内容构建方法
  Widget _buildTimelineContent(WidgetRef ref) {
    final config = ref.watch(dawConfigProvider);
    final tracks = ref.watch(tracksProvider);
    final playbackState = ref.watch(playbackProvider);
    final zoomState = ref.watch(zoomProvider);
    final viewportWidth = ref.watch(viewportWidthProvider);
    final draggingState = ref.watch(draggingStateProvider);
    final scrollController = ref.watch(scrollControllerProvider);

    // 安全检查
    if (viewportWidth <= 0) {
      return const Center(child: CircularProgressIndicator());
    }

    // 计算缩放后的每秒像素数
    final double scaledPixelsPerSecond =
        config.pixelsPerSecond * zoomState.scale;

    // 计算每行可显示的秒数（自适应）
    final double adaptiveSecondsPerRow =
        (viewportWidth / scaledPixelsPerSecond).floor().toDouble();
    final double secondsPerRowScaled =
        adaptiveSecondsPerRow > config.minSecondsPerRow
            ? adaptiveSecondsPerRow
            : config.minSecondsPerRow;

    // 调试输出
    debugPrint(
        '视口宽度: $viewportWidth, 每行秒数: $secondsPerRowScaled, 缩放比例: ${zoomState.scale}, 每秒像素: $scaledPixelsPerSecond');
    if (draggingState.isDragging) {
      debugPrint(
          '拖动状态: ${draggingState.isDragging}, 活跃轨道: ${draggingState.activeTrackIndex}');
    }

    // 遍历所有轨道，输出轨道和片段信息用于调试
    for (int i = 0; i < tracks.length; i++) {
      final track = tracks[i];
      debugPrint(
          '轨道 $i: ${track.name}, 可见: ${track.isVisible}, 片段数: ${track.clips.length}');
      for (final clip in track.clips) {
        debugPrint(
            '  片段: ${clip.name}, 开始时间: ${clip.startTime}, 持续时间: ${clip.duration}');
      }
    }

    // 计算总所需行数
    final int totalDuration = tracks.fold(
        0,
        (max, track) => Math.max(
            max.toInt(),
            track.clips.fold(
                0,
                (maxTime, clip) => Math.max(maxTime.toInt(),
                    (clip.startTime + clip.duration).toInt()))));

    final int rowCount =
        (totalDuration / secondsPerRowScaled).ceil() + 1; // 额外添加一行作为缓冲

    // 计算行的高度
    double rowHeight = _calculateVisibleRowHeight(
      config,
      tracks.where((track) => track.isVisible).length,
      draggingState.isDragging,
      draggingState.activeTrackIndex,
    );

    // 生成正在拖动的片段位置指示器
    Widget _buildDraggingPositionIndicator() {
      if (!draggingState.isDragging || draggingState.draggingClip == null) {
        return const SizedBox();
      }

      return Positioned(
        top: 4,
        left: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${draggingState.draggingClip!.name}: ${draggingState.draggingClip!.startTime.toStringAsFixed(2)}s',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      );
    }

    // 构建时间线滚动视图内容
    return Stack(
      children: [
        // 滚动视图
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            final playbackNotifier = ref.read(playbackProvider.notifier);

            // 检测用户手动滚动
            if (notification is ScrollUpdateNotification) {
              // 如果是用户拖动（而非程序触发的动画滚动）
              if (notification.dragDetails != null) {
                // 检测到用户手动滚动，禁用自动滚动
                if (!playbackState.disableAutoScroll) {
                  // 将自动滚动状态设置为禁用
                  playbackNotifier.setAutoScroll(false);
                  // 显示提示
                  ScaffoldMessenger.of(ref.context).showSnackBar(
                    const SnackBar(
                      content: Text('已禁用自动滚动，播放指针不会再自动滚动'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            }
            return false;
          },
          child: SingleChildScrollView(
            controller: scrollController,
            child: SizedBox(
              height: rowHeight * rowCount,
              child: Stack(
                children: [
                  // 生成所有行
                  Column(
                    children: List.generate(rowCount, (rowIndex) {
                      // 计算当前行的时间范围
                      final double rowStartTime =
                          rowIndex * secondsPerRowScaled;
                      final double rowEndTime =
                          rowStartTime + secondsPerRowScaled;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 时间轴标尺
                          Stack(
                            children: [
                              _buildTimelineRuler(
                                ref,
                                rowStartTime: rowStartTime,
                                rowEndTime: rowEndTime,
                                rowIndex: rowIndex,
                                rowCount: rowCount,
                                viewportWidth: viewportWidth,
                              ),

                              // 为当前行添加一个高亮指示器，方便调试
                              // 如果是当前拖动片段所在的行，显示高亮背景
                              if (draggingState.isDragging &&
                                  draggingState.draggingClip != null &&
                                  rowIndex ==
                                      (draggingState.draggingClip!.startTime /
                                              secondsPerRowScaled)
                                          .floor())
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.yellow.withOpacity(0.1),
                                  ),
                                ),
                            ],
                          ),

                          // 轨道内容 - 移除左侧的轨道名称，只显示内容部分
                          _buildTracks(
                            ref,
                            rowStartTime: rowStartTime,
                            rowEndTime: rowEndTime,
                            viewportWidth: viewportWidth,
                          ),

                          // 行间距
                          SizedBox(height: config.rowSpacing),
                        ],
                      );
                    }),
                  ),

                  // 播放指针
                  _buildPlayhead(
                    ref,
                    viewportWidth: viewportWidth,
                    secondsPerRowScaled: secondsPerRowScaled,
                  ),
                ],
              ),
            ),
          ),
        ),

        // 拖动状态指示器
        _buildDraggingPositionIndicator(),
      ],
    );
  }

  // 计算可见行高
  double _calculateVisibleRowHeight(DawConfig config, int visibleTrackCount,
      bool isDragging, int? activeTrackIndex) {
    if (isDragging && activeTrackIndex != null) {
      // 拖动状态下，行高只计算时间轴+活跃轨道+间距
      return config.timelineHeight + config.trackHeight + config.rowSpacing;
    } else {
      // 正常状态下，行高为时间轴+可见轨道+间距
      return config.timelineHeight +
          (visibleTrackCount * config.trackHeight) +
          config.rowSpacing;
    }
  }

  // 构建时间轴标尺 - 改进版本支持更多小节
  Widget _buildTimelineRuler(
    WidgetRef ref, {
    required double rowStartTime,
    required double rowEndTime,
    required int rowIndex,
    required int rowCount,
    required double viewportWidth,
  }) {
    final config = ref.watch(dawConfigProvider);
    final timeUtils = ref.watch(timeUtilsProvider);

    // 计算这一行显示多少秒
    final double rowDuration = rowEndTime - rowStartTime;

    // 获取小节信息
    final startBarInfo = timeUtils.secondsToBarInfo(rowStartTime);
    final endBarInfo = timeUtils.secondsToBarInfo(rowEndTime - 0.01); // 避免边界问题

    // 计算这一行包含的小节数
    final int startBar = startBarInfo['bar'];
    final int endBar = endBarInfo['bar'];
    final int barCount = endBar - startBar + 1;

    // 根据视口宽度计算一个合理的分隔数
    // 每个小节位置都要显示，但需要保证最小像素间距以避免数字重叠
    final double minPixelsBetweenBars = 60.0; // 小节号之间的最小间距

    // 计算每小节平均像素宽度
    final double secondsPerBeat = 60.0 / timeUtils.bpm;
    final double secondsPerBar = secondsPerBeat * timeUtils.beatsPerBar;
    final double pixelsPerBar = (secondsPerBar / rowDuration) * viewportWidth;

    // 动态调整显示间隔 - 根据小节范围调整显示策略
    int barDisplayInterval = 1;

    // 如果小节密度太高，动态调整间隔
    if (pixelsPerBar < minPixelsBetweenBars) {
      barDisplayInterval = (minPixelsBetweenBars / pixelsPerBar).ceil();

      // 为大数字优化显示间隔
      if (startBar > 100) {
        // 超过100小节时，按10的倍数显示
        barDisplayInterval = Math.max(barDisplayInterval, 10);
      } else if (startBar > 32) {
        // 超过32小节时，至少按4的倍数显示
        barDisplayInterval = Math.max(barDisplayInterval, 4);
      } else if (startBar > 16) {
        // 超过16小节时，至少按2的倍数显示
        barDisplayInterval = Math.max(barDisplayInterval, 2);
      }
    }

    // 分隔线数量 - 保证足够的分辨率
    int divisionCount = Math.max((rowDuration / secondsPerBeat).round(), 8);

    return SizedBox(
      height: config.timelineHeight,
      width: viewportWidth,
      child: Stack(
        children: [
          // 底部边框
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 1,
              color: Colors.grey[300],
            ),
          ),

          // 生成时间标记和小节线
          ...List.generate(
            divisionCount + 1,
            (i) {
              final double time =
                  rowStartTime + (i * rowDuration / divisionCount);
              if (time > rowEndTime) return const SizedBox();

              // 获取小节信息
              final barInfo = timeUtils.secondsToBarInfo(time);
              final int bar = barInfo['bar'];
              final int beat = barInfo['beat'];

              // 判断是主要标记还是次要标记
              final bool isMainMark = beat == 1; // 每小节的第一拍是主要标记
              final bool isSecondMark = beat > 1; // 其他拍是次要标记

              final double markHeight = isMainMark
                  ? config.timelineHeight - 6
                  : isSecondMark
                      ? config.timelineHeight - 10
                      : (config.timelineHeight - 12) / 2;

              // 计算标记在视图中的位置
              final double markPosition = (i / divisionCount) * viewportWidth;

              // 小节号显示逻辑：
              // 1. 必须是小节的第一拍
              // 2. 必须符合显示间隔规则
              bool shouldDisplayNumber =
                  isMainMark && (bar % barDisplayInterval == 0);

              // 使用TimeUtils的方法格式化小节显示
              String barText = timeUtils.formatBarDisplay(bar);

              return Positioned(
                left: markPosition,
                top: 0,
                child: SizedBox(
                  width: viewportWidth / divisionCount,
                  height: config.timelineHeight,
                  child: Stack(
                    children: [
                      // 垂直线条
                      Positioned(
                        left: 0,
                        bottom: 0,
                        child: Container(
                          width: 1,
                          height: markHeight,
                          color: isMainMark
                              ? Colors.grey[700]
                              : isSecondMark
                                  ? Colors.grey[500]
                                  : Colors.grey[300],
                        ),
                      ),

                      // 时间标签（只显示符合条件的小节号）
                      if (shouldDisplayNumber)
                        Positioned(
                          left: 4, // 数字距离线的间距
                          top: 2,
                          child: Container(
                            // 添加背景使数字更清晰
                            padding: const EdgeInsets.symmetric(
                                horizontal: 2, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              barText,
                              style: TextStyle(
                                fontSize: bar > 100 ? 8 : 10, // 大数字使用更小的字体
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 添加额外调试信息 - 显示当前行的时间范围和小节信息
          if (rowIndex == 0)
            Positioned(
              top: 0,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  '${startBar}-${endBar}小节 (间隔:${barDisplayInterval})',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 构建播放指针
  Widget _buildPlayhead(
    WidgetRef ref, {
    required double viewportWidth,
    required double secondsPerRowScaled,
  }) {
    final config = ref.watch(dawConfigProvider);
    final playbackState = ref.watch(playbackProvider);
    final tracks = ref.watch(tracksProvider);
    final draggingState = ref.watch(draggingStateProvider);

    // 如果每行显示的时间太短，不显示播放指针
    if (secondsPerRowScaled < config.minSecondsPerRow) return const SizedBox();

    // 计算当前播放位置所在的行
    final int currentRow =
        (playbackState.position / secondsPerRowScaled).floor();

    // 计算当前行内的位置（秒）
    final double positionInRow =
        playbackState.position - (currentRow * secondsPerRowScaled);

    // 计算每秒对应的像素数
    final double pixelsPerSecond = viewportWidth / secondsPerRowScaled;

    // 计算精确的位置
    final double exactXPosition = positionInRow * pixelsPerSecond;

    // 使用整数对齐避免抗锯齿导致的模糊
    final int pixelX = exactXPosition.round();

    // 计算可见轨道数
    final int visibleTrackCount =
        tracks.where((track) => track.isVisible).length;

    // 计算行的完整高度（包含间距）
    double rowHeight = _calculateVisibleRowHeight(
      config,
      visibleTrackCount,
      draggingState.isDragging,
      draggingState.activeTrackIndex,
    );

    // 计算不包含间距的实际内容高度
    double contentHeight;
    if (draggingState.isDragging && draggingState.activeTrackIndex != null) {
      // 拖动状态下只有一个轨道
      contentHeight = config.timelineHeight + config.trackHeight;
    } else {
      // 正常状态下是所有可见轨道
      contentHeight =
          config.timelineHeight + (visibleTrackCount * config.trackHeight);
    }

    // 计算当前行的垂直位置
    final double yPosition = currentRow * rowHeight;

    return Positioned(
      left: pixelX.toDouble(),
      top: yPosition,
      child: Column(
        children: [
          // 顶部圆点标记
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          // 垂直线 - 精确计算高度，不延伸到间距
          Container(
            width: 1,
            height: contentHeight - 5, // 减去圆点高度，且不包含行间距
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  /// 根据行持续时间计算应该显示多少个分隔
  int _calculateDivisionCount(TimeUtils timeUtils, double rowDuration) {
    // 计算这一行大约包含多少个小节
    final double secondsPerBeat = 60.0 / timeUtils.bpm;
    final double secondsPerBar = secondsPerBeat * timeUtils.beatsPerBar;
    final double barsInRow = rowDuration / secondsPerBar;

    // 计算每小节应该显示的分隔数量（根据持续时间和可用宽度）
    final int divisionsPerBar = _calculateDivisionsPerBar(barsInRow);

    // 返回总分隔数，确保足够的分辨率
    return Math.max((barsInRow * divisionsPerBar).round(), 8);
  }

  /// 计算每小节应该显示多少个分隔
  /// 根据小节数动态调整
  int _calculateDivisionsPerBar(double barsInRow) {
    if (barsInRow <= 1) return 4; // 当一行只有一个小节或更少时，显示4个分隔（每拍一个）
    if (barsInRow <= 2) return 4; // 当一行有2个小节时，显示4个分隔（每拍一个）
    if (barsInRow <= 4) return 2; // 当一行有3-4个小节时，显示2个分隔（每2拍一个）
    if (barsInRow <= 8) return 1; // 当一行有5-8个小节时，只在小节开始处显示分隔
    return 1; // 其他情况也只在小节开始处显示
  }

  // 开始播放
  void _togglePlay(WidgetRef ref) {
    final playbackNotifier = ref.read(playbackProvider.notifier);
    if (playbackNotifier.state.isPlaying) {
      playbackNotifier.togglePlay();
    } else {
      playbackNotifier.togglePlay();
    }
  }
}

/// 三角形绘制器
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
