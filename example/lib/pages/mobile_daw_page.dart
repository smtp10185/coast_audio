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
            // 轨道可见性控制
            IconButton(
              icon: Icon(uiControl.isTrackPanelExpanded
                  ? Icons.layers
                  : Icons.layers_outlined),
              onPressed: () =>
                  ref.read(uiControlProvider.notifier).toggleTrackPanel(),
              tooltip: '轨道显示控制',
            ),
            // 播放控制按钮
            IconButton(
              icon: Icon(
                  playbackState.isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () => ref.read(playbackProvider.notifier).togglePlay(),
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () => ref.read(playbackProvider.notifier).stop(),
            ),
          ],
        ),
        body: Column(
          children: [
            // 轨道控制面板
            _buildTrackControlPanel(ref),

            // 缩放控制
            _buildZoomControls(ref),

            // 播放控制
            _buildTransportControls(ref),

            // 主要内容区域
            Expanded(
              child: _buildTimelineContent(ref),
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

  // 轨道控制面板组件
  Widget _buildTrackControlPanel(WidgetRef ref) {
    final tracksNotifier = ref.read(tracksProvider.notifier);
    final tracks = ref.watch(tracksProvider);
    final uiControl = ref.watch(uiControlProvider);
    final uiControlNotifier = ref.read(uiControlProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 控制按钮
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            children: [
              Text(
                '轨道控制',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  uiControl.isTrackPanelExpanded
                      ? Icons.expand_less
                      : Icons.expand_more,
                  color: Colors.grey[700],
                ),
                onPressed: () => uiControlNotifier.toggleTrackPanel(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: uiControl.isTrackPanelExpanded ? '收起面板' : '展开面板',
              ),
            ],
          ),
        ),

        // 轨道列表面板
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: uiControl.isTrackPanelExpanded ? tracks.length * 40.0 : 0,
          color: Colors.grey[100],
          child: ListView.builder(
            itemCount: tracks.length,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final track = tracks[index];
              // 为不同轨道分配不同颜色
              final Color trackColor = tracksNotifier.getTrackColor(index);

              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(track.name, style: const TextStyle(fontSize: 14)),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 可见性按钮
                    IconButton(
                      icon: Icon(
                        track.isVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: track.isVisible ? Colors.blue : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () =>
                          tracksNotifier.toggleTrackVisibility(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: track.isVisible ? '隐藏轨道' : '显示轨道',
                    ),
                    const SizedBox(width: 12),
                    // 静音按钮
                    IconButton(
                      icon: Icon(
                        track.isMuted ? Icons.volume_off : Icons.volume_up,
                        color: track.isMuted ? Colors.red : Colors.grey[700],
                        size: 20,
                      ),
                      onPressed: () => tracksNotifier.toggleTrackMute(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: track.isMuted ? '取消静音' : '静音',
                    ),
                  ],
                ),
                trailing: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: trackColor,
                    shape: BoxShape.circle,
                  ),
                ),
                onTap: () => tracksNotifier.toggleTrackVisibility(index),
              );
            },
          ),
        ),
      ],
    );
  }

  // 缩放控制组件
  Widget _buildZoomControls(WidgetRef ref) {
    final zoomState = ref.watch(zoomProvider);
    final zoomNotifier = ref.read(zoomProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // 缩小按钮
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () => zoomNotifier.zoomOut(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 20,
            splashRadius: 20,
            tooltip: '缩小',
          ),

          const SizedBox(width: 4),

          // 缩放滑块
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 3,
                activeTrackColor: Theme.of(ref.context).primaryColor,
                inactiveTrackColor: Colors.grey[300],
                thumbColor: Theme.of(ref.context).primaryColor,
              ),
              child: Slider(
                value: zoomState.scale,
                min: 0.5,
                max: 2.0,
                onChanged: (value) => zoomNotifier.setScale(value),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // 放大按钮
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => zoomNotifier.zoomIn(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 20,
            splashRadius: 20,
            tooltip: '放大',
          ),

          // 显示当前缩放值
          const SizedBox(width: 8),
          Text(
            '${zoomState.scale.toStringAsFixed(1)}x',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  // 播放控制组件
  Widget _buildTransportControls(WidgetRef ref) {
    final config = ref.watch(dawConfigProvider);
    final playbackState = ref.watch(playbackProvider);
    final playbackNotifier = ref.read(playbackProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 按钮控制栏
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 回到开头按钮
            IconButton(
              icon: const Icon(Icons.skip_previous),
              onPressed: () => playbackNotifier.seekTo(0.0),
              tooltip: '回到开头',
            ),

            // 播放/暂停按钮
            IconButton(
              icon: Icon(
                  playbackState.isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () => playbackNotifier.togglePlay(),
              iconSize: 32,
              tooltip: playbackState.isPlaying ? '暂停' : '播放',
            ),

            // 停止按钮
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () => playbackNotifier.stop(),
              tooltip: '停止',
            ),

            // 当前播放时间显示
            const SizedBox(width: 8),
            Text(
              _formatTime(playbackState.position),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),

            const Text(' / '),

            // 总时长显示
            Text(
              _formatTime(config.totalSeconds),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),

        // 播放进度条
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SliderTheme(
            data: SliderThemeData(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 4,
              activeTrackColor: Theme.of(ref.context).primaryColor,
              inactiveTrackColor: Colors.grey[300],
              thumbColor: Theme.of(ref.context).primaryColor,
            ),
            child: Slider(
              value: playbackState.position.clamp(0, config.totalSeconds),
              min: 0,
              max: config.totalSeconds,
              onChanged: (value) => playbackNotifier.seekTo(value),
            ),
          ),
        ),
      ],
    );
  }

  /// 格式化时间为 MM:SS 格式
  String _formatTime(double seconds) {
    final int mins = (seconds / 60).floor();
    final int secs = (seconds % 60).floor();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // 主要时间线内容
  Widget _buildTimelineContent(WidgetRef ref) {
    final config = ref.watch(dawConfigProvider);
    final timeUtils = ref.watch(timeUtilsProvider);
    final scrollController = ref.watch(scrollControllerProvider);
    final playbackState = ref.watch(playbackProvider);
    final zoomState = ref.watch(zoomProvider);
    final draggingState = ref.watch(draggingStateProvider);
    final viewportWidth = ref.watch(viewportWidthProvider);
    final tracks = ref.watch(tracksProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 安全地更新视口宽度
        ref
            .read(viewportWidthProvider.notifier)
            .updateWidth(constraints.maxWidth);

        // 计算实际使用的像素每秒
        final double scaledPixelsPerSecond =
            config.pixelsPerSecond * zoomState.scale;

        // 根据可用宽度计算每行可显示的秒数
        final double adaptiveSecondsPerRow =
            (viewportWidth / scaledPixelsPerSecond).floor().toDouble();
        // 确保至少显示最小秒数
        final double secondsPerRowScaled =
            adaptiveSecondsPerRow > config.minSecondsPerRow
                ? adaptiveSecondsPerRow
                : config.minSecondsPerRow;

        // 计算有多少行
        final int rowCount = (config.totalSeconds / secondsPerRowScaled).ceil();

        // 在每次构建时打印状态信息，以便调试
        // print(
        //     'TimelineContent: viewportWidth=$viewportWidth, secondsPerRow=$secondsPerRowScaled, rowCount=$rowCount');
        // print(
        //     'TimelineContent: 缩放比例=${zoomState.scale}, 每秒像素数=$scaledPixelsPerSecond');
        // print(
        //     'TimelineContent: 拖动状态=${draggingState.isDragging}, 片段=${draggingState.draggingClip?.name}');

        // 打印所有轨道和片段信息
        // for (int i = 0; i < tracks.length; i++) {
        //   final track = tracks[i];
        //   print('Track ${track.name} - ${track.clips.length} clips:');
        //   for (var clip in track.clips) {
        //     print(
        //         ' - Clip ${clip.name}: startTime=${clip.startTime}, duration=${clip.duration}');
        //   }
        // }

        return Stack(
          children: [
            // 时间轴和轨道内容
            SingleChildScrollView(
              controller: scrollController,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // 确保内容高度不会溢出
                  minHeight: constraints.maxHeight,
                ),
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: rowCount,
                  itemBuilder: (context, rowIndex) {
                    final double rowStartTime = rowIndex * secondsPerRowScaled;
                    final double rowEndTime =
                        (rowIndex + 1) * secondsPerRowScaled;

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

                        // 轨道内容
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
                  },
                ),
              ),
            ),

            // 播放指针
            if (playbackState.position > 0)
              _buildPlayhead(
                ref,
                viewportWidth: viewportWidth,
                secondsPerRowScaled: secondsPerRowScaled,
              ),

            // 拖动辅助线 - 跟随鼠标位置
            if (draggingState.isDragging &&
                draggingState.currentDragPosition != null)
              Positioned(
                left: draggingState.currentDragPosition!.dx -
                    MediaQuery.of(context).padding.left,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  color: Colors.yellow.withOpacity(0.7),
                ),
              ),

            // 显示拖动状态文本
            if (draggingState.isDragging && draggingState.draggingClip != null)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '拖动: ${draggingState.draggingClip!.name} - ${draggingState.draggingClip!.startTime.toStringAsFixed(2)}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // 构建时间轴标尺
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

    // 决定显示间隔 - 如果小节太密集，则按间隔显示
    int barDisplayInterval = 1;
    if (pixelsPerBar < minPixelsBetweenBars) {
      barDisplayInterval = (minPixelsBetweenBars / pixelsPerBar).ceil();
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
                              '$bar',
                              style: TextStyle(
                                fontSize: 10,
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
                  '每${barDisplayInterval}个小节显示',
                  style: TextStyle(
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

  // 构建单个轨道
  Widget _buildTrackItem(
    WidgetRef ref, {
    required Track track,
    required int trackIndex,
    required double rowStartTime,
    required double rowEndTime,
    required double viewportWidth,
  }) {
    final config = ref.watch(dawConfigProvider);

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
            ),
          ),

          // 轨道名称
          Positioned(
            left: 8,
            top: 4,
            child: Text(
              track.name,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
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

    // 打印调试信息以确认片段位置
    // print(
    //     'Rendering clip ${clip.name} at startTime: ${clip.startTime}, in row: $rowStartTime-$rowEndTime');

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

    // print(
    //     'Clip ${clip.name} rendered at left: $clipLeftInRow, width: $clipWidthInRow');

    // 判断是否为当前正在拖动的片段
    final bool isCurrentlyDragging = draggingState.isDragging &&
        draggingState.draggingClip != null &&
        draggingState.draggingClip!.name == clip.name &&
        draggingState.draggingClip!.type == clip.type &&
        draggingState.draggingClip!.color == clip.color;

    return Positioned(
      key: ValueKey('clip_${clip.name}_${clip.startTime}'), // 添加key确保刷新
      left: clipLeftInRow,
      top: 20, // 在轨道名称下方
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // 确保即使在透明区域也能捕获事件
        onPanStart: (details) {
          // print(
          //     'Dragging: PanStart at ${details.globalPosition} for clip ${clip.name}');

          // 添加轻微触觉反馈
          HapticFeedback.lightImpact();

          draggingNotifier.startDragging(
              clip, trackIndex, details.globalPosition);
        },
        onPanUpdate: (details) {
          if (isCurrentlyDragging) {
            // print('Dragging: PanUpdate at ${details.globalPosition}');
            draggingNotifier.updateDragging(details.globalPosition);
          }
        },
        onPanEnd: (details) {
          if (isCurrentlyDragging) {
            // print('Dragging: PanEnd');

            // 添加触觉反馈，表示拖动结束
            HapticFeedback.mediumImpact();

            draggingNotifier.endDragging();
          }
        },
        // 保留原有的长按处理以兼容移动设备
        onLongPressStart: (details) {
          // print(
          //     'Dragging: LongPressStart at ${details.globalPosition} for clip ${clip.name}');

          // 添加触觉反馈，表示长按开始
          HapticFeedback.mediumImpact();

          draggingNotifier.startDragging(
              clip, trackIndex, details.globalPosition);
        },
        onLongPressMoveUpdate: (details) {
          if (isCurrentlyDragging) {
            // print('Dragging: LongPressMoveUpdate at ${details.globalPosition}');
            draggingNotifier.updateDragging(details.globalPosition);
          }
        },
        onLongPressEnd: (details) {
          if (isCurrentlyDragging) {
            // print('Dragging: LongPressEnd');
            draggingNotifier.endDragging();
          }
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Container(
            width: clipWidthInRow,
            height: config.trackHeight - 25,
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

  // 构建播放指针
  Widget _buildPlayhead(
    WidgetRef ref, {
    required double viewportWidth,
    required double secondsPerRowScaled,
  }) {
    final config = ref.watch(dawConfigProvider);
    final playbackState = ref.watch(playbackProvider);

    // 计算当前播放位置所在的行
    if (secondsPerRowScaled < config.minSecondsPerRow) return const SizedBox();

    final int currentRow =
        (playbackState.position / secondsPerRowScaled).floor();
    final double positionInRow =
        playbackState.position - (currentRow * secondsPerRowScaled);

    // 计算指针在视口中的水平位置
    final double xPosition =
        (positionInRow / secondsPerRowScaled) * viewportWidth;

    return Positioned(
      left: xPosition,
      top: 0,
      child: Container(
        width: 2,
        height: MediaQuery.of(ref.context).size.height,
        color: Colors.red.withOpacity(0.8),
        child: Stack(
          children: [
            // 顶部三角形标记
            Positioned(
              top: 0,
              left: -4,
              child: SizedBox(
                width: 10,
                height: 8,
                child: CustomPaint(
                  painter: _TrianglePainter(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
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
