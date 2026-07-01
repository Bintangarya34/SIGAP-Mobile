import 'package:geolocator/geolocator.dart';

class StationLocation {
  final String key;
  final String name;
  final double latitude;
  final double longitude;

  StationLocation({
    required this.key,
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  static final List<StationLocation> stations = [
    StationLocation(key: "lokasi1", name: "Kalikobor", latitude: -7.2850000, longitude: 112.802806),
    StationLocation(key: "lokasi2", name: "UHT", latitude: -7.2907778, longitude: 112.793278),
    StationLocation(key: "lokasi3", name: "Pucanganom", latitude: -7.2869071, longitude: 112.7556923),
  ];

  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return null;
    } 

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (_) {
      return null;
    }
  }

  static double getDistanceInMeters(double userLat, double userLng, double stationLat, double stationLng) {
    return Geolocator.distanceBetween(userLat, userLng, stationLat, stationLng);
  }

  static StationLocation getClosestStation(double userLat, double userLng) {
    StationLocation closest = stations.first;
    double minDistance = getDistanceInMeters(userLat, userLng, closest.latitude, closest.longitude);

    for (var station in stations.skip(1)) {
      double distance = getDistanceInMeters(userLat, userLng, station.latitude, station.longitude);
      if (distance < minDistance) {
        minDistance = distance;
        closest = station;
      }
    }

    return closest;
  }
}
