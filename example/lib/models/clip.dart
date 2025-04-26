import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // For DeepCollectionEquality
import 'package:uuid/uuid.dart'; // Import uuid

/// 片段类型枚举
enum ClipType {
  wav, // 音频文件
  midi, // MIDI 数据
  chord // 和弦标记
}

// Helper function to safely parse ClipType from String
ClipType _parseClipType(String? typeString) {
  return ClipType.values.firstWhere(
    (e) => e.name == typeString,
    orElse: () => ClipType.wav,
  );
}

// Use final instead of const for Uuid instance
final _uuid = Uuid();

/// 音频片段模型
class Clip {
  final String id; // Unique identifier
  final String name; // 片段名称
  final double startTime; // 开始时间（秒）
  final double duration; // 持续时间（秒）
  final Color color; // 显示颜色
  final ClipType type; // 片段类型
  final String? chordValue; // 和弦值，如 "Cmaj7", "Am"等，仅在type为chord时有效

  Clip({
    required this.name,
    required this.startTime,
    required this.duration,
    required this.color,
    required this.type,
    this.chordValue,
    String? id, // Allow providing an ID, otherwise generate one
  }) : id = id ?? _uuid.v4(); // Assign ID in initializer list

  // Factory constructor to create a Clip from a JSON map
  factory Clip.fromJson(Map<String, dynamic> json) {
    return Clip(
      id: json['id'] as String? ??
          _uuid.v4(), // Deserialize ID or generate if missing
      name: json['name'] as String? ?? 'Unnamed Clip',
      startTime: (json['startTime'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toDouble() ?? 1.0,
      // Deserialize color from integer value
      color: Color(json['colorValue'] as int? ?? Colors.grey.value),
      // Deserialize enum from string
      type: _parseClipType(json['typeString'] as String?),
      chordValue: json['chordValue'] as String?,
    );
  }

  // Method to convert Clip instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id, // Serialize ID
      'name': name,
      'startTime': startTime,
      'duration': duration,
      // Serialize color as integer value
      'colorValue': color.value,
      // Serialize enum as string
      'typeString': type.name,
      if (type == ClipType.chord && chordValue != null)
        'chordValue': chordValue,
    };
  }

  // Compare primarily based on the unique ID
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Clip && other.id == id;
  }

  // Hash code based primarily on the unique ID
  @override
  int get hashCode => id.hashCode;

  // Add ID to toString for debugging
  @override
  String toString() =>
      'Clip($id, $name, type: ${type.name}, start: $startTime, dur: $duration${type == ClipType.chord ? ", chord: $chordValue" : ""})';
}
