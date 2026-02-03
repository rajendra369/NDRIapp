import 'package:flutter/material.dart';
import '../models/data_record.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class RecordCard extends StatelessWidget {
  final DataRecord record;

  const RecordCard({
    super.key,
    required this.record,
  });

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date
            Text(
              _formatDate(record.date),
              style: AppConstants.subheadingStyle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 4),
            
            // Collector
            Text(
              'Collector: ${record.collector}',
              style: AppConstants.captionStyle,
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            
            // Data values
            if (record.rainStation != null && record.rainfall != null) ...[
              Row(
                children: [
                  const Icon(Icons.water_drop, size: 16, color: AppConstants.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    'Rain: ',
                    style: AppConstants.bodyStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${record.rainfall}mm ',
                    style: AppConstants.bodyStyle,
                  ),
                  Text(
                    '(${record.rainStation})',
                    style: AppConstants.captionStyle.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ],
            
            if (record.flowStation != null && record.discharge != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.waves, size: 16, color: AppConstants.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    'Flow: ',
                    style: AppConstants.bodyStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${record.discharge}LPS ',
                    style: AppConstants.bodyStyle,
                  ),
                  Text(
                    '(${record.flowStation})',
                    style: AppConstants.captionStyle.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
