import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/weather_observation.dart';
import '../../domain/repositories/weather_repository.dart';

class SaveWeatherObservation implements UseCase<void, Params> {
  final WeatherRepository repository;

  SaveWeatherObservation(this.repository);

  @override
  Future<Either<Failure, void>> call(Params params) async {
    return await repository.saveWeatherObservation(params.observation);
  }
}

class Params extends Equatable {
  final WeatherObservation observation;

  const Params({required this.observation});

  @override
  List<Object> get props => [observation];
}
