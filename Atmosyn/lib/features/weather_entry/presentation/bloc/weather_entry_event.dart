import 'package:equatable/equatable.dart';
import '../../domain/entities/weather_observation.dart';

abstract class WeatherEntryEvent extends Equatable {
  const WeatherEntryEvent();

  @override
  List<Object> get props => [];
}

class SaveObservationEvent extends WeatherEntryEvent {
  final WeatherObservation observation;

  const SaveObservationEvent(this.observation);

  @override
  List<Object> get props => [observation];
}
