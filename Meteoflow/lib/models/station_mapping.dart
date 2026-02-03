class StationMapping {
  // Station mappings for each collector
  static const Map<String, Map<String, List<String>>> mapping = {
    'Chhabi Thapa': {
      'flow': ['Flow_S406'],
    },
    'Niruta Purbachhane': {
      'rain': ['Index_311050201'],
      'flow': ['Flow_S218', 'Flow_S219'],
    },
    'Menuka Rai': {
      'rain': ['Index_311050601'],
      'flow': ['Flow_S719', 'Flow_S602'],
    },
    'Yuvaraja Shrestha': {
      'rain': ['Index_311060401'],
      'flow': ['Flow_S410'],
    },
    'Muna Kumari Pahadi': {
      'rain': ['Index_311060301'],
      'flow': ['Flow_S306'],
    },
  };

  // List of all collectors
  static const List<String> collectors = [
    'Chhabi Thapa',
    'Niruta Purbachhane',
    'Menuka Rai',
    'Yuvaraja Shrestha',
    'Muna Kumari Pahadi',
  ];

  // Station Metadata for CSV Headers - Spring Monitoring Stations
  static const Map<String, Map<String, String>> metadata = {
    // Spring Monitoring Stations (Flow)
    'Flow_S602': {
      'name': 'Panityanki',
      'region': 'Sindhuli',
      'muni': 'Kamalamai-6',
      'loc': 'Panityanki Spring',
      'lat': '27.213855',
      'lon': '85.924468',
      'alt': '485',
      'type': 'Spring',
    },
    'Flow_S719': {
      'name': 'Bardyautar',
      'region': 'Sindhuli',
      'muni': 'Kamalamai',
      'loc': 'Bardyautar Spring',
      'lat': '27.214045',
      'lon': '85.930664',
      'alt': '471',
      'type': 'Spring',
    },
    'Flow_S218': {
      'name': 'Gwang Khola',
      'region': 'Sindhuli',
      'muni': 'Kamalamai',
      'loc': 'Gwang Khola Spring',
      'lat': '27.257651',
      'lon': '85.947514',
      'alt': '683',
      'type': 'Spring',
    },
    'Flow_S219': {
      'name': 'Simgaun',
      'region': 'Sindhuli',
      'muni': 'Kamalamai',
      'loc': 'Simgaun Spring',
      'lat': '27.2574504758',
      'lon': '85.9477912774',
      'alt': '724',
      'type': 'Spring',
    },
    'Flow_S406': {
      'name': 'Saatpatre',
      'region': 'Sindhuli',
      'muni': 'Kamalamai',
      'loc': 'Saatpatre Spring',
      'lat': '27.251225',
      'lon': '85.912832',
      'alt': '627',
      'type': 'Spring',
    },
    'Flow_S306': {
      'name': 'Kalimati',
      'region': 'Sindhuli',
      'muni': 'Sunkoshi-3',
      'loc': 'Kalimati Spring',
      'lat': '27.403767',
      'lon': '85.872903',
      'alt': '576',
      'type': 'Spring',
    },
    'Flow_S410': {
      'name': 'Deurali (Thulo Khola)',
      'region': 'Sindhuli',
      'muni': 'Sunkoshi',
      'loc': 'Deurali Thulo Khola Spring',
      'lat': '27.361479',
      'lon': '85.847604',
      'alt': '1613',
      'type': 'Spring',
    },

    // Rain Gauge Stations
    'Index_311050201': {
      'name': 'Chiyabari',
      'region': 'Sindhuli',
      'muni': 'Kamalamai-2',
      'loc': 'Personal land (house yard)',
      'lat': '27.250358',
      'lon': '85.937691',
      'alt': '627.5',
      'type': 'Rain Gauge',
    },
    'Index_311050601': {
      'name': 'Panitanki',
      'region': 'Sindhuli',
      'muni': 'Kamalamai-6',
      'loc': 'Government Water tank compound',
      'lat': '27.215199',
      'lon': '85.924586',
      'alt': '506.3',
      'type': 'Rain Gauge',
    },
    'Index_311060401': {
      'name': 'Kotgaun',
      'region': 'Sindhuli',
      'muni': 'Sunkoshi-4',
      'loc': 'Personal House Yard',
      'lat': '27.384385',
      'lon': '85.857803',
      'alt': '1213.2',
      'type': 'Rain Gauge',
    },
    'Index_311060301': {
      'name': 'Kalimati',
      'region': 'Sindhuli',
      'muni': 'Sunkoshi-3',
      'loc': 'Personal House Yard',
      'lat': '27.409330',
      'lon': '85.879965',
      'alt': '695.9',
      'type': 'Rain Gauge',
    },
  };

  // Station coordinates for Map Visualization [lat, lng]
  // Only monitored stations in Sindhuli area
  static const Map<String, List<double>> coordinates = {
    // Spring Monitoring Stations (7)
    'Flow_S602': [27.213855, 85.924468],
    'Flow_S719': [27.214045, 85.930664],
    'Flow_S218': [27.257651, 85.947514],
    'Flow_S219': [27.2574504758, 85.9477912774],
    'Flow_S406': [27.251225, 85.912832],
    'Flow_S306': [27.403767, 85.872903],
    'Flow_S410': [27.361479, 85.847604],

    // Rain Gauge Stations (4)
    'Index_311050201': [27.250358, 85.937691],
    'Index_311050601': [27.215199, 85.924586],
    'Index_311060401': [27.384385, 85.857803],
    'Index_311060301': [27.409330, 85.879965],
  };

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
    final list = stations.toList()..sort();
    return list;
  }

  // Get all flow stations (for CSV export)
  static List<String> getAllFlowStations() {
    final stations = <String>{};
    for (var collectorMap in mapping.values) {
      if (collectorMap['flow'] != null) {
        stations.addAll(collectorMap['flow']!);
      }
    }
    final list = stations.toList()..sort();
    return list;
  }

  static List<double>? getCoordinates(String stationId) {
    return coordinates[stationId];
  }

  // Get station display name
  static String getStationName(String stationId) {
    return metadata[stationId]?['name'] ?? stationId;
  }

  // Get station type (Spring or Rain Gauge)
  static String getStationType(String stationId) {
    return metadata[stationId]?['type'] ?? 'Unknown';
  }
}
