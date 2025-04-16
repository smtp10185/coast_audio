import 'package:flutter/material.dart';

/// 片段类型枚举
enum ClipType { wav, midi }

/// 音频/MIDI片段模型
class Clip {
  final String name;
  final ClipType type;
  final Color color;
  double startTime; // 开始时间(秒)
  double duration; // 持续时间(秒)

  Clip({
    required this.name,
    required this.startTime,
    required this.duration,
    required this.color,
    required this.type,
  });

  // 添加equals方法以正确比较片段
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is Clip &&
        other.name == name &&
        other.type == type &&
        other.color == color;
  }

  // 添加hashCode方法
  @override
  int get hashCode => Object.hash(name, type, color);

  // 添加toString方法便于调试
  @override
  String toString() =>
      'Clip($name, startTime: $startTime, duration: $duration)';
}
