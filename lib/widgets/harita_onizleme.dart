import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/konum_servisi.dart';

/// Müşteri kartı içinde gösterilen küçük harita önizlemesi
class HaritaOnizleme extends StatelessWidget {
  final double enlem;
  final double boylam;
  final String musteriAdi;
  final bool tamEkranButon;

  const HaritaOnizleme({
    super.key,
    required this.enlem,
    required this.boylam,
    required this.musteriAdi,
    this.tamEkranButon = true,
  });

  Future<void> _googleMapsAc(BuildContext context) async {
    final url = KonumServisi.googleMapsYolTarifi(enlem, boylam);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Maps açılamadı'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final konum = LatLng(enlem, boylam);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Harita
          SizedBox(
            height: 180,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: konum,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.visit_app',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: konum,
                      width: 40,
                      height: 50,
                      child: const _PinWidget(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Koordinat bilgisi
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                '${enlem.toStringAsFixed(5)}, ${boylam.toStringAsFixed(5)}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
          ),

          // Tam ekran ve yol tarifi butonları
          if (tamEkranButon)
            Positioned(
              bottom: 8,
              right: 8,
              child: Column(
                children: [
                  _MapButon(
                    ikon: Icons.directions,
                    etiket: 'Yol Tarifi',
                    renk: Colors.blue,
                    onTap: () => _googleMapsAc(context),
                  ),
                  const SizedBox(height: 6),
                  _MapButon(
                    ikon: Icons.fullscreen,
                    etiket: 'Büyüt',
                    renk: Colors.grey.shade700,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TamEkranHarita(
                          enlem: enlem,
                          boylam: boylam,
                          musteriAdi: musteriAdi,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Pin Widget ────────────────────────────────────────────────────────────

class _PinWidget extends StatelessWidget {
  const _PinWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.agriculture, color: Colors.white, size: 16),
        ),
        CustomPaint(
          size: const Size(10, 10),
          painter: _PinTailPainter(),
        ),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.fill;

    // dart:ui'ın Path'i — latlong2.Path ile çakışmaz
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Map Buton ─────────────────────────────────────────────────────────────

class _MapButon extends StatelessWidget {
  final IconData ikon;
  final String etiket;
  final Color renk;
  final VoidCallback onTap;

  const _MapButon({
    required this.ikon,
    required this.etiket,
    required this.renk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, size: 14, color: renk),
            const SizedBox(width: 4),
            Text(
              etiket,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: renk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tam Ekran Harita ──────────────────────────────────────────────────────

class TamEkranHarita extends StatefulWidget {
  final double enlem;
  final double boylam;
  final String musteriAdi;

  const TamEkranHarita({
    super.key,
    required this.enlem,
    required this.boylam,
    required this.musteriAdi,
  });

  @override
  State<TamEkranHarita> createState() => _TamEkranHaritaState();
}

class _TamEkranHaritaState extends State<TamEkranHarita> {
  late final MapController _mapController;
  double _zoom = 15;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _yolTarifi() async {
    final url = KonumServisi.googleMapsYolTarifi(widget.enlem, widget.boylam);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final konum = LatLng(widget.enlem, widget.boylam);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: konum,
              initialZoom: _zoom,
              minZoom: 3,
              maxZoom: 19,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.visit_app',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: konum,
                    width: 40,
                    height: 50,
                    child: const _PinWidget(),
                  ),
                ],
              ),
            ],
          ),

          // Üst bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: const Color(0xFF2E7D32),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 4,
                bottom: 12,
                left: 8,
                right: 8,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.musteriAdi,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${widget.enlem.toStringAsFixed(6)}, '
                          '${widget.boylam.toStringAsFixed(6)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Zoom kontrolleri
          Positioned(
            right: 12,
            bottom: 100,
            child: Column(
              children: [
                _ZoomButon(
                  ikon: Icons.add,
                  onTap: () {
                    setState(() => _zoom = (_zoom + 1).clamp(3, 19));
                    _mapController.move(konum, _zoom);
                  },
                ),
                const SizedBox(height: 4),
                _ZoomButon(
                  ikon: Icons.remove,
                  onTap: () {
                    setState(() => _zoom = (_zoom - 1).clamp(3, 19));
                    _mapController.move(konum, _zoom);
                  },
                ),
              ],
            ),
          ),

          // Yol tarifi butonu
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: _yolTarifi,
              icon: const Icon(Icons.directions, size: 20),
              label: const Text(
                "Google Maps'te Yol Tarifi Al",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
            ),
          ),

          // OSM attribution (zorunlu)
          Positioned(
            bottom: 80,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '© OpenStreetMap',
                style: TextStyle(fontSize: 9, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Zoom Buton ────────────────────────────────────────────────────────────

class _ZoomButon extends StatelessWidget {
  final IconData ikon;
  final VoidCallback onTap;
  const _ZoomButon({required this.ikon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(ikon, color: Colors.grey.shade700, size: 20),
      ),
    );
  }
}
