import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'tempo_sequence_event.dart';
part 'tempo_sequence_state.dart';

class TempoSequenceBloc extends Bloc<TempoSequenceEvent, TempoSequenceState> {
  TempoSequenceBloc() : super(TempoSequenceInitial()) {
    on<LoadTempoSequence>((event, emit) {
      // Load initial data
      emit(TempoSequenceLoaded(tempos: [], timeSigs: []));
    });

    on<AddTempo>((event, emit) {
      if (state is TempoSequenceLoaded) {
        final currentState = state as TempoSequenceLoaded;
        final updatedTempos = List<TempoSetting>.from(currentState.tempos)
          ..add(event.tempo);
        emit(TempoSequenceLoaded(
            tempos: updatedTempos, timeSigs: currentState.timeSigs));
      }
    });

    on<AddTimeSig>((event, emit) {
      if (state is TempoSequenceLoaded) {
        final currentState = state as TempoSequenceLoaded;
        final updatedTimeSigs = List<TimeSigSetting>.from(currentState.timeSigs)
          ..add(event.timeSig);
        emit(TempoSequenceLoaded(
            tempos: currentState.tempos, timeSigs: updatedTimeSigs));
      }
    });
  }
}
