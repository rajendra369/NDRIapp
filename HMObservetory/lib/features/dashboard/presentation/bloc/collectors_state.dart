import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/collector.dart';

abstract class CollectorsState extends Equatable {
  const CollectorsState();

  @override
  List<Object?> get props => [];
}

class CollectorsInitial extends CollectorsState {}

class CollectorsLoading extends CollectorsState {}

class CollectorsLoaded extends CollectorsState {
  final List<Collector> collectors;

  const CollectorsLoaded(this.collectors);

  @override
  List<Object?> get props => [collectors];
}

class CollectorOperationSuccess extends CollectorsState {}

class CollectorsError extends CollectorsState {
  final String message;

  const CollectorsError(this.message);

  @override
  List<Object?> get props => [message];
}
