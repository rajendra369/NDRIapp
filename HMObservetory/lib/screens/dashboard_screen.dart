import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../models/station_mapping.dart';
import 'station_trend_dialog.dart';
import 'settings_screen.dart';

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

  // Map center for Sindhuli monitoring area
  static const LatLng _sindhuliCenter = LatLng(27.30, 85.90);
  static const double _initialZoom = 10.5;

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
      builder: (context) => StationTrendDialog(stationId: stationId),
    );
  }

  void _centerOnStations() {
    _mapController.move(_sindhuliCenter, _initialZoom);
  }

  @override
  Widget build(BuildContext context) {
    // Build markers for only monitored stations
    final stationMarkers = StationMapping.coordinates.entries.map((entry) {
      final stationId = entry.key;
      final coords = entry.value;
      final stationType = StationMapping.getStationType(stationId);
      final isSpring = stationType == 'Spring';

      // Get station code
      // Springs: "S-602" from "Flow_S602"
      // Rain Gauges: "M-201" from "Index_311050201" (M- + last 3 digits)
      String stationCode;
      if (isSpring) {
        stationCode = stationId.replaceAll('Flow_', '');
      } else {
        // Rain gauge: get last 3 digits and add M- prefix
        final code = stationId.replaceAll('Index_', '');
        stationCode = 'M-${code.substring(code.length - 3)}';
      }

      return Marker(
        point: LatLng(coords[0], coords[1]),
        width: 80,
        height: 60,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => _showStationData(stationId),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(blurRadius: 4, color: Colors.black26),
                  ],
                  border: Border.all(
                    color: isSpring ? Colors.blue : Colors.orange,
                    width: 2,
                  ),
                ),
                child: Icon(
                  isSpring ? Icons.waves : Icons.water_drop,
                  color: isSpring ? Colors.blue : Colors.orange,
                  size: 18,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: isSpring ? Colors.blue[700] : Colors.orange[700],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  stationCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sindhuli Monitoring Dashboard'),
        actions: [
          if (_isLoadingMap)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Center on stations',
            onPressed: _centerOnStations,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload map',
            onPressed: _loadMapData,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _sindhuliCenter,
              initialZoom: _initialZoom,
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

          // Legend
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(blurRadius: 4, color: Colors.black26),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Legend',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  _buildLegendItem(Icons.waves, Colors.blue, 'Spring (7)'),
                  const SizedBox(height: 4),
                  _buildLegendItem(
                    Icons.water_drop,
                    Colors.orange,
                    'Rain Gauge (4)',
                  ),
                  const Divider(),
                  Text(
                    'Tap marker to view trends',
                    style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
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

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
