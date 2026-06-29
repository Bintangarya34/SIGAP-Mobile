class StationMeta {
  final String key;
  final String name;
  final int lokasiId;
  final double refHeight;
  final double waspadaThreshold;
  final double siagaThreshold;
  final double latitude;
  final double longitude;

  StationMeta({
    required this.key,
    required this.name,
    required this.lokasiId,
    required this.refHeight,
    required this.waspadaThreshold,
    required this.siagaThreshold,
    required this.latitude,
    required this.longitude,
  });
}

class StationConstants {
  static final Map<String, StationMeta> stations = {
    'lokasi1': StationMeta(
      key: 'lokasi1',
      name: 'Pucanganom',
      lokasiId: 1,
      refHeight: 366.01,
      waspadaThreshold: 110.0,
      siagaThreshold: 130.0,
      latitude: -7.28498,
      longitude: 112.802923,
    ),
    'lokasi2': StationMeta(
      key: 'lokasi2',
      name: 'UHT',
      lokasiId: 2,
      refHeight: 466.0,
      waspadaThreshold: 250.0,
      siagaThreshold: 285.0,
      latitude: -7.290753,
      longitude: 112.793255,
    ),
    'lokasi3': StationMeta(
      key: 'lokasi3',
      name: 'Kalikobor',
      lokasiId: 3,
      refHeight: 545.0,
      waspadaThreshold: 120.0,
      siagaThreshold: 150.0,
      latitude: -7.286943,
      longitude: 112.755689,
    ),
  };
}
