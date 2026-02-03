import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/entities/station_mapping.dart';
import '../widgets/station_trend_dialog.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MapController _mapController = MapController();

  // Map center for Sindhuli monitoring area
  static const LatLng _sindhuliCenter = LatLng(27.30, 85.90);
  static const double _initialZoom = 10.5;

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
    final stationMarkers = StationMapping.coordinates.entries.map((entry) {
      final stationId = entry.key;
      final coords = entry.value;
      final stationType = StationMapping.getStationType(stationId);
      final isSpring = stationType == 'Spring';

      String stationCode;
      if (isSpring) {
        stationCode = stationId.replaceAll('Flow_', '');
      } else {
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

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final isLoading = state is DashboardLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Sindhuli Monitoring Dashboard'),
            actions: [
              if (isLoading)
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
                onPressed: () => context.read<DashboardBloc>().add(
                  DashboardRefreshRequested(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
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
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'org.ndri.muhan',
                  ),
                  if (state is DashboardLoaded) ...[
                    PolylineLayer(polylines: state.palikaBoundaries),
                    PolylineLayer(polylines: state.districtBoundaries),
                    PolylineLayer(polylines: state.provinceBoundaries),
                  ],
                  MarkerLayer(markers: stationMarkers),
                ],
              ),
              if (state is DashboardError)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              Positioned(
                bottom: 16,
                left: 16,
                child: GlassContainer(
                  padding: const EdgeInsets.all(12),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Legend',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
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
      },
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
