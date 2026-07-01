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
      name: 'Kalikobor',
      lokasiId: 3,
      refHeight: 545.0,
      waspadaThreshold: 120.0,
      siagaThreshold: 150.0,
      latitude: -7.2850000,
      longitude: 112.802806,
    ),
    'lokasi2': StationMeta(
      key: 'lokasi2',
      name: 'UHT',
      lokasiId: 2,
      refHeight: 466.0,
      waspadaThreshold: 316.0, // 466 - 150 (Height Waspada 150 cm)
      siagaThreshold: 276.0,   // 466 - 190 (Height Siaga 190 cm)
      latitude: -7.2907778,
      longitude: 112.793278,
    ),
    'lokasi3': StationMeta(
      key: 'lokasi3',
      name: 'Pucanganom',
      lokasiId: 1,
      refHeight: 366.01,
      waspadaThreshold: 110.0,
      siagaThreshold: 130.0,
      latitude: -7.2869071,
      longitude: 112.7556923,
    ),
  };
}
