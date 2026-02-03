import 'package:equatable/equatable.dart';

abstract class ImportEvent extends Equatable {
  const ImportEvent();

  @override
  List<Object?> get props => [];
}

class ImportFileRequested extends ImportEvent {}

class ImportUploadRequested extends ImportEvent {
  final List<Map<String, dynamic>> data;
  const ImportUploadRequested(this.data);
  @override
  List<Object?> get props => [data];
}
