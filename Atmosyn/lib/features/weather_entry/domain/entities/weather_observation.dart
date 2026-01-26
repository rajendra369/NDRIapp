import 'package:equatable/equatable.dart';

class WeatherObservation extends Equatable {
  final int? id;
  final String stationId;
  final DateTime timestamp;
  final double? temperature;
  final double? rainfall;
  final double? humidity;
  final double? windSpeed;
  final String? remarks;
  final bool isSynced;
  final String status; // 'DRAFT', 'VERIFIED'

  const WeatherObservation({
    this.id,
    required this.stationId,
    required this.timestamp,
    this.temperature,
    this.rainfall,
    this.humidity,
    this.windSpeed,
    this.remarks,
    this.isSynced = false,
    this.status = 'DRAFT',
  });

  @override
  List<Object?> get props => [
    id,
    stationId,
    timestamp,
    temperature,
    rainfall,
    humidity,
    windSpeed,
    remarks,
    isSynced,
    status,
  ];
}
