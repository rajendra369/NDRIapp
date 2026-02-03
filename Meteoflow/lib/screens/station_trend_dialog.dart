import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/station_mapping.dart';

class StationTrendDialog extends StatefulWidget {
  final String stationId;

  const StationTrendDialog({super.key, required this.stationId});

  @override
  State<StationTrendDialog> createState() => _StationTrendDialogState();
}

class _StationTrendDialogState extends State<StationTrendDialog> {
  bool _isLoading = true;
  List<FlSpot> _dataPoints = [];
  List<DateTime> _dates = [];
  String _selectedPeriod = '7days';
  double _minY = 0;
  double _maxY = 100;

  @override
  void initState() {
    super.initState();
    _loadTrendData();
  }

  Future<void> _loadTrendData() async {
    setState(() => _isLoading = true);

    try {
      // Calculate date range based on selected period
      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedPeriod) {
        case '7days':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case '30days':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case '90days':
          startDate = now.subtract(const Duration(days: 90));
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
      }

      // Try to fetch data from Firestore
      // If Firebase is not initialized, this will throw an error
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('data_records')
            .where('stationId', isEqualTo: widget.stationId)
            .where('timestamp', isGreaterThanOrEqualTo: startDate)
            .orderBy('timestamp')
            .get();

        final points = <FlSpot>[];
        final dates = <DateTime>[];

        for (var i = 0; i < querySnapshot.docs.length; i++) {
          final doc = querySnapshot.docs[i];
          final data = doc.data();
          final timestamp = (data['timestamp'] as Timestamp).toDate();
          final value = (data['value'] as num?)?.toDouble() ?? 0.0;

          points.add(FlSpot(i.toDouble(), value));
          dates.add(timestamp);
        }

        if (points.isNotEmpty) {
          final values = points.map((p) => p.y).toList();
          _minY = values.reduce((a, b) => a < b ? a : b) * 0.9;
          _maxY = values.reduce((a, b) => a > b ? a : b) * 1.1;
        }

        setState(() {
          _dataPoints = points;
          _dates = dates;
          _isLoading = false;
        });
      } catch (firestoreError) {
        // Firebase not initialized or Firestore error
        debugPrint('Firestore not available: $firestoreError');
        setState(() {
          _dataPoints = [];
          _dates = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading trend data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stationName = StationMapping.getStationName(widget.stationId);
    final stationType = StationMapping.getStationType(widget.stationId);
    final isSpring = stationType == 'Spring';

    // Get station code for display
    String stationCode;
    if (isSpring) {
      stationCode = widget.stationId.replaceAll('Flow_', '');
    } else {
      final code = widget.stationId.replaceAll('Index_', '');
      stationCode = 'M-${code.substring(code.length - 3)}';
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSpring
                      ? [Colors.blue[700]!, Colors.blue[500]!]
                      : [Colors.orange[700]!, Colors.orange[500]!],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSpring ? Icons.waves : Icons.water_drop,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stationCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          stationName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Period selector
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Period:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: '7days', label: Text('7D')),
                        ButtonSegment(value: '30days', label: Text('30D')),
                        ButtonSegment(value: '90days', label: Text('90D')),
                      ],
                      selected: {_selectedPeriod},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _selectedPeriod = newSelection.first;
                          _loadTrendData();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Chart
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _dataPoints.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No data available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: (_maxY - _minY) / 5,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey[300]!,
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 45,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < _dates.length) {
                                    final date = _dates[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        DateFormat('MM/dd').format(date),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          minY: _minY,
                          maxY: _maxY,
                          lineBarsData: [
                            LineChartBarData(
                              spots: _dataPoints,
                              isCurved: true,
                              color: isSpring ? Colors.blue : Colors.orange,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: _dataPoints.length < 30,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: Colors.white,
                                    strokeWidth: 2,
                                    strokeColor: isSpring
                                        ? Colors.blue
                                        : Colors.orange,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: (isSpring ? Colors.blue : Colors.orange)
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // Stats summary
            if (!_isLoading && _dataPoints.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Min',
                      _minY.toStringAsFixed(2),
                      Icons.arrow_downward,
                      Colors.red,
                    ),
                    _buildStatItem(
                      'Max',
                      _maxY.toStringAsFixed(2),
                      Icons.arrow_upward,
                      Colors.green,
                    ),
                    _buildStatItem(
                      'Avg',
                      (_dataPoints.map((p) => p.y).reduce((a, b) => a + b) /
                              _dataPoints.length)
                          .toStringAsFixed(2),
                      Icons.show_chart,
                      Colors.blue,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
