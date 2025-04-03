import 'package:coast_audio/src/engine/clip.dart';

abstract class ClipOwner {
  ClipOwner();

  // 获取ClipOwner的状态
  Map<String, dynamic> getClipOwnerState();

  // 获取ClipOwner的ID
  String getClipOwnerID();

  // 获取ClipOwner的可选对象
  dynamic getClipOwnerSelectable();

  // 获取ClipOwner所属的编辑对象
  dynamic getClipOwnerEdit();

  // 获取所有剪辑
  List<Clip> getClips();

  // 初始化ClipOwner
  void initialiseClipOwner(dynamic edit, Map<String, dynamic> clipParentState);

  // 当剪辑被创建时调用
  void clipCreated(Clip clip);

  // 当剪辑被添加或移除时调用
  void clipAddedOrRemoved();

  // 当剪辑的顺序改变时调用
  void clipOrderChanged();

  // 当剪辑的开始或结束位置改变时调用
  void clipPositionChanged();
}
