import 'clip.dart';

/// 音频轨道模型
class Track {
  final String name;
  final List<Clip> clips;
  bool isVisible; // 控制轨道是否显示
  bool isMuted; // 是否静音
  bool isSolo; // 是否独奏
  double volume; // 音量 (0.0 - 1.0)
  double pan; // 声像 (-1.0左 ~ 1.0右)

  Track({
    required this.name,
    required this.clips,
    this.isVisible = true,
    this.isMuted = false,
    this.isSolo = false,
    this.volume = 1.0,
    this.pan = 0.0,
  });
}
