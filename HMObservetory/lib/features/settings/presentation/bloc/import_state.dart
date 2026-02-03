import 'package:equatable/equatable.dart';

abstract class ImportState extends Equatable {
  const ImportState();

  @override
  List<Object?> get props => [];
}

class ImportInitial extends ImportState {}

class ImportLoading extends ImportState {
  final String message;
  const ImportLoading(this.message);
  @override
  List<Object?> get props => [message];
}

class ImportFileSelected extends ImportState {
  final String fileName;
  final List<Map<String, dynamic>> data;
  const ImportFileSelected(this.fileName, this.data);
  @override
  List<Object?> get props => [fileName, data];
}

class ImportSuccess extends ImportState {
  final int count;
  const ImportSuccess(this.count);
  @override
  List<Object?> get props => [count];
}

class ImportError extends ImportState {
  final String message;
  const ImportError(this.message);
  @override
  List<Object?> get props => [message];
}
