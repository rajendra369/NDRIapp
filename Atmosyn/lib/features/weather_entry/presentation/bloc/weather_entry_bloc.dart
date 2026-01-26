import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/save_weather_observation.dart';
import 'weather_entry_event.dart';
import 'weather_entry_state.dart';

class WeatherEntryBloc extends Bloc<WeatherEntryEvent, WeatherEntryState> {
  final SaveWeatherObservation saveWeatherObservation;

  WeatherEntryBloc({required this.saveWeatherObservation})
    : super(WeatherEntryInitial()) {
    on<SaveObservationEvent>(_onSaveObservation);
  }

  Future<void> _onSaveObservation(
    SaveObservationEvent event,
    Emitter<WeatherEntryState> emit,
  ) async {
    emit(WeatherEntryLoading());
    final result = await saveWeatherObservation(
      Params(observation: event.observation),
    );
    result.fold(
      (failure) =>
          emit(const WeatherEntryFailure("Failed to save observation")),
      (_) => emit(WeatherEntrySuccess()),
    );
  }
}
