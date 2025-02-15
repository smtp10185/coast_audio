import 'dart:math';

import 'package:music_core/music_core.dart';

class AutomationCurve {
  List<AutomationPoint> points = [];
  dynamic ownerParam; // Placeholder for the owner parameter

  int getNumPoints() => points.length;

  TimeDuration getLength() =>
      TimeDuration.fromSeconds(points.last.time.inSeconds());

  AutomationPoint getPoint(int index) => points[index];

  TimePosition getPointTime(int index) => points[index].time;

  double getPointValue(int index) => points[index].value;

  double getPointCurve(int index) => points[index].curve;

  void addPoint(TimePosition time, double value, double curve) {
    points.add(AutomationPoint(time, value, curve));
    points.sort((a, b) => a.time.inSeconds().compareTo(b.time.inSeconds()));
  }

  void removePoint(int index) {
    if (index >= 0 && index < points.length) {
      points.removeAt(index);
    }
  }

  void clear() {
    points.clear();
  }

  double getValueAt(TimePosition timePos) {
    if (points.isEmpty) return 0.0;

    final time = timePos.inSeconds();
    if (time <= points.first.time.inSeconds()) return points.first.value;
    if (time >= points.last.time.inSeconds()) return points.last.value;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      if (time >= p1.time.inSeconds() && time <= p2.time.inSeconds()) {
        final alpha = (time - p1.time.inSeconds()) /
            (p2.time.inSeconds() - p1.time.inSeconds());
        return p1.value + alpha * (p2.value - p1.value);
      }
    }

    return 0.0;
  }

  void setPointTime(int i, TimePosition time) {}

  // Additional methods like getBezierPoint, getBezierYFromX, etc., would be implemented here
}

class AutomationPoint {
  final TimePosition time;
  final double value;
  final double curve;

  AutomationPoint(this.time, this.value, this.curve);
}
