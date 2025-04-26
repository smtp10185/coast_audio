import 'clip.dart';
import 'package:flutter/material.dart'; // Need Color for default value

/// 轨道类型枚举
enum TrackType {
  normal, // 普通音频轨道
  chord // 和弦轨道
}

// Helper function to safely parse TrackType from String
TrackType _parseTrackType(String typeString) {
  return TrackType.values.firstWhere(
    (e) => e.name == typeString,
    orElse: () => TrackType.normal, // Default or fallback type
  );
}

/// 音频轨道模型
class Track {
  final String name;
  final List<Clip> clips;
  final TrackType type; // 轨道类型
  bool isVisible; // 控制轨道是否显示
  bool isMuted; // 是否静音
  bool isSolo; // 是否独奏
  double volume; // 音量 (0.0 - 1.0)
  double pan; // 声像 (-1.0左 ~ 1.0右)

  Track({
    required this.name,
    required this.clips,
    this.type = TrackType.normal,
    this.isVisible = true,
    this.isMuted = false,
    this.isSolo = false,
    this.volume = 1.0,
    this.pan = 0.0,
  });

  // Factory constructor to create a Track from a JSON map
  factory Track.fromJson(Map<String, dynamic> json) {
    // Parse the list of clips
    var clipListFromJson = json['clips'] as List<dynamic>? ?? [];
    List<Clip> parsedClips = clipListFromJson
        .map((clipJson) => Clip.fromJson(clipJson as Map<String, dynamic>))
        .toList();

    return Track(
      name: json['name'] as String? ?? 'Unnamed Track',
      clips: parsedClips,
      // Deserialize enum from string
      type: _parseTrackType(
          json['typeString'] as String? ?? TrackType.normal.name),
      isVisible: json['isVisible'] as bool? ?? true,
      isMuted: json['isMuted'] as bool? ?? false,
      isSolo: json['isSolo'] as bool? ?? false,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      pan: (json['pan'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Method to convert Track instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      // Serialize list of clips by calling toJson on each Clip
      'clips': clips.map((clip) => clip.toJson()).toList(),
      // Serialize enum as string
      'typeString': type.name,
      'isVisible': isVisible,
      'isMuted': isMuted,
      'isSolo': isSolo,
      'volume': volume,
      'pan': pan,
    };
  }
}
