import 'package:flutter/material.dart';
import '../constants/ref_heights.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/cache_service.dart';

class StationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  String _activeStationKey = 'lokasi2'; // Default UHT (prediction-optimized location)
  String get activeStationKey => _activeStationKey;

  // Storing data for all stations to allow global access (e.g. on the map)
  final Map<String, List<dynamic>> _allSensorData = {};
  final Map<String, Map<String, dynamic>> _allPredictionData = {};
  final Map<String, Map<String, dynamic>> _allComparisonData = {};
  final Map<String, String> _stationStatuses = {};
  final Map<String, String> _predictedStatuses = {};

  List<dynamic> get sensorData => _allSensorData[_activeStationKey] ?? [];
  Map<String, dynamic>? get predictionData => _allPredictionData[_activeStationKey];
  Map<String, dynamic>? get comparisonData => _allComparisonData[_activeStationKey];
  String get status => _stationStatuses[_activeStationKey] ?? "OFFLINE";

  Map<String, String> get allStationStatuses => _stationStatuses;
  Map<String, String> get allPredictedStatuses => _predictedStatuses;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  double? _distanceToUser;
  double? get distanceToUser => _distanceToUser;

  StationMeta get activeStation => StationConstants.stations[_activeStationKey]!;

  void setActiveStation(String key) {
    if (_activeStationKey == key) return;
    _activeStationKey = key;
    notifyListeners();
    // Quickly update user proximity and notify listeners
    updateProximity();
  }

  Future<void> fetchData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Concurrently fetch data for all 3 stations for map overlay performance
      await Future.wait(
        StationConstants.stations.keys.map((key) => _fetchStationData(key))
      );
      _isOffline = false;
    } catch (e) {
      _isOffline = true;
      _errorMessage = "Memuat data offline dari memori.";
    }

    // Update user proximity
    try {
      await updateProximity();
    } catch (e) {
      _distanceToUser = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchStationData(String key) async {
    final meta = StationConstants.stations[key]!;
    
    // 1. Fetch sensor data
    List<dynamic> sData = [];
    try {
      sData = await _apiService.getSensorData(key, meta.lokasiId);
      _allSensorData[key] = sData;
    } catch (_) {
      // Fetch fallback from cache
      sData = CacheService.getCachedSensorData(key) ?? [];
      _allSensorData[key] = sData;
    }

    // 2. Fetch Prediction
    Map<String, dynamic>? pData;
    try {
      pData = await _apiService.getPredictionData(key, meta.lokasiId);
      _allPredictionData[key] = pData ?? {};
    } catch (_) {
      pData = CacheService.getCachedPredictionData(key);
      _allPredictionData[key] = pData ?? {};
    }

    // 3. Fetch Comparison metrics
    Map<String, dynamic>? cData;
    try {
      cData = await _apiService.getComparisonData(key, meta.lokasiId);
      _allComparisonData[key] = cData ?? {};
    } catch (_) {
      _allComparisonData[key] = {};
    }

    // 4. Process status
    String currentStatus = "OFFLINE";
    if (sData.isNotEmpty) {
      final latest = Map<String, dynamic>.from(sData.first as Map);
      final d1 = double.tryParse(latest['distance1']?.toString() ?? '') ?? 0.0;
      final d2 = double.tryParse(latest['distance2']?.toString() ?? '') ?? 0.0;
      double? dist;

      if (key == 'lokasi3') {
        if (d2 > 10 && d2 < 600) dist = d2;
        else if (d1 > 10 && d1 < 600) dist = d1;
      } else {
        if (d1 > 10 && d1 < 600) dist = d1;
        else if (d2 > 10 && d2 < 600) dist = d2;
      }

      if (dist != null) {
        final tAir = meta.refHeight - dist;
        if (tAir >= meta.siagaThreshold) {
          currentStatus = "SIAGA";
        } else if (tAir >= meta.waspadaThreshold) {
          currentStatus = "WASPADA";
        } else {
          currentStatus = "AMAN";
        }
      } else {
        currentStatus = "GLITCH";
      }
    }
    
    final String? previousStatus = _stationStatuses[key];
    _stationStatuses[key] = currentStatus;

    // Trigger local push notification on SIAGA transition for the active station
    if (key == _activeStationKey && currentStatus == "SIAGA" && previousStatus != "SIAGA") {
      NotificationService.showNotification(
        id: 101,
        title: "⚠️ PERINGATAN SIAGA BANJIR!",
        body: "Stasiun ${meta.name} mendeteksi ketinggian air kritis (SIAGA). Harap waspada!",
      );
    }

    // 5. Process predicted status (using the 6H forecast for warning overlays)
    String predictedStatus = currentStatus;
    if (pData != null && pData['prediksi'] != null) {
      final forecast = pData['prediksi']['6'] ?? {}; // check 6H horizon
      predictedStatus = forecast['status'] ?? currentStatus;
    }
    _predictedStatuses[key] = predictedStatus;
  }

  Future<void> updateProximity() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      if (pos != null) {
        _distanceToUser = LocationService.getDistanceInMeters(
          pos.latitude,
          pos.longitude,
          activeStation.latitude,
          activeStation.longitude,
        );
      } else {
        _distanceToUser = null;
      }
    } catch (e) {
      _distanceToUser = null;
    }
    notifyListeners();
  }

  Future<void> switchToClosestStation() async {
    _isLoading = true;
    notifyListeners();

    final pos = await LocationService.getCurrentPosition();
    if (pos != null) {
      final closest = LocationService.getClosestStation(pos.latitude, pos.longitude);
      _activeStationKey = closest.key;
      await fetchData();
    } else {
      _errorMessage = "GPS tidak aktif atau izin ditolak.";
      _isLoading = false;
      notifyListeners();
    }
  }
}
