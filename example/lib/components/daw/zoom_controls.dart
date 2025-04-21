import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/daw_providers.dart';

/// 缩放控制组件 - 用于在DAW界面中控制时间轴的缩放级别
class ZoomControls extends ConsumerWidget {
  const ZoomControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoomState = ref.watch(zoomProvider);
    final zoomNotifier = ref.read(zoomProvider.notifier);

    return Container(
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
                padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                child: Icon(Icons.remove, size: 14),
              ),
            ),
          ),
          // 显示缩放值
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
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
                padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                child: Icon(Icons.add, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
