/// Enum representing common musical note durations.
enum NoteDuration {
  whole(4, '全音符'),
  half(2, '二分音符'),
  quarter(1, '四分音符'),
  eighth(0.5, '八分音符'),
  sixteenth(0.25, '十六分音符');

  /// The number of beats this duration represents (assuming 4/4 time or similar).
  final double beats;

  /// A user-friendly display name.
  final String displayName;

  const NoteDuration(this.beats, this.displayName);

  /// Finds the NoteDuration that most closely matches the given number of beats.
  /// Returns quarter note by default if no close match is found.
  static NoteDuration fromBeats(double beats) {
    NoteDuration closest = NoteDuration.quarter;
    double minDifference = (NoteDuration.quarter.beats - beats).abs();

    for (final duration in NoteDuration.values) {
      final difference = (duration.beats - beats).abs();
      if (difference < minDifference) {
        minDifference = difference;
        closest = duration;
      }
    }
    // Add a small tolerance for floating point comparisons
    if (minDifference < 0.01) {
      return closest;
    } else {
      // If no standard duration is close enough, maybe default or handle differently?
      // For now, let's stick to the closest standard one found.
      // Consider returning null or throwing if exact match is needed elsewhere.
      print(
          "Warning: Beats value $beats doesn't closely match a standard NoteDuration. Using ${closest.displayName}.");
      return closest;
    }
  }
}
