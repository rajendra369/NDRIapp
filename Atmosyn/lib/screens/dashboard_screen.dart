import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../models/station_mapping.dart';
import 'station_viz_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MapController _mapController = MapController();
  List<Polyline> _provinceBoundaries = [];
  List<Polyline> _districtBoundaries = [];
  List<Polyline> _palikaBoundaries = [];
  bool _isLoadingMap = true;

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    setState(() => _isLoadingMap = true);
    try {
      final provinceUrl =
          'https://raw.githubusercontent.com/Acesmndr/nepal-geojson/master/generated-geojson/nepal-with-provinces-acesmndr.geojson';
      final districtUrl =
          'https://raw.githubusercontent.com/Acesmndr/nepal-geojson/master/generated-geojson/nepal-with-districts-acesmndr.geojson';
      final palikaUrl =
          'https://raw.githubusercontent.com/younginnovations/nepal-locallevel-map/master/out/municipalities.simplified.geojson';

      final results = await Future.wait([
        http.get(Uri.parse(provinceUrl)),
        http.get(Uri.parse(districtUrl)),
        http.get(Uri.parse(palikaUrl)),
      ]);

      if (results[0].statusCode == 200) {
        _provinceBoundaries = _parseGeoJson(
          results[0].body,
          Colors.blue.withValues(alpha: 0.6),
          3.0,
        );
      }
      if (results[1].statusCode == 200) {
        _districtBoundaries = _parseGeoJson(
          results[1].body,
          Colors.black45,
          1.5,
        );
      }
      if (results[2].statusCode == 200) {
        _palikaBoundaries = _parseGeoJson(
          results[2].body,
          Colors.grey.withValues(alpha: 0.3),
          0.8,
        );
      }
    } catch (e) {
      debugPrint('Error loading map data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMap = false);
    }
  }

  List<Polyline> _parseGeoJson(String data, Color color, double stroke) {
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

  void _showStationData(String stationId) {
    showDialog(
      context: context,
      builder: (context) => StationVizDialog(stationId: stationId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stationMarkers = StationMapping.coordinates.entries.map((entry) {
      return Marker(
        point: LatLng(entry.value[0], entry.value[1]),
        width: 40,
        height: 40,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onDoubleTap: () => _showStationData(entry.key),
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
                ),
                child: Icon(
                  entry.key.contains('Flow') ? Icons.waves : Icons.water_drop,
                  color: entry.key.contains('Flow') ? Colors.blue : Colors.cyan,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.key.split('_').last,
                  style: const TextStyle(color: Colors.white, fontSize: 8),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nepal Data Dashboard'),
        actions: [
          if (_isLoadingMap)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMapData),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: LatLng(28.3949, 84.1240),
          initialZoom: 7,
          minZoom: 5,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'org.ndri.muhan',
          ),
          PolylineLayer(polylines: _palikaBoundaries),
          PolylineLayer(polylines: _districtBoundaries),
          PolylineLayer(polylines: _provinceBoundaries),
          MarkerLayer(markers: stationMarkers),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'zoom_in',
            onPressed: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom + 1,
            ),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'zoom_out',
            onPressed: () => _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom - 1,
            ),
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
