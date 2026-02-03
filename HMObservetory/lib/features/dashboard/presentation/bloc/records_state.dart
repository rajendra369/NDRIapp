import 'package:equatable/equatable.dart';
import '../../domain/entities/data_record.dart';

abstract class RecordsState extends Equatable {
  const RecordsState();

  @override
  List<Object?> get props => [];
}

class RecordsInitial extends RecordsState {}

class RecordsLoading extends RecordsState {}

class RecordSaveSuccess extends RecordsState {}

class RecordsLoaded extends RecordsState {
  final List<DataRecord> records;

  const RecordsLoaded(this.records);

  @override
  List<Object?> get props => [records];
}

class RecordsError extends RecordsState {
  final String message;

  const RecordsError(this.message);

  @override
  List<Object?> get props => [message];
}
