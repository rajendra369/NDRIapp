class DataRecord {
  final String date;
  final String collector;
  final String? rainStation;
  final String? rainfall;
  final String? flowStation;
  final String? discharge;
  final DateTime lastUpdated;

  DataRecord({
    required this.date,
    required this.collector,
    this.rainStation,
    this.rainfall,
    this.flowStation,
    this.discharge,
    required this.lastUpdated,
  });

  // Generate document ID: DATE_STATION
  String get documentId {
    final station = rainStation ?? flowStation ?? '';
    final sanitized = station.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    return '${date}_$sanitized';
  }

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'collector': collector,
      if (rainStation != null) 'rainStation': rainStation,
      if (rainfall != null) 'rainfall': rainfall,
      if (flowStation != null) 'flowStation': flowStation,
      if (discharge != null) 'discharge': discharge,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory DataRecord.fromJson(Map<String, dynamic> json) {
    return DataRecord(
      date: json['date'] as String,
      collector: json['collector'] as String,
      rainStation: json['rainStation'] as String?,
      rainfall: json['rainfall'] as String?,
      flowStation: json['flowStation'] as String?,
      discharge: json['discharge'] as String?,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  // Copy with method for updates
  DataRecord copyWith({
    String? date,
    String? collector,
    String? rainStation,
    String? rainfall,
    String? flowStation,
    String? discharge,
    DateTime? lastUpdated,
  }) {
    return DataRecord(
      date: date ?? this.date,
      collector: collector ?? this.collector,
      rainStation: rainStation ?? this.rainStation,
      rainfall: rainfall ?? this.rainfall,
      flowStation: flowStation ?? this.flowStation,
      discharge: discharge ?? this.discharge,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
