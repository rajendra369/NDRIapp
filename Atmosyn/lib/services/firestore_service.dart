import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/data_record.dart';
import '../models/collector.dart';
import '../models/station_mapping.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'records';

  // Save or update a record (upsert with merge)
  Future<void> saveRecord(DataRecord record) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(record.documentId)
          .set(record.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save record: $e');
    }
  }

  // Clear all records
  Future<void> clearAllRecords() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear records: $e');
    }
  }

  // Get all records as a stream (real-time updates)
  Stream<List<DataRecord>> getRecordsStream() {
    return _firestore.collection(_collectionName).snapshots().map((snapshot) {
      final records = snapshot.docs
          .map((doc) => DataRecord.fromJson(doc.data()))
          .toList();

      // Sort by date descending (newest first)
      records.sort((a, b) => b.date.compareTo(a.date));

      return records;
    });
  }

  // Get all records once (for CSV export)
  Future<List<DataRecord>> getAllRecords() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      final records = snapshot.docs
          .map((doc) => DataRecord.fromJson(doc.data()))
          .toList();

      // Sort by date ascending (for CSV)
      records.sort((a, b) => a.date.compareTo(b.date));

      return records;
    } catch (e) {
      throw Exception('Failed to fetch records: $e');
    }
  }

  // Delete a record (optional feature)
  Future<void> deleteRecord(String documentId) async {
    try {
      await _firestore.collection(_collectionName).doc(documentId).delete();
    } catch (e) {
      throw Exception('Failed to delete record: $e');
    }
  }

  // Get record count
  Future<int> getRecordCount() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get record count: $e');
    }
  }

  // --- Collector Management ---

  final String _collectorsCollection = 'collectors';

  // Get collectors stream (returns List<Collector> objects)
  Stream<List<Collector>> getCollectorsStream() {
    return _firestore
        .collection(_collectorsCollection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Collector.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }

  // Add a new collector (initially empty stations)
  Future<void> addCollector(String name) async {
    try {
      final collector = Collector(
        id: '',
        name: name,
        rainStations: [],
        flowStations: [],
      );
      await _firestore
          .collection(_collectorsCollection)
          .add(collector.toFirestore());
    } catch (e) {
      throw Exception('Failed to add collector: $e');
    }
  }

  // Update a collector (stations etc.)
  Future<void> updateCollector(Collector collector) async {
    try {
      await _firestore
          .collection(_collectorsCollection)
          .doc(collector.id)
          .update(collector.toFirestore());
    } catch (e) {
      throw Exception('Failed to update collector: $e');
    }
  }

  // Remove a collector
  Future<void> removeCollector(String id) async {
    try {
      await _firestore.collection(_collectorsCollection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to remove collector: $e');
    }
  }

  // Seed default collectors and their stations if missing
  Future<void> seedDefaultCollectors() async {
    try {
      final snapshot = await _firestore.collection(_collectorsCollection).get();
      final existingNames = snapshot.docs
          .map((doc) => doc.data()['name'] as String)
          .toSet();

      final mapping = StationMapping.mapping;

      // Add missing mappings
      for (final entry in mapping.entries) {
        final name = entry.key;
        if (!existingNames.contains(name)) {
          final stations = entry.value;
          final rain = stations['rain'] ?? [];
          final flow = stations['flow'] ?? [];

          await _firestore.collection(_collectorsCollection).add({
            'name': name,
            'rain': rain,
            'flow': flow,
          });
          debugPrint('Seeded default collector: $name');
        }
      }

      // Add any names from the simple list that weren't in the mapping map
      for (final name in StationMapping.collectors) {
        if (!existingNames.contains(name) && !mapping.containsKey(name)) {
          await _firestore.collection(_collectorsCollection).add({
            'name': name,
            'rain': [],
            'flow': [],
          });
          debugPrint('Seeded default empty collector: $name');
        }
      }
    } catch (e) {
      debugPrint('Seeding error: $e');
    }
  }
}
