import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/providers/station_provider.dart';
import '../../../../core/widgets/brutal_card.dart';
import '../../../../core/widgets/brutal_button.dart';
import 'package:google_fonts/google_fonts.dart';

class AnalitikPage extends StatefulWidget {
  const AnalitikPage({super.key});

  @override
  State<AnalitikPage> createState() => _AnalitikPageState();
}

class _AnalitikPageState extends State<AnalitikPage> {
  String _activeHorizon = "6"; // Default 6H

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: AppBar(
        backgroundColor: BrutalColors.primary,
        elevation: 0,
        title: Text(
          'ANALITIK ML',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: Consumer<StationProvider>(
        builder: (context, provider, child) {
          final station = provider.activeStation;
          final pred = provider.predictionData;
          final isClassification = dataTipe(pred) == "klasifikasi";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                BrutalCard(
                  backgroundColor: BrutalColors.secondary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        isClassification
                            ? 'Model: Klasifikasi Status (Real-time)'
                            : 'Model: Multi-Horizon Forecasting (AI)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),

                if (isClassification) ...[
                  // Classification display for Pucanganom
                  BrutalCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STATUS KLASIFIKASI'.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          pred?['sekarang']?['status'] ?? 'OFFLINE',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: BrutalColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        const Divider(thickness: 1.5, color: BrutalColors.border),
                        const SizedBox(height: 4.0),
                        Text(
                          'Catatan: Lokasi ini adalah rumah pompa dengan data terbatas. AI hanya mengklasifikasikan status saat ini (tidak ada peramalan waktu).',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Forecast displays UHT & Kalikobor
                  Text(
                    'Pilih Horizon Waktu'.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8.0),
                  
                  // Horizon Selector Buttons
                  Row(
                    children: ["1", "3", "6", "12", "24"].map((h) {
                      final isActive = _activeHorizon == h;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: BrutalButton(
                            height: 38.0,
                            backgroundColor: isActive ? BrutalColors.primary : BrutalColors.cardBg,
                            onTap: () => setState(() => _activeHorizon = h),
                            child: Text(
                              '${h}H',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isActive ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20.0),

                  // Prediction Details Card
                  _buildHorizonDetailsCard(pred, _activeHorizon),
                  const SizedBox(height: 20.0),

                  // Model Evaluation Card (New web-based update)
                  _buildModelEvaluationCard(provider.comparisonData),
                  const SizedBox(height: 20.0),

                  // Forecast Visual Bars (7 history + 5 predictions)
                  Text(
                    'Grafik Tinggi Air & Prediksi (cm)'.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8.0),
                  _buildForecastBarsWidget(pred, provider.sensorData),
                ],
                if (provider.distanceToUser != null) ...[
                  const SizedBox(height: 16.0),
                  BrutalCard(
                    backgroundColor: Colors.white,
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: BrutalColors.primary),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            'Jarak ke stasiun ini: ${(provider.distanceToUser! / 1000).toStringAsFixed(2)} km dari Anda',
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
                const SizedBox(height: 24.0),
              ],
            ),
          );
        },
      ),
    );
  }

  String dataTipe(Map<String, dynamic>? pred) {
    if (pred == null) return "unknown";
    return pred['tipe'] ?? 'unknown';
  }

  Widget _buildHorizonDetailsCard(Map<String, dynamic>? pred, String h) {
    final predictions = pred?['prediksi'] ?? {};
    final hPred = predictions[h] ?? {};
    
    final tka = hPred['tinggi_air_cm'] != null ? '${hPred['tinggi_air_cm']} cm' : '-';
    final status = hPred['status'] ?? '-';
    final conf = hPred['confidence'] != null ? '${(hPred['confidence'] * 100).round()}% setuju' : '-';
    final keandalan = hPred['keandalan'] ?? '-';

    return BrutalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Prediksi $h Jam ke Depan'.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          const Divider(thickness: 1.5, color: BrutalColors.border),
          const SizedBox(height: 8.0),
          _buildDetailRow('Tinggi Air Perkiraan:', tka, isBoldValue: true),
          const SizedBox(height: 8.0),
          _buildDetailRow('Status Perkiraan:', status.toUpperCase(), colorValue: status == 'SIAGA' ? BrutalColors.primary : Colors.black),
          const SizedBox(height: 8.0),
          _buildDetailRow('Confidence AI:', conf),
          const SizedBox(height: 8.0),
          _buildDetailRow('Tingkat Keandalan:', keandalan.toUpperCase(), colorValue: keandalan == 'andal' ? Colors.green : Colors.blue),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBoldValue = false, Color? colorValue}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isBoldValue ? FontWeight.w900 : FontWeight.bold,
            color: colorValue ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildForecastBarsWidget(Map<String, dynamic>? pred, List<dynamic> sensorList) {
    // Collect 7 history values and 5 prediction values
    List<double> heights = [];
    List<bool> isPrediction = [];
    List<String> statuses = [];

    // 1. History
    final history = pred?['histori'] as List<dynamic>? ?? [];
    for (int i = 0; i < 7; i++) {
      if (i < history.length) {
        final hPoint = history[i];
        final val = double.tryParse(hPoint['tinggi_air_cm']?.toString() ?? '') ?? 0.0;
        heights.add(val);
        statuses.add(hPoint['status'] ?? 'AMAN');
        isPrediction.add(false);
      } else {
        heights.add(10.0);
        statuses.add('AMAN');
        isPrediction.add(false);
      }
    }

    // 2. Predictions
    final predictions = pred?['prediksi'] ?? {};
    final horizons = ["1", "3", "6", "12", "24"];
    for (var h in horizons) {
      final pPoint = predictions[h] ?? {};
      final val = double.tryParse(pPoint['tinggi_air_cm']?.toString() ?? '') ?? 0.0;
      heights.add(val);
      statuses.add(pPoint['status'] ?? 'AMAN');
      isPrediction.add(true);
    }

    // Max height for normalization
    double maxVal = heights.fold(100.0, (m, element) => element > m ? element : m);

    return BrutalCard(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(heights.length, (idx) {
                final h = heights[idx];
                final isPred = isPrediction[idx];
                final status = statuses[idx];
                
                final normalizedHeight = (h / maxVal * 120).clamp(10.0, 140.0);
                
                Color barColor = BrutalColors.primary;
                if (status == 'SIAGA') {
                  barColor = BrutalColors.primary;
                } else if (status == 'WASPADA') {
                  barColor = BrutalColors.warning;
                } else {
                  barColor = isPred ? BrutalColors.secondary : Colors.grey.shade400;
                }

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Tooltip(
                      message: '${h.toStringAsFixed(1)} cm\n(${isPred ? 'Prediksi' : 'Histori'})',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: normalizedHeight,
                            decoration: BoxDecoration(
                              color: barColor,
                              border: Border.all(color: BrutalColors.border, width: 1.5),
                              boxShadow: isPred ? [
                                const BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(1, 1),
                                  blurRadius: 0,
                                )
                              ] : null,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            isPred ? '${horizons[idx - 7]}H' : '-${7 - idx}j',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: isPred ? BrutalColors.primary : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const Divider(height: 24, thickness: 1.5, color: BrutalColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Histori', Colors.grey.shade400),
              _buildLegendItem('Prediksi', BrutalColors.secondary),
              _buildLegendItem('Siaga/Bahaya', BrutalColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: BrutalColors.border, width: 1.0),
          ),
        ),
        const SizedBox(width: 4.0),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildModelEvaluationCard(Map<String, dynamic>? comparisonData) {
    if (comparisonData == null || comparisonData.isEmpty) {
      return BrutalCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evaluasi Ketepatan Model AI'.toUpperCase(),
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
            ),
            const Divider(thickness: 1.5, color: BrutalColors.border),
            const SizedBox(height: 8.0),
            Text('Mengambil data metrik ketepatan model...', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    final diffsList = comparisonData['diffs'] as List<dynamic>? ?? [];
    final diffs = diffsList.map((d) => double.tryParse(d.toString()) ?? 0.0).toList();
    
    double avgDiff = 0.0;
    double accuracy = 0.0;
    if (diffs.isNotEmpty) {
      final sum = diffs.reduce((a, b) => a + b);
      avgDiff = sum / diffs.length;
      
      final tepat = diffs.where((d) => d <= 15.0).length;
      accuracy = (tepat / diffs.length) * 100;
    }

    return BrutalCard(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evaluasi Ketepatan Model AI'.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          const Divider(thickness: 1.5, color: BrutalColors.border),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ketepatan (±15 cm)',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '${accuracy.toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: BrutalColors.primary),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1.5,
                height: 45,
                color: BrutalColors.border,
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rata-rata Meleset',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '± ${avgDiff.toStringAsFixed(1)} cm',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: BrutalColors.secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
