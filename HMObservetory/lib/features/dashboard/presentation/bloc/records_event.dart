import 'package:equatable/equatable.dart';
import '../../domain/entities/data_record.dart';

abstract class RecordsEvent extends Equatable {
  const RecordsEvent();

  @override
  List<Object?> get props => [];
}

class RecordSaveRequested extends RecordsEvent {
  final DataRecord record;

  const RecordSaveRequested(this.record);

  @override
  List<Object?> get props => [record];
}

class RecordsFetchRequested extends RecordsEvent {}

class RecordsClearRequested extends RecordsEvent {}
