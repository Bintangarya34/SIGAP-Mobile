import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String _sensorBoxName = 'sensor_data';
  static const String _predictionBoxName = 'prediction_data';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_sensorBoxName);
    await Hive.openBox(_predictionBoxName);
  }

  static Future<void> cacheSensorData(String stationKey, List<dynamic> data) async {
    final box = Hive.box(_sensorBoxName);
    await box.put(stationKey, data);
  }

  static List<dynamic>? getCachedSensorData(String stationKey) {
    final box = Hive.box(_sensorBoxName);
    return box.get(stationKey) as List<dynamic>?;
  }

  static Future<void> cachePredictionData(String stationKey, Map<String, dynamic> data) async {
    final box = Hive.box(_predictionBoxName);
    await box.put(stationKey, data);
  }

  static Map<String, dynamic>? getCachedPredictionData(String stationKey) {
    final box = Hive.box(_predictionBoxName);
    final raw = box.get(stationKey);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  static Future<void> clearCache() async {
    await Hive.box(_sensorBoxName).clear();
    await Hive.box(_predictionBoxName).clear();
  }
}
