import 'package:equatable/equatable.dart';
import 'package:flutter_map/flutter_map.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final List<Polyline> provinceBoundaries;
  final List<Polyline> districtBoundaries;
  final List<Polyline> palikaBoundaries;

  const DashboardLoaded({
    required this.provinceBoundaries,
    required this.districtBoundaries,
    required this.palikaBoundaries,
  });

  @override
  List<Object?> get props => [
    provinceBoundaries,
    districtBoundaries,
    palikaBoundaries,
  ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
