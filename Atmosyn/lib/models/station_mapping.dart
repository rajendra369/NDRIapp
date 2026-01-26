class StationMapping {
  // Station mappings for each collector
  static const Map<String, Map<String, List<String>>> mapping = {
    'Chhabi Thapa': {
      'flow': ['Flow_311050406'],
    },
    'Niruta Purbachhane': {
      'rain': ['Index_311050201'],
      'flow': ['Flow_311050218', 'Flow_311050219'],
    },
    'Menuka Rai': {
      'rain': ['Index_311050601'],
      'flow': ['Flow_311050719', 'Flow_311050602'],
    },
    'Yuvaraja Shrestha': {
      'rain': ['Index_311060401'],
      'flow': ['Flow_311060410', 'Flow_311060306'],
    },
    'Muna Kumari Pahadi': {
      'rain': ['Index_311060301'],
      'flow': ['Flow_311060306'],
    },
    'DHM (Weather Stations)': {
      'rain': [
        'Index_110701_Daily',
        'Index_110701_Hourly',
        'Index_110702_Daily',
        'Index_110702_Hourly',
        'Index_585_Daily',
        'Index_585_Hourly',
        'Index_1115_Daily',
        'Index_1115_Hourly',
      ],
    },
  };

  // List of all collectors
  static const List<String> collectors = [
    'Chhabi Thapa',
    'Niruta Purbachhane',
    'Menuka Rai',
    'Yuvaraja Shrestha',
    'Muna Kumari Pahadi',
    'DHM (Weather Stations)',
  ];

  // Get rain stations for a collector
  static List<String> getRainStations(String collector) {
    return mapping[collector]?['rain'] ?? [];
  }

  // Get flow stations for a collector
  static List<String> getFlowStations(String collector) {
    return mapping[collector]?['flow'] ?? [];
  }

  // Get all rain stations (for CSV export)
  static List<String> getAllRainStations() {
    final stations = <String>{};
    for (var collectorMap in mapping.values) {
      if (collectorMap['rain'] != null) {
        stations.addAll(collectorMap['rain']!);
      }
    }
    return stations.toList()..sort();
  }

  // Get all flow stations (for CSV export)
  static List<String> getAllFlowStations() {
    final stations = <String>{};
    for (var collectorMap in mapping.values) {
      if (collectorMap['flow'] != null) {
        stations.addAll(collectorMap['flow']!);
      }
    }
    return stations.toList()..sort();
  }

  // Station coordinates for Map Visualization [lat, lng]
  static const Map<String, List<double>> coordinates = {
    // Flow Stations
    'Flow_311050406': [28.053, 85.321],
    'Flow_311050218': [27.712, 85.312],
    'Flow_311050219': [27.701, 85.334],
    'Flow_311050719': [28.210, 84.004],
    'Flow_311050602': [28.234, 84.056],
    'Flow_311060410': [26.812, 87.283],
    'Flow_311060306': [26.901, 87.123],

    // Rain Stations
    'Index_311050201': [27.721, 85.342],
    'Index_311050601': [28.192, 84.012],
    'Index_311060401': [26.834, 87.294],
    'Index_311060301': [26.912, 87.112],

    // DHM Stations
    'Index_110701_Daily': [27.345, 86.123],
    'Index_110701_Hourly': [27.345, 86.126],
    'Index_110702_Daily': [27.890, 84.567],
    'Index_110702_Hourly': [27.890, 84.570],
    'Index_585_Daily': [28.234, 83.123],
    'Index_585_Hourly': [28.234, 83.126],
    'Index_1115_Daily': [29.123, 82.345],
    'Index_1115_Hourly': [29.123, 82.348],
  };

  static List<double>? getCoordinates(String stationId) {
    return coordinates[stationId];
  }
}
