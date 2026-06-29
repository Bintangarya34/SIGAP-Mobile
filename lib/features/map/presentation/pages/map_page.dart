import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/ref_heights.dart';
import '../../../../core/providers/station_provider.dart';
import '../../../../core/widgets/brutal_card.dart';
import '../../../../core/widgets/brutal_button.dart';
import '../../../../core/services/location_service.dart';
import 'package:google_fonts/google_fonts.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Position? _userPosition;
  bool _isLoadingLocation = true;
  final MapController _mapController = MapController();
  StationMeta? _selectedStation;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final pos = await LocationService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userPosition = pos;
          _isLoadingLocation = false;
        });
        if (pos != null && mounted) {
          _mapController.move(LatLng(pos.latitude, pos.longitude), 13.5);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StationProvider>(context);

    // Default center to Surabaya center if user location not found
    final double centerLat = _userPosition?.latitude ?? -7.288;
    final double centerLng = _userPosition?.longitude ?? 112.78;

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: AppBar(
        backgroundColor: BrutalColors.primary,
        elevation: 0,
        title: Text(
          'PETA MONITOR SENSOR',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.gps_fixed, color: Colors.white),
            onPressed: _fetchUserLocation,
          ),
        ],
      ),
      body: _isLoadingLocation
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: BrutalColors.primary),
                  SizedBox(height: 12.0),
                  Text('Menentukan koordinat GPS Anda...', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : Stack(
              children: [
                // Leaflet Map (flutter_map)
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(centerLat, centerLng),
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.sigap_mobile',
                    ),
                    MarkerLayer(
                      markers: [
                        // User Marker (Blue pulsing dot representation)
                        if (_userPosition != null)
                          Marker(
                            point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                            width: 45.0,
                            height: 45.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.blue, width: 2.0),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person_pin_circle,
                                  color: Colors.blue,
                                  size: 28.0,
                                ),
                              ),
                            ),
                          ),
                        // Sensor Markers with ML prediction overlays
                        ...StationConstants.stations.values.map((meta) {
                          final isSelected = _selectedStation?.key == meta.key;
                          final predictedStatus = provider.allPredictedStatuses[meta.key] ?? "OFFLINE";
                          
                          return Marker(
                            point: LatLng(meta.latitude, meta.longitude),
                            width: 80.0,
                            height: 80.0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedStation = meta;
                                });
                              },
                              child: PulsingSensorMarker(
                                predictedStatus: predictedStatus,
                                isSelected: isSelected,
                                stationName: meta.name,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),

                // Floating Info Panel for Selected Station
                if (_selectedStation != null)
                  Positioned(
                    bottom: 16.0,
                    left: 16.0,
                    right: 16.0,
                    child: _buildStationDetailsCard(_selectedStation!, provider),
                  )
                else if (_userPosition != null)
                  Positioned(
                    bottom: 16.0,
                    left: 16.0,
                    right: 16.0,
                    child: _buildClosestStationPanel(provider),
                  ),
              ],
            ),
    );
  }

  Widget _buildStationDetailsCard(StationMeta meta, StationProvider provider) {
    double distance = 0.0;
    if (_userPosition != null) {
      distance = LocationService.getDistanceInMeters(
        _userPosition!.latitude,
        _userPosition!.longitude,
        meta.latitude,
        meta.longitude,
      );
    }

    final pStatus = provider.allPredictedStatuses[meta.key] ?? "OFFLINE";

    return BrutalCard(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                meta.name.toUpperCase(),
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18.0),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _selectedStation = null),
              ),
            ],
          ),
          const Divider(height: 16, thickness: 1.5, color: BrutalColors.surfaceContainer),
          const SizedBox(height: 4.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Prediksi Status (6H):', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
              Text(
                pStatus,
                style: GoogleFonts.inter(
                  fontSize: 13, 
                  fontWeight: FontWeight.w900, 
                  color: pStatus == 'SIAGA' ? BrutalColors.danger : (pStatus == 'WASPADA' ? BrutalColors.warning : BrutalColors.success)
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Jarak ke stasiun:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
              Text(
                '${(distance / 1000).toStringAsFixed(2)} km',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w900, color: BrutalColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          BrutalButton(
            height: 38.0,
            backgroundColor: BrutalColors.primary,
            onTap: () {
              provider.setActiveStation(meta.key);
              Navigator.pop(context); // Return home to dashboard content
            },
            child: Text(
              'LIHAT MONITOR DATA',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosestStationPanel(StationProvider provider) {
    final closest = LocationService.getClosestStation(_userPosition!.latitude, _userPosition!.longitude);
    final distance = LocationService.getDistanceInMeters(
      _userPosition!.latitude,
      _userPosition!.longitude,
      closest.latitude,
      closest.longitude,
    );

    return BrutalCard(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.near_me, color: BrutalColors.primary, size: 18.0),
              const SizedBox(width: 6.0),
              Text(
                'STASIUN TERDEKAT',
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black),
              ),
            ],
          ),
          const Divider(height: 12, thickness: 1.5, color: BrutalColors.surfaceContainer),
          Text(
            'Stasiun ${closest.name} berjarak ${(distance / 1000).toStringAsFixed(2)} km dari lokasi Anda.',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8.0),
          BrutalButton(
            height: 38.0,
            backgroundColor: BrutalColors.primary,
            onTap: () {
              provider.setActiveStation(closest.key);
              Navigator.pop(context); // Return home to dashboard content
            },
            child: Text(
              'PANTAU STASIUN INI',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// Stateful Marker supporting pulsing warning animations for SIAGA statuses
class PulsingSensorMarker extends StatefulWidget {
  final String predictedStatus;
  final bool isSelected;
  final String stationName;

  const PulsingSensorMarker({
    super.key,
    required this.predictedStatus,
    required this.isSelected,
    required this.stationName,
  });

  @override
  State<PulsingSensorMarker> createState() => _PulsingSensorMarkerState();
}

class _PulsingSensorMarkerState extends State<PulsingSensorMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color pinColor = BrutalColors.primary;
    IconData icon = Icons.settings_input_antenna;
    bool shouldPulse = false;

    switch (widget.predictedStatus.toUpperCase()) {
      case 'SIAGA':
        pinColor = BrutalColors.danger;
        icon = Icons.warning_amber_rounded;
        shouldPulse = true;
        break;
      case 'WASPADA':
        pinColor = BrutalColors.warning;
        icon = Icons.error_outline_rounded;
        break;
      case 'AMAN':
        pinColor = BrutalColors.success;
        icon = Icons.check_circle_outline_rounded;
        break;
      default:
        pinColor = Colors.grey;
        icon = Icons.portable_wifi_off_rounded;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing Ring for SIAGA
            if (shouldPulse)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    width: 36 + (20 * _controller.value),
                    height: 36 + (20 * _controller.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BrutalColors.danger.withValues(alpha: 0.4 * (1 - _controller.value)),
                    ),
                  );
                },
              ),
            // Outer Border
            Container(
              decoration: BoxDecoration(
                color: widget.isSelected ? Colors.yellow : pinColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(2, 2),
                    blurRadius: 4.0,
                  )
                ],
              ),
              padding: const EdgeInsets.all(6.0),
              child: Icon(
                icon,
                color: widget.isSelected && widget.predictedStatus != 'SIAGA' ? Colors.black : Colors.white,
                size: 20.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2.0),
        // Label
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 1.5),
            borderRadius: BorderRadius.circular(4.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
          child: Text(
            widget.stationName,
            style: GoogleFonts.inter(
              fontSize: 9.0,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
