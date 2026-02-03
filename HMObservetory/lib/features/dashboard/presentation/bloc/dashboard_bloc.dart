import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/datasources/map_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final MapService _mapService;

  DashboardBloc({required MapService mapService})
    : _mapService = mapService,
      super(DashboardInitial()) {
    on<DashboardDataRequested>(_onDashboardDataRequested);
    on<DashboardRefreshRequested>(_onDashboardDataRequested);
  }

  Future<void> _onDashboardDataRequested(
    DashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final data = await _mapService.fetchGeoJsonData();

      final provinces = _parseGeoJson(
        data['provinces'] ?? '',
        Colors.blue.withValues(alpha: 0.6),
        3.0,
      );
      final districts = _parseGeoJson(
        data['districts'] ?? '',
        Colors.black45,
        1.5,
      );
      final palikas = _parseGeoJson(
        data['palikas'] ?? '',
        Colors.grey.withValues(alpha: 0.3),
        0.8,
      );

      emit(
        DashboardLoaded(
          provinceBoundaries: provinces,
          districtBoundaries: districts,
          palikaBoundaries: palikas,
        ),
      );
    } catch (e) {
      emit(DashboardError('Failed to load map data: $e'));
    }
  }

  List<Polyline> _parseGeoJson(String data, Color color, double stroke) {
    if (data.isEmpty) return [];
    final List<Polyline> polylines = [];
    final Map<String, dynamic> json = jsonDecode(data);
    final List features = json['features'] ?? [];

    for (var feature in features) {
      final geometry = feature['geometry'];
      if (geometry == null) continue;

      final type = geometry['type'];
      final coordinates = geometry['coordinates'];

      if (type == 'Polygon') {
        _addPolygonToPolylines(coordinates, polylines, color, stroke);
      } else if (type == 'MultiPolygon') {
        for (var polygon in coordinates) {
          _addPolygonToPolylines(polygon, polylines, color, stroke);
        }
      }
    }
    return polylines;
  }

  void _addPolygonToPolylines(
    List coordinates,
    List<Polyline> polylines,
    Color color,
    double stroke,
  ) {
    for (var ring in coordinates) {
      final List<LatLng> points = [];
      for (var coord in ring) {
        points.add(LatLng(coord[1].toDouble(), coord[0].toDouble()));
      }
      polylines.add(
        Polyline(points: points, color: color, strokeWidth: stroke),
      );
    }
  }
}
