import '../../domain/entities/weather_observation.dart';

class WeatherObservationModel extends WeatherObservation {
  const WeatherObservationModel({
    super.id,
    required super.stationId,
    required super.timestamp,
    super.temperature,
    super.rainfall,
    super.humidity,
    super.windSpeed,
    super.remarks,
    super.isSynced,
    super.status,
  });

  factory WeatherObservationModel.fromJson(Map<String, dynamic> json) {
    return WeatherObservationModel(
      id: json['id'],
      stationId: json['station_id'],
      timestamp: DateTime.parse(json['timestamp']),
      temperature: json['temperature']?.toDouble(),
      rainfall: json['rainfall']?.toDouble(),
      humidity: json['humidity']?.toDouble(),
      windSpeed: json['wind_speed']?.toDouble(),
      remarks: json['remarks'],
      isSynced: json['is_synced'] == 1, // SQLite uses 0/1 for boolean
      status: json['status'] ?? 'DRAFT',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'station_id': stationId,
      'timestamp': timestamp.toIso8601String(),
      'temperature': temperature,
      'rainfall': rainfall,
      'humidity': humidity,
      'wind_speed': windSpeed,
      'remarks': remarks,
      'is_synced': isSynced ? 1 : 0,
      'status': status,
    };
  }

  factory WeatherObservationModel.fromEntity(WeatherObservation entity) {
    return WeatherObservationModel(
      id: entity.id,
      stationId: entity.stationId,
      timestamp: entity.timestamp,
      temperature: entity.temperature,
      rainfall: entity.rainfall,
      humidity: entity.humidity,
      windSpeed: entity.windSpeed,
      remarks: entity.remarks,
      isSynced: entity.isSynced,
      status: entity.status,
    );
  }
}
