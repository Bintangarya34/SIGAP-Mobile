import 'package:flutter/material.dart';
import 'dart:math' as math;
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
  String _activeHorizon = "3"; // Default 3H

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
                    children: ["1", "3", "6"].map((h) {
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
          _buildDetailRow('Confidence Tree:', conf),
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
    final station = Provider.of<StationProvider>(context, listen: false).activeStation;

    final history = pred?['histori'] as List<dynamic>? ?? [];
    final sekarang = pred?['sekarang'] ?? {};
    final prediksi = pred?['prediksi'] ?? {};

    List<double> values = [];
    List<String> labels = ["-6j", "-3j", "-1j", "now", "+1j", "+3j", "+6j"];
    List<String> statuses = [];
    List<bool> isPredList = [];

    // Helper for history status
    String getHistoryStatus(dynamic hPoint) {
      return hPoint?['status'] ?? 'AMAN';
    }

    // 1. -6 Jam (index length - 7)
    final h6 = history.length >= 7 ? history[history.length - 7] : null;
    final h6Val = double.tryParse(h6?['tinggi_air_cm']?.toString() ?? '') ?? 0.0;
    values.add(h6Val);
    statuses.add(getHistoryStatus(h6));
    isPredList.add(false);

    // 2. -3 Jam (index length - 4)
    final h3 = history.length >= 4 ? history[history.length - 4] : null;
    final h3Val = double.tryParse(h3?['tinggi_air_cm']?.toString() ?? '') ?? 0.0;
    values.add(h3Val);
    statuses.add(getHistoryStatus(h3));
    isPredList.add(false);

    // 3. -1 Jam (index length - 2)
    final h1 = history.length >= 2 ? history[history.length - 2] : null;
    final h1Val = double.tryParse(h1?['tinggi_air_cm']?.toString() ?? '') ?? 0.0;
    values.add(h1Val);
    statuses.add(getHistoryStatus(h1));
    isPredList.add(false);

    // 4. now (current value)
    final curVal = double.tryParse(sekarang['tinggi_air_cm']?.toString() ?? '') ?? 0.0;
    values.add(curVal);
    statuses.add(sekarang['status'] ?? 'AMAN');
    isPredList.add(false);
    const nowIndex = 3;

    // 5. +1 Jam
    final p1 = prediksi['1'] ?? {};
    final p1Val = double.tryParse(p1['tinggi_air_cm']?.toString() ?? '') ?? 0.0;
    values.add(p1Val);
    statuses.add(p1['status'] ?? 'AMAN');
    isPredList.add(true);

    // 6. +3 Jam
    final p3 = prediksi['3'] ?? {};
    final p3Val = double.tryParse(p3['tinggi_air_cm']?.toString() ?? '') ?? 0.0;
    values.add(p3Val);
    statuses.add(p3['status'] ?? 'AMAN');
    isPredList.add(true);

    // 7. +6 Jam
    final p6 = prediksi['6'] ?? {};
    final p6Val = double.tryParse(p6['tinggi_air_cm']?.toString() ?? '') ?? 0.0;
    values.add(p6Val);
    statuses.add(p6['status'] ?? 'AMAN');
    isPredList.add(true);

    // River geometry setup
    double bibir = 300.0;
    if (station.lokasiId == 1) { // Pucanganom
      bibir = 300.0;
    } else if (station.lokasiId == 2) { // UHT
      bibir = 290.0;
    } else if (station.lokasiId == 3) { // Kalikobor
      bibir = 370.0;
    }
    double tengah = (bibir / 2).roundToDouble();
    double pangkal = 0.0;

    // Thresholds
    final ambang = pred?['ambang'] ?? {};
    double waspada = double.tryParse(ambang['waspada']?.toString() ?? '') ?? 0.0;
    double siaga = double.tryParse(ambang['siaga']?.toString() ?? '') ?? 0.0;

    if (waspada == 0.0 || siaga == 0.0) {
      if (station.lokasiId == 1) { // Pucanganom
        waspada = 110.0;
        siaga = 130.0;
      } else if (station.lokasiId == 2) { // UHT
        waspada = 150.0;
        siaga = 190.0;
      } else { // Kalikobor (3)
        waspada = 120.0;
        siaga = 150.0;
      }
    }

    if (values.isEmpty) {
      return BrutalCard(
        child: SizedBox(
          height: 100,
          child: Center(
            child: Text('Tidak ada data grafik', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ),
      );
    }

    return BrutalCard(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: CustomPaint(
              painter: RiverChartPainter(
                values: values,
                labels: labels,
                statuses: statuses,
                isPredList: isPredList,
                nowIndex: nowIndex,
                activeHorizon: _activeHorizon,
                bibir: bibir,
                tengah: tengah,
                pangkal: pangkal,
                waspada: waspada,
                siaga: siaga,
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          const Divider(height: 1, thickness: 1.5, color: BrutalColors.border),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Aktual', const Color(0xFF2C3E50)),
              _buildLegendItem('Prediksi', const Color(0xFFE67E22)),
              _buildLegendItem('Aman', const Color(0xFF2ECC71)),
              _buildLegendItem('Waspada', const Color(0xFFF1C40F)),
              _buildLegendItem('Siaga', const Color(0xFFE74C3C)),
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: BrutalColors.border, width: 1.0),
          ),
        ),
        const SizedBox(width: 4.0),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold),
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

class RiverChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final List<String> statuses;
  final List<bool> isPredList;
  final int nowIndex;
  final String activeHorizon;
  final double bibir;
  final double tengah;
  final double pangkal;
  final double waspada;
  final double siaga;

  RiverChartPainter({
    required this.values,
    required this.labels,
    required this.statuses,
    required this.isPredList,
    required this.nowIndex,
    required this.activeHorizon,
    required this.bibir,
    required this.tengah,
    required this.pangkal,
    required this.waspada,
    required this.siaga,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftMargin = 35.0;
    const double rightMargin = 110.0;
    const double topMargin = 20.0;
    const double bottomMargin = 25.0;

    final double plotWidth = size.width - leftMargin - rightMargin;
    final double plotHeight = size.height - topMargin - bottomMargin;

    final double maxVal = math.max(bibir * 1.15, values.reduce(math.max));

    double getX(int idx) {
      if (values.length <= 1) return leftMargin;
      return leftMargin + (idx / (values.length - 1)) * plotWidth;
    }

    double getY(double val) {
      return size.height - bottomMargin - (val / maxVal) * plotHeight;
    }

    // Shading for overflow (above bibir)
    final double yBibir = getY(bibir);
    final Paint overflowPaint = Paint()..color = const Color(0x1CE74C3C); // red opacity
    canvas.drawRect(Rect.fromLTRB(leftMargin, topMargin, leftMargin + plotWidth, yBibir), overflowPaint);

    // Draw horizontal river geometry lines
    void drawGeoLine(double val, String label, Color color, {bool isDashed = false}) {
      final double y = getY(val);
      final Paint linePaint = Paint()
        ..color = color
        ..strokeWidth = 1.5;
      
      if (isDashed) {
        // Draw dashed line
        double curX = leftMargin;
        const double dashWidth = 5.0;
        const double spaceWidth = 3.0;
        while (curX < leftMargin + plotWidth) {
          canvas.drawLine(Offset(curX, y), Offset(math.min(curX + dashWidth, leftMargin + plotWidth), y), linePaint);
          curX += dashWidth + spaceWidth;
        }
      } else {
        canvas.drawLine(Offset(leftMargin, y), Offset(leftMargin + plotWidth, y), linePaint);
      }

      // Draw label background box
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: label,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 8.0, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      final double boxWidth = tp.width + 8.0;
      final double boxHeight = tp.height + 4.0;
      final double boxLeft = leftMargin + plotWidth + 6.0;
      final double boxTop = y - boxHeight / 2;

      final Paint boxPaint = Paint()..color = color;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight), const Radius.circular(4.0)), boxPaint);
      tp.paint(canvas, Offset(boxLeft + 4.0, boxTop + 2.0));
    }

    drawGeoLine(bibir, 'BIBIR SUNGAI ${bibir.round()} cm', const Color(0xFF7B3F00));
    drawGeoLine(tengah, 'TENGAH ${tengah.round()} cm', const Color(0xFF5D6D7E), isDashed: true);
    drawGeoLine(pangkal, 'PANGKAL ${pangkal.round()} cm', const Color(0xFF34495E));

    // Draw operational threshold lines (WASPADA & SIAGA)
    void drawThresholdLine(double val, String label, Color color) {
      final double y = getY(val);
      final Paint linePaint = Paint()
        ..color = color.withValues(alpha: 0.7)
        ..strokeWidth = 1.2;

      // Dashed
      double curX = leftMargin;
      const double dashWidth = 4.0;
      const double spaceWidth = 4.0;
      while (curX < leftMargin + plotWidth) {
        canvas.drawLine(Offset(curX, y), Offset(math.min(curX + dashWidth, leftMargin + plotWidth), y), linePaint);
        curX += dashWidth + spaceWidth;
      }

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: label,
          style: GoogleFonts.inter(color: color, fontSize: 7.5, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(leftMargin + plotWidth - tp.width - 5.0, y - tp.height - 2.0));
    }

    drawThresholdLine(waspada, 'WASPADA ${waspada.round()} cm', const Color(0xFFF1C40F));
    drawThresholdLine(siaga, 'SIAGA ${siaga.round()} cm', const Color(0xFFE74C3C));

    // Draw Grid Lines (Y-Axis ticks)
    final Paint gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;
    for (int i = 1; i <= 4; i++) {
      double gridVal = bibir * (i / 4);
      double y = getY(gridVal);
      canvas.drawLine(Offset(leftMargin, y), Offset(leftMargin + plotWidth, y), gridPaint);
      
      final TextPainter tp = TextPainter(
        text: TextSpan(text: '${gridVal.round()}', style: GoogleFonts.inter(color: Colors.grey, fontSize: 7)),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(leftMargin - tp.width - 4.0, y - tp.height / 2));
    }

    // Draw actual vs prediction lines
    // Solid path for history
    final Path histPath = Path();
    bool startedHist = false;
    for (int i = 0; i <= nowIndex; i++) {
      final double px = getX(i);
      final double py = getY(values[i]);
      if (!startedHist) {
        histPath.moveTo(px, py);
        startedHist = true;
      } else {
        histPath.lineTo(px, py);
      }
    }
    final Paint histLinePaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(histPath, histLinePaint);

    // Dashed path for predictions
    final Paint predLinePaint = Paint()
      ..color = const Color(0xFFE67E22)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    for (int i = nowIndex; i < values.length - 1; i++) {
      final double p1x = getX(i);
      final double p1y = getY(values[i]);
      final double p2x = getX(i + 1);
      final double p2y = getY(values[i + 1]);

      // Draw dashed line segment
      double dx = p2x - p1x;
      double dy = p2y - p1y;
      double len = math.sqrt(dx * dx + dy * dy);
      double dirX = dx / len;
      double dirY = dy / len;
      double curLen = 0.0;
      const double dashLen = 5.0;
      const double spaceLen = 3.0;
      while (curLen < len) {
        double nextLen = curLen + dashLen;
        if (nextLen > len) nextLen = len;
        canvas.drawLine(
          Offset(p1x + dirX * curLen, p1y + dirY * curLen),
          Offset(p1x + dirX * nextLen, p1y + dirY * nextLen),
          predLinePaint,
        );
        curLen += dashLen + spaceLen;
      }
    }

    // Draw points & labels
    final Map<String, Color> statusColors = {
      'AMAN': const Color(0xFF2ECC71),
      'WASPADA': const Color(0xFFF1C40F),
      'SIAGA': const Color(0xFFE74C3C),
    };

    for (int i = 0; i < values.length; i++) {
      final double px = getX(i);
      final double py = getY(values[i]);
      final double val = values[i];
      final String st = statuses[i];
      final bool isPred = isPredList[i];

      // Draw highlighting outer ring if active horizon matches
      final bool isActiveH = isPred && labels[i] == '+$activeHorizon' 'j';
      if (isActiveH) {
        final Paint activePaint = Paint()
          ..color = const Color(0xFF2C3E50)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(Offset(px, py), 9.0, activePaint);
      }

      // Draw core circle point
      final Paint ptPaint = Paint()
        ..color = statusColors[st] ?? const Color(0xFF95A5A6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), 4.5, ptPaint);
      canvas.drawCircle(Offset(px, py), 4.5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.0);

      // Draw value text label above point
      final TextPainter valTp = TextPainter(
        text: TextSpan(
          text: '${val.round()}',
          style: GoogleFonts.inter(color: Colors.black, fontSize: 8.0, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      valTp.layout();
      valTp.paint(canvas, Offset(px - valTp.width / 2, py - valTp.height - 4.0));

      // Draw X-axis label below point
      final TextPainter xTp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: GoogleFonts.inter(
            color: isPred ? const Color(0xFFE67E22) : Colors.black87,
            fontSize: 7.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      xTp.layout();
      xTp.paint(canvas, Offset(px - xTp.width / 2, size.height - bottomMargin + 4.0));
    }

    // Draw solid vertical separator line at "now"
    final double nowX = getX(nowIndex);
    final Paint sepPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.0;
    double curY = topMargin;
    while (curY < size.height - bottomMargin) {
      canvas.drawLine(Offset(nowX, curY), Offset(nowX, math.min(curY + 3.0, size.height - bottomMargin)), sepPaint);
      curY += 6.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
