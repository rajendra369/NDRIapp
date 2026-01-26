import 'package:equatable/equatable.dart';

abstract class WeatherEntryState extends Equatable {
  const WeatherEntryState();

  @override
  List<Object> get props => [];
}

class WeatherEntryInitial extends WeatherEntryState {}

class WeatherEntryLoading extends WeatherEntryState {}

class WeatherEntrySuccess extends WeatherEntryState {}

class WeatherEntryFailure extends WeatherEntryState {
  final String message;

  const WeatherEntryFailure(this.message);

  @override
  List<Object> get props => [message];
}
