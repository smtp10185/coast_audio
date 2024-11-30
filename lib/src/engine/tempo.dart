class TempoSetting {
  final double bpm;
  final double startBeat;
  final double curve;

  TempoSetting(
      {required this.bpm, required this.startBeat, required this.curve});
}

class TimeSigSetting {
  final double startBeat;
  final int numerator;
  final int denominator;
  final bool triplets;

  TimeSigSetting({
    required this.startBeat,
    required this.numerator,
    required this.denominator,
    required this.triplets,
  });
}
