class Collector {
  final String id;
  final String name;
  final List<String> rainStations;
  final List<String> flowStations;

  Collector({
    required this.id,
    required this.name,
    required this.rainStations,
    required this.flowStations,
  });

  factory Collector.fromFirestore(String id, Map<String, dynamic> data) {
    return Collector(
      id: id,
      name: data['name'] ?? '',
      rainStations: List<String>.from(data['rain'] ?? []),
      flowStations: List<String>.from(data['flow'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'name': name, 'rain': rainStations, 'flow': flowStations};
  }

  Collector copyWith({
    String? name,
    List<String>? rainStations,
    List<String>? flowStations,
  }) {
    return Collector(
      id: id,
      name: name ?? this.name,
      rainStations: rainStations ?? this.rainStations,
      flowStations: flowStations ?? this.flowStations,
    );
  }
}
