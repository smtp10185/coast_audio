import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/daw_providers.dart';
import '../../utils/time_utils.dart';
import 'dart:math' as Math;

/// 时间轴标尺 - 显示时间轴和小节标记
class TimelineRuler extends ConsumerWidget {
  final double rowStartTime;
  final double rowEndTime;
  final int rowIndex;
  final int rowCount;
  final double viewportWidth;

  const TimelineRuler({
    super.key,
    required this.rowStartTime,
    required this.rowEndTime,
    required this.rowIndex,
    required this.rowCount,
    required this.viewportWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    // Remove GestureDetector, interaction handled by parent
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
