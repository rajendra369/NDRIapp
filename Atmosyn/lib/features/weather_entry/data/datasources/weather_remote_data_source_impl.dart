import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/exceptions.dart';
import '../models/weather_observation_model.dart';
import 'weather_remote_data_source.dart';

class WeatherRemoteDataSourceImpl implements WeatherRemoteDataSource {
  final FirebaseFirestore firestore;

  WeatherRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> syncObservation(WeatherObservationModel observation) async {
    try {
      await firestore
          .collection('observations')
          .doc(observation.id?.toString())
          .set(observation.toJson());
    } catch (e) {
      throw ServerException();
    }
  }
}
