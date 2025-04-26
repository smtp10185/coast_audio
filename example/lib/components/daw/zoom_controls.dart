import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/daw_providers.dart';

/// 缩放控制组件 - 用于在DAW界面中控制时间轴的缩放级别
class ZoomControls extends ConsumerWidget {
  const ZoomControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoomState = ref.watch(zoomProvider);
    final zoomNotifier = ref.read(zoomProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(right: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 缩小按钮
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(3.0),
              ),
              onTap: () => zoomNotifier.zoomOut(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: const Icon(Icons.remove, size: 16),
              ),
            ),
          ),

          // 显示缩放值
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            color: Colors.grey[200],
            child: Text(
              '${zoomState.scale.toStringAsFixed(1)}x',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),

          // 放大按钮
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(3.0),
              ),
              onTap: () => zoomNotifier.zoomIn(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: const Icon(Icons.add, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
