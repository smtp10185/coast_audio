import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/daw_providers.dart';

/// 全局拖动监听器 - 捕获和处理整个DAW页面的拖动事件
class GlobalDragListener extends ConsumerWidget {
  final Widget child;

  const GlobalDragListener({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
}
