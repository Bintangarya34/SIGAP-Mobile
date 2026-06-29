import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'cache_service.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://sigap-banjir-2-production.up.railway.app',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<List<dynamic>> getSensorData(String stationKey, int lokasiId) async {
    try {
      final response = await _dio.get('/api/sensor', queryParameters: {'lokasi': lokasiId});
      if (response.statusCode == 200 && response.data['status'] == 'ok') {
        final List<dynamic> list = response.data['data'] ?? [];
        // Cache data for offline usage
        await CacheService.cacheSensorData(stationKey, list);
        return list;
      }
      throw Exception('Gagal memuat data dari server');
    } catch (e) {
      // Fallback to cache if offline
      final cached = CacheService.getCachedSensorData(stationKey);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPredictionData(String stationKey, int lokasiId) async {
    try {
      final response = await _dio.get('/api/prediksi', queryParameters: {'lokasi': lokasiId});
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
        // Cache data for offline usage
        await CacheService.cachePredictionData(stationKey, data);
        return data;
      }
      throw Exception('Gagal memuat data prediksi');
    } catch (e) {
      // Fallback to cache if offline
      final cached = CacheService.getCachedPredictionData(stationKey);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  Future<bool> uploadFloodReport({
    required double latitude,
    required double longitude,
    required String comment,
    required String? imagePath,
  }) async {
    try {
      String? base64Image;
      if (imagePath != null && imagePath != "simulated_photo.jpg") {
        // Read file bytes and encode to base64
        final bytes = await File(imagePath).readAsBytes();
        base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } else if (imagePath == "simulated_photo.jpg") {
        // For simulator, generate a small dummy red dot image base64
        base64Image = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA=';
      }

      final response = await _dio.post('/api/laporan', data: {
        'lat': latitude,
        'lng': longitude,
        'catatan': comment,
        if (base64Image != null) 'fotoBase64': base64Image,
      });

      return response.statusCode == 200 && response.data['status'] == 'ok';
    } catch (e) {
      print("Upload error: $e");
      return false;
    }
  }

  Future<List<dynamic>> getFloodReports() async {
    try {
      final response = await _dio.get('/api/laporan');
      if (response.statusCode == 200 && response.data['status'] == 'ok') {
        return response.data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Fetch reports error: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getComparisonData(String stationKey, int lokasiId) async {
    try {
      final response = await _dio.get('/api/perbandingan', queryParameters: {'lokasi': lokasiId});
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (e) {
      print("Get comparison error: $e");
      return null;
    }
  }
}
