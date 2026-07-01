import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/ref_heights.dart';
import '../../../../core/providers/station_provider.dart';
import '../../../../core/widgets/brutal_card.dart';
import '../../../../core/widgets/brutal_button.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../analitik/presentation/pages/analitik_page.dart';
import '../../../map/presentation/pages/map_page.dart';
import '../../../laporan/presentation/pages/lapor_banjir_page.dart';

// Shell container to handle seamless Tab switches via IndexedStack
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentTab = 0;

  final List<Widget> _pages = [
    const DashboardHomeContent(),
    const AnalitikPage(),
    const MapPage(),
    const LaporBanjirPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: BrutalColors.border, width: 2.5),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: _currentTab,
          type: BottomNavigationBarType.fixed, // Prevent shifting on 4 items
          selectedItemColor: BrutalColors.primary,
          unselectedItemColor: Colors.black54,
          selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11),
          onTap: (index) {
            setState(() {
              _currentTab = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.ssid_chart),
              label: 'Prediction',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.warning_amber),
              label: 'Alert',
            ),
          ],
        ),
      ),
    );
  }
}

// Inner Widget containing the actual Home content
class DashboardHomeContent extends StatefulWidget {
  const DashboardHomeContent({super.key});

  @override
  State<DashboardHomeContent> createState() => _DashboardHomeContentState();
}

class _DashboardHomeContentState extends State<DashboardHomeContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StationProvider>(context, listen: false).fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: AppBar(
        backgroundColor: BrutalColors.primary,
        elevation: 0,
        title: Text(
          'SIGAP-Banjir',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: () {
              Provider.of<StationProvider>(context, listen: false)
                  .switchToClosestStation();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              Provider.of<StationProvider>(context, listen: false).fetchData();
            },
          ),
        ],
      ),
      body: Consumer<StationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: BrutalColors.primary),
            );
          }

          final station = provider.activeStation;
          final sensorList = provider.sensorData;
          
          // Parse latest record details
          Map<String, dynamic>? latest;
          Map<String, dynamic>? oldest;
          if (sensorList.isNotEmpty) {
            latest = Map<String, dynamic>.from(sensorList.first as Map);
            oldest = Map<String, dynamic>.from(sensorList.last as Map);
          }

          double? distance;
          double? oldestDistance;
          double tinggiAir = 0.0;
          double oldestTinggiAir = 0.0;
          String status = "OFFLINE";
          double d1 = 0.0;
          double d2 = 0.0;

          if (latest != null) {
            d1 = double.tryParse(latest['distance1']?.toString() ?? '') ?? 0.0;
            d2 = double.tryParse(latest['distance2']?.toString() ?? '') ?? 0.0;

            // Handle oldest for trend calculation
            if (oldest != null) {
              final od1 = double.tryParse(oldest['distance1']?.toString() ?? '') ?? 0.0;
              final od2 = double.tryParse(oldest['distance2']?.toString() ?? '') ?? 0.0;
              if (station.key == 'lokasi1') { // Kalikobor (swapped key)
                if (od2 > 10 && od2 < 600) {
                  oldestDistance = od2;
                } else if (od1 > 10 && od1 < 600) oldestDistance = od1;
              } else { // Pucanganom (lokasi3) & UHT (lokasi2)
                if (od1 > 10 && od1 < 600) {
                  oldestDistance = od1;
                } else if (od2 > 10 && od2 < 600) oldestDistance = od2;
              }
              if (oldestDistance != null) {
                oldestTinggiAir = station.refHeight - oldestDistance;
              }
            }

            if (station.key == 'lokasi1') { // Kalikobor (swapped key)
              if (d2 > 10 && d2 < 600) {
                distance = d2;
              } else if (d1 > 10 && d1 < 600) {
                distance = d1;
              }
            } else { // Pucanganom (lokasi3) & UHT (lokasi2)
              if (d1 > 10 && d1 < 600) {
                distance = d1;
              } else if (d2 > 10 && d2 < 600) {
                distance = d2;
              }
            }

            // Check if telemetry timestamp is fresh (offline if older than 60 minutes)
            if (latest['waktu'] != null) {
              try {
                final DateTime dataTime = DateTime.parse(latest['waktu'].toString());
                final DateTime now = DateTime.now();
                final int diffMinutes = now.difference(dataTime).inMinutes.abs();
                if (diffMinutes > 60) {
                  distance = null; // Force offline
                }
              } catch (_) {}
            }

            if (distance != null) {
              tinggiAir = station.refHeight - distance;
              tinggiAir = tinggiAir < 0 ? 0 : tinggiAir;

              double waspadaH = station.refHeight - station.waspadaThreshold;
              double siagaH = station.refHeight - station.siagaThreshold;

              if (station.lokasiId == 2) { // UHT
                waspadaH = 150.0;
                siagaH = 190.0;
              }

              if (tinggiAir >= siagaH) {
                status = "SIAGA";
              } else if (tinggiAir >= waspadaH) {
                status = "WASPADA";
              } else {
                status = "AMAN";
              }
            } else {
              status = "OFFLINE";
            }
          }

          // Calculate trend from oldest in current window
          double trendDiff = tinggiAir - oldestTinggiAir;
          String trendSign = trendDiff >= 0 ? "+" : "";
          String trendStr = "$trendSign${trendDiff.toStringAsFixed(1)} cm dari beberapa menit lalu";

          return RefreshIndicator(
            onRefresh: () => provider.fetchData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Select Location Label
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                    child: Text(
                      'Select Location',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  // Location Selector
                  Row(
                    children: StationConstants.stations.keys.map((key) {
                      final meta = StationConstants.stations[key]!;
                      final isActive = provider.activeStationKey == key;
                      
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: BrutalButton(
                            height: 38.0,
                            backgroundColor: isActive ? BrutalColors.primary : BrutalColors.cardBg,
                            onTap: () => provider.setActiveStation(key),
                            child: Text(
                              meta.name.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isActive ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20.0),

                  // Proximity Alert Banner
                  if (provider.distanceToUser != null) ...[
                    BrutalCard(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: BrutalColors.primary),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              'Jarak Anda: ${(provider.distanceToUser! / 1000).toStringAsFixed(2)} km dari stasiun ini',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Current Status Card
                  BrutalCard(
                    backgroundColor: status == "AMAN" ? BrutalColors.primary : (status == "WASPADA" ? BrutalColors.warning : BrutalColors.danger),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Status'.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            status,
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Water Level Card
                  BrutalCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Water Level'.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          distance != null ? '${tinggiAir.toStringAsFixed(1)} cm' : '--- cm',
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          distance != null ? trendStr : '+/- --- cm from 1h ago',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const Divider(height: 24, thickness: 1.5, color: BrutalColors.surfaceContainer),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Distance 1', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 12)),
                                const SizedBox(height: 2.0),
                                Text(d1 > 0 ? '${d1.toStringAsFixed(1)} cm' : '-', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Distance 2', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 12)),
                                const SizedBox(height: 2.0),
                                Text(d2 > 0 ? '${d2.toStringAsFixed(1)} cm' : '-', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Param Header
                  Text(
                    'Location Sensors'.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8.0),

                  // Param Grid
                  _buildGauges(station.lokasiId, latest),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGauges(int lokasiId, Map<String, dynamic>? latest) {
    if (latest == null) {
      return BrutalCard(
        child: Text(
          'Tidak ada data sensor tambahan.',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      );
    }

    if (lokasiId == 2) {
      // UHT: Weather (Temp, Humi, Rain, Baro)
      final temp = double.tryParse(latest['temp']?.toString() ?? '') ?? 0.0;
      final humi = double.tryParse(latest['humi']?.toString() ?? '') ?? 0.0;
      final rain = double.tryParse(latest['curah_hujan']?.toString() ?? '') ?? 0.0;
      final baro = double.tryParse(latest['baro']?.toString() ?? '') ?? 0.0;

      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          _buildMiniGauge('Temperature', '${temp.toStringAsFixed(1)} °C', temp / 50, Colors.pinkAccent),
          _buildMiniGauge('Humidity', '${humi.toStringAsFixed(1)} %', humi / 100, Colors.cyan),
          _buildMiniGauge('Rainfall', '${rain.toStringAsFixed(1)} mm', rain / 30, Colors.lightBlue),
          _buildMiniGauge('Air Pressure', baro > 0 ? '${baro.toStringAsFixed(0)} hPa' : '-', baro > 0 ? (baro - 900) / 200 : 0, Colors.amber),
        ],
      );
    } else if (lokasiId == 1) {
      // Pucanganom: Rainfall
      final rain = double.tryParse(latest['curah_hujan_1h']?.toString() ?? '') ?? 0.0;
      final tip = int.tryParse(latest['jumlah_tip']?.toString() ?? '') ?? 0;

      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          _buildMiniGauge('Rainfall 1h', '${rain.toStringAsFixed(1)} mm', rain / 30, Colors.cyan),
          _buildMiniGauge('Jumlah Tip', '$tip', tip / 50, Colors.pinkAccent),
        ],
      );
    } else {
      // Kalikobor: Sensor Jarak
      final d1 = double.tryParse(latest['distance1']?.toString() ?? '') ?? 0.0;
      final d2 = double.tryParse(latest['distance2']?.toString() ?? '') ?? 0.0;

      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          _buildMiniGauge('Distance 1', d1 > 0 ? '${d1.toStringAsFixed(0)} cm' : 'OFFLINE', d1 > 0 ? d1 / 600 : 0, Colors.pinkAccent),
          _buildMiniGauge('Distance 2', d2 > 0 ? '${d2.toStringAsFixed(0)} cm' : 'OFFLINE', d2 > 0 ? d2 / 600 : 0, Colors.cyan),
        ],
      );
    }
  }

  Widget _buildMiniGauge(String label, String value, double percent, Color fillCol) {
    final capPercent = percent.clamp(0.0, 1.0);
    return BrutalCard(
      padding: const EdgeInsets.all(12.0),
      child: Stack(
        children: [
          // Gauge Progress Fill from bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60 * capPercent,
            child: Container(
              color: fillCol.withValues(alpha: 0.15),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
