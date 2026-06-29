import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/brutal_card.dart';
import '../../../../core/widgets/brutal_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class LaporBanjirPage extends StatefulWidget {
  const LaporBanjirPage({super.key});

  @override
  State<LaporBanjirPage> createState() => _LaporBanjirPageState();
}

class _LaporBanjirPageState extends State<LaporBanjirPage> {
  final TextEditingController _commentController = TextEditingController();
  final ApiService _apiService = ApiService();

  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;
  bool _isUploading = false;
  String? _imagePath;
  
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: BrutalColors.background,
      shape: const Border(top: BorderSide(color: BrutalColors.border, width: 2.5)),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.black),
              title: Text('Ambil Foto Kamera', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 50,
                  );
                  if (image != null) {
                    setState(() => _imagePath = image.path);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal membuka kamera: $e')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.black),
              title: Text('Pilih dari Galeri', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 50,
                  );
                  if (image != null) {
                    setState(() => _imagePath = image.path);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal membuka galeri: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _retrieveLocation();
  }

  Future<void> _retrieveLocation() async {
    setState(() => _isGettingLocation = true);
    final pos = await LocationService.getCurrentPosition();
    if (pos != null) {
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
    }
    setState(() => _isGettingLocation = false);
  }

  Future<void> _submitReport() async {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Koordinat GPS diperlukan.')),
      );
      return;
    }

    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Harap berikan keterangan kondisi.')),
      );
      return;
    }

    setState(() => _isUploading = true);
    
    final success = await _apiService.uploadFloodReport(
      latitude: _latitude!,
      longitude: _longitude!,
      comment: comment,
      imagePath: _imagePath,
    );

    setState(() => _isUploading = false);

    if (success) {
      NotificationService.showNotification(
        id: 102,
        title: "📸 LAPORAN WARGA MASUK!",
        body: "Laporan visual genangan air di lokasi Anda berhasil diunggah dan disimpan ke server SIGAP.",
      );

      // Clear input
      _commentController.clear();
      setState(() {
        _imagePath = null;
      });
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: BrutalColors.background,
            shape: Border.all(color: BrutalColors.border, width: 2.5),
            title: Text(
              'LAPORAN DIKIRIM',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900),
            ),
            content: Text(
              'Terima kasih atas laporan Anda. Data GPS dan visual Anda telah ditambahkan ke basis data SIGAP untuk validasi lapangan.',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            actions: [
              BrutalButton(
                width: 100,
                height: 40,
                backgroundColor: BrutalColors.primary,
                onTap: () {
                  Navigator.pop(ctx);
                },
                child: Text(
                  'OK',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim laporan. Coba lagi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: BrutalColors.background,
        appBar: AppBar(
          backgroundColor: BrutalColors.primary,
          elevation: 0,
          title: Text(
            'LAPOR BANJIR',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'LAPOR BARU'),
              Tab(text: 'DAFTAR LAPORAN'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLaporBaruForm(),
            _buildDaftarLaporanList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLaporBaruForm() {
    return _isUploading
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: BrutalColors.primary),
                SizedBox(height: 16.0),
                Text('Mengupload laporan ke server SIGAP...', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BrutalCard(
                  backgroundColor: BrutalColors.secondary,
                  child: Text(
                    'Laporkan kondisi banjir atau genangan air di sekitar Anda. Laporan Anda akan divalidasi dengan sensor fisik IoT SIGAP.',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),

                Text(
                  'Foto Kondisi Visual'.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8.0),
                GestureDetector(
                  onTap: _pickImage,
                  child: BrutalCard(
                    backgroundColor: Colors.grey.shade200,
                    padding: EdgeInsets.zero,
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      color: Colors.transparent,
                      child: _imagePath == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_enhance, size: 40.0, color: BrutalColors.text),
                                const SizedBox(height: 8.0),
                                Text(
                                  'TAP UNTUK AMBIL FOTO',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 11),
                                ),
                              ],
                            )
                          : Stack(
                              children: [
                                Positioned.fill(
                                  child: _imagePath == "simulated_photo.jpg"
                                      ? Container(
                                          color: Colors.red,
                                          child: const Center(
                                            child: Icon(Icons.check_circle, size: 50.0, color: Colors.white),
                                          ),
                                        )
                                      : Image.file(
                                          File(_imagePath!),
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    color: Colors.black87,
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                    child: Text(
                                      _imagePath == "simulated_photo.jpg" ? 'Simulasi' : 'Ubah Foto',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),

                Text(
                  'GPS Lokasi Laporan'.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8.0),
                BrutalCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Latitude: ${_latitude?.toStringAsFixed(6) ?? 'Mencari...'}',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Longitude: ${_longitude?.toStringAsFixed(6) ?? 'Mencari...'}',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (_isGettingLocation)
                        const CircularProgressIndicator(color: BrutalColors.primary)
                      else
                        IconButton(
                          icon: const Icon(Icons.gps_fixed),
                          onPressed: _retrieveLocation,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),

                Text(
                  'Keterangan Kondisi Air'.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8.0),
                BrutalCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: TextField(
                    controller: _commentController,
                    maxLines: 3,
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Misal: Air menggenang setinggi lutut orang dewasa (sekitar 40cm)...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),

                BrutalButton(
                  backgroundColor: BrutalColors.primary,
                  onTap: _submitReport,
                  child: Text(
                    'KIRIM LAPORAN SEKARANG',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
              ],
            ),
          );
  }

  Widget _buildDaftarLaporanList() {
    return FutureBuilder<List<dynamic>>(
      future: _apiService.getFloodReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: BrutalColors.primary),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'Belum ada laporan foto warga.',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          );
        }

        final reports = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final item = Map<String, dynamic>.from(reports[index] as Map);
            final timeStr = item['waktu'] ?? '';
            
            // Format Timestamp
            String formattedTime = timeStr;
            try {
              final dateTime = DateTime.parse(timeStr);
              formattedTime = DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
            } catch (_) {}

            final lat = double.tryParse(item['latitude']?.toString() ?? '') ?? 0.0;
            final lng = double.tryParse(item['longitude']?.toString() ?? '') ?? 0.0;
            final catatan = item['catatan'] ?? '';
            final fotoUrl = item['foto_url'];

            return BrutalCard(
              margin: const EdgeInsets.only(bottom: 16.0),
              backgroundColor: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Render
                  if (fotoUrl != null)
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Image.network(
                        'https://sigap-banjir-2-production.up.railway.app$fotoUrl',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, size: 50.0, color: Colors.grey),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      height: 80,
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 12.0),

                  // Comment
                  Text(
                    catatan,
                    style: GoogleFonts.inter(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8.0),

                  // Metadata details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GPS: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        formattedTime,
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
