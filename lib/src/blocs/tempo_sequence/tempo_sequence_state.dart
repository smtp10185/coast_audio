part of 'tempo_sequence_bloc.dart';

abstract class TempoSequenceState extends Equatable {
  const TempoSequenceState();

  @override
  List<Object> get props => [];
}

class TempoSequenceInitial extends TempoSequenceState {}

class TempoSequenceLoaded extends TempoSequenceState {
  final List<TempoSetting> tempos;
  final List<TimeSigSetting> timeSigs;

  const TempoSequenceLoaded({required this.tempos, required this.timeSigs});

  @override
  List<Object> get props => [tempos, timeSigs];
}

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
