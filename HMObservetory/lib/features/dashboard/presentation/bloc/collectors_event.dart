import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/collector.dart';

abstract class CollectorsEvent extends Equatable {
  const CollectorsEvent();

  @override
  List<Object?> get props => [];
}

class CollectorsFetchRequested extends CollectorsEvent {}

class CollectorAdded extends CollectorsEvent {
  final String name;
  const CollectorAdded(this.name);
  @override
  List<Object?> get props => [name];
}

class CollectorRemoved extends CollectorsEvent {
  final String id;
  const CollectorRemoved(this.id);
  @override
  List<Object?> get props => [id];
}

class CollectorUpdated extends CollectorsEvent {
  final Collector collector;
  const CollectorUpdated(this.collector);
  @override
  List<Object?> get props => [collector];
}
