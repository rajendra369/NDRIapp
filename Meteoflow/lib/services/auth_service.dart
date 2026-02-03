import '../models/station_mapping.dart';

/// Simple local authentication service for collectors
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Current logged-in collector
  String? _currentCollector;

  // Pre-defined collector credentials (collector name -> password)
  static const Map<String, String> _credentials = {
    'Chhabi Thapa': 'chhabi123',
    'Niruta Purbachhane': 'niruta123',
    'Menuka Rai': 'menuka123',
    'Yuvaraja Shrestha': 'yuvaraja123',
    'Muna Kumari Pahadi': 'muna123',
  };

  // Admin credentials
  static const String _adminUsername = 'admin';
  static const String _adminPassword = 'admin123';

  /// Get list of all collectors
  List<String> get collectors => StationMapping.collectors;

  /// Get current logged-in collector
  String? get currentCollector => _currentCollector;

  /// Check if user is logged in
  bool get isLoggedIn => _currentCollector != null;

  /// Attempt to login as a collector
  /// Returns true if successful, false otherwise
  bool loginAsCollector(String collector, String password) {
    final storedPassword = _credentials[collector];
    if (storedPassword != null && storedPassword == password) {
      _currentCollector = collector;
      return true;
    }
    return false;
  }

  /// Attempt to login as admin
  /// Returns true if successful, false otherwise
  bool loginAsAdmin(String username, String password) {
    if (username == _adminUsername && password == _adminPassword) {
      _currentCollector = 'Admin';
      return true;
    }
    return false;
  }

  /// Logout current user
  void logout() {
    _currentCollector = null;
  }

  /// Check if current user is admin
  bool get isAdmin => _currentCollector == 'Admin';
}
