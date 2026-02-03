import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/data_record.dart';
import '../services/firestore_service.dart';

class StationVizDialog extends StatefulWidget {
  final String stationId;
  const StationVizDialog({super.key, required this.stationId});

  @override
  State<StationVizDialog> createState() => _StationVizDialogState();
}

class _StationVizDialogState extends State<StationVizDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  List<DataRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final all = await _firestoreService.getAllRecords();
      // Filter for this station
      _records = all
          .where(
            (r) =>
                r.rainStation == widget.stationId ||
                r.flowStation == widget.stationId,
          )
          .toList();
      // Sort by date ascending for the graph
      _records.sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      debugPrint('Error loading station data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRain = widget.stationId.contains('Index');
    final title = isRain ? 'Rainfall Data' : 'Discharge Data';

    final color = isRain ? Colors.cyan : Colors.blue;

    return AlertDialog(
      title: Text('${widget.stationId}\n$title'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 300,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _records.isEmpty
            ? const Center(
                child: Text('No data recorded yet for this station.'),
              )
            : Padding(
                padding: const EdgeInsets.only(top: 20, right: 20),
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1, // Will adjust based on data length
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < 0 ||
                                value.toInt() >= _records.length) {
                              return const SizedBox();
                            }
                            final dateStr = _records[value.toInt()].date;
                            final date = DateTime.parse(dateStr);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MM/dd').format(date),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) => Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _records.asMap().entries.map((entry) {
                          double val = 0;
                          if (isRain) {
                            val =
                                double.tryParse(entry.value.rainfall ?? '0') ??
                                0;
                          } else {
                            val =
                                double.tryParse(entry.value.discharge ?? '0') ??
                                0;
                          }
                          return FlSpot(entry.key.toDouble(), val);
                        }).toList(),
                        isCurved: true,
                        color: color,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: color.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
