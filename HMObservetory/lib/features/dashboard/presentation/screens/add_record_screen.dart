import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/entities/data_record.dart';
import '../../../auth/domain/entities/collector.dart';
import '../bloc/records_bloc.dart';
import '../bloc/records_event.dart';
import '../bloc/records_state.dart';
import '../bloc/collectors_bloc.dart';
import '../bloc/collectors_state.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form State
  String? _selectedCollectorId;
  DateTime _selectedDate = DateTime.now();
  String _entryType = 'rain'; // 'rain' or 'discharge'

  // Available stations for current selection
  List<String> _currentRainStations = [];
  List<String> _currentFlowStations = [];

  // Rain State
  String? _selectedRainStation;
  final TextEditingController _rainfallController = TextEditingController();

  // Discharge State
  String? _selectedFlowStation;
  final TextEditingController _dischargeController = TextEditingController();

  @override
  void dispose() {
    _rainfallController.dispose();
    _dischargeController.dispose();
    super.dispose();
  }

  void _onCollectorChanged(String? collectorId, List<Collector> allCollectors) {
    if (collectorId == null) return;

    final collector = allCollectors.firstWhere(
      (c) => c.id == collectorId,
      orElse: () =>
          Collector(id: '', name: '', rainStations: [], flowStations: []),
    );

    setState(() {
      _selectedCollectorId = collectorId;
      _currentRainStations = collector.rainStations;
      _currentFlowStations = collector.flowStations;
      _selectedRainStation = null;
      _selectedFlowStation = null;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm(List<Collector> allCollectors) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCollectorId == null) return;

    final collectorName = allCollectors
        .firstWhere((c) => c.id == _selectedCollectorId)
        .name;

    final record = DataRecord(
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      collector: collectorName,
      rainStation: _entryType == 'rain' ? _selectedRainStation : null,
      rainfall: _entryType == 'rain' ? _rainfallController.text : null,
      flowStation: _entryType == 'discharge' ? _selectedFlowStation : null,
      discharge: _entryType == 'discharge' ? _dischargeController.text : null,
      lastUpdated: DateTime.now(),
    );

    context.read<RecordsBloc>().add(RecordSaveRequested(record));
  }

  void _resetForm() {
    _rainfallController.clear();
    _dischargeController.clear();
    setState(() {
      _selectedRainStation = null;
      _selectedFlowStation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecordsBloc, RecordsState>(
      listener: (context, state) {
        if (state is RecordSaveSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record saved successfully!')),
          );
          _resetForm();
        } else if (state is RecordsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final isSaving = state is RecordsLoading;

        return Scaffold(
          appBar: AppBar(title: const Text('Add Record')),
          body: BlocBuilder<CollectorsBloc, CollectorsState>(
            builder: (context, collectorState) {
              if (collectorState is CollectorsLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (collectorState is CollectorsError) {
                return Center(child: Text('Error: ${collectorState.message}'));
              }

              final collectors = collectorState is CollectorsLoaded
                  ? collectorState.collectors
                  : <Collector>[];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedCollectorId,
                          items: collectors
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                          decoration: const InputDecoration(
                            labelText: 'Collector Name',
                          ),
                          onChanged: (value) =>
                              _onCollectorChanged(value, collectors),
                          validator: (val) => val == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              DateFormat('MMM d, yyyy').format(_selectedDate),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'rain',
                              label: Text('Rainfall'),
                              icon: Icon(Icons.water_drop),
                            ),
                            ButtonSegment(
                              value: 'discharge',
                              label: Text('Discharge'),
                              icon: Icon(Icons.waves),
                            ),
                          ],
                          selected: {_entryType},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              _entryType = newSelection.first;
                              _formKey.currentState?.reset();
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        if (_entryType == 'rain') ...[
                          if (_currentRainStations.isEmpty &&
                              _selectedCollectorId != null)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Text(
                                'No rain stations assigned to this collector.',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          DropdownButtonFormField<String>(
                            value: _selectedRainStation,
                            items: _currentRainStations
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            decoration: const InputDecoration(
                              labelText: 'Station Name',
                            ),
                            onChanged: (val) =>
                                setState(() => _selectedRainStation = val),
                            validator: (val) => val == null ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _rainfallController,
                            decoration: const InputDecoration(
                              labelText: 'Rainfall (mm)',
                              hintText: '0.0',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ] else ...[
                          if (_currentFlowStations.isEmpty &&
                              _selectedCollectorId != null)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Text(
                                'No flow stations assigned to this collector.',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          DropdownButtonFormField<String>(
                            value: _selectedFlowStation,
                            items: _currentFlowStations
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            decoration: const InputDecoration(
                              labelText: 'Spring/Stream Name',
                            ),
                            onChanged: (val) =>
                                setState(() => _selectedFlowStation = val),
                            validator: (val) => val == null ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _dischargeController,
                            decoration: const InputDecoration(
                              labelText: 'Spring Discharge (LPS)',
                              hintText: '0.00',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: isSaving
                              ? null
                              : () => _submitForm(collectors),
                          icon: isSaving
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(isSaving ? 'Saving...' : 'Save Record'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
