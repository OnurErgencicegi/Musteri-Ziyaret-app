import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/customer.dart';
import '../providers/musteri_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MusteriEkleScreen
// ─────────────────────────────────────────────────────────────────────────────

class MusteriEkleScreen extends StatefulWidget {
  final MusteriProvider provider;
  final Musteri? mevcutMusteri;

  const MusteriEkleScreen({
    super.key,
    required this.provider,
    this.mevcutMusteri,
  });

  @override
  State<MusteriEkleScreen> createState() => _MusteriEkleScreenState();
}

class _MusteriEkleScreenState extends State<MusteriEkleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tcController;
  late TextEditingController _adController;
  late TextEditingController _soyadController;
  late TextEditingController _adresController;
  late TextEditingController _araziController;
  late TextEditingController _telefonController;
  late TextEditingController _notlarController;

  double? _enlem;
  double? _boylam;
  bool _konumYukleniyor = false;

  bool get _duzenleme => widget.mevcutMusteri != null;

  @override
  void initState() {
    super.initState();
    final m = widget.mevcutMusteri;
    _tcController = TextEditingController(text: m?.tcKimlik ?? '');
    _adController = TextEditingController(text: m?.ad ?? '');
    _soyadController = TextEditingController(text: m?.soyad ?? '');
    _adresController = TextEditingController(text: m?.adres ?? '');
    _araziController =
        TextEditingController(text: m != null ? m.araziBoyutu.toString() : '');
    _telefonController = TextEditingController(text: m?.telefon ?? '');
    _notlarController = TextEditingController(text: m?.notlar ?? '');
    _enlem = m?.enlem;
    _boylam = m?.boylam;
  }

  @override
  void dispose() {
    _tcController.dispose();
    _adController.dispose();
    _soyadController.dispose();
    _adresController.dispose();
    _araziController.dispose();
    _telefonController.dispose();
    _notlarController.dispose();
    super.dispose();
  }

  // ── GPS konumu al ─────────────────────────────────────────────────────────

  Future<void> _mevcutKonumuAl() async {
    setState(() => _konumYukleniyor = true);
    try {
      LocationPermission izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
      }
      if (izin == LocationPermission.deniedForever ||
          izin == LocationPermission.denied) {
        _konumHatasi('Konum izni verilmedi');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _enlem = pos.latitude;
        _boylam = pos.longitude;
      });
    } catch (e) {
      _konumHatasi('Konum alınamadı: $e');
    } finally {
      setState(() => _konumYukleniyor = false);
    }
  }

  void _konumHatasi(String mesaj) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mesaj),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.red.shade700,
    ));
  }

  // ── Haritadan pin seç ─────────────────────────────────────────────────────

  Future<void> _haritadanSec() async {
    final secilen = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => _HaritaPinSecici(
          baslangicKonum: (_enlem != null && _boylam != null)
              ? LatLng(_enlem!, _boylam!)
              : null,
        ),
      ),
    );
    if (secilen != null) {
      setState(() {
        _enlem = secilen.latitude;
        _boylam = secilen.longitude;
      });
    }
  }

  // ── Kaydet ───────────────────────────────────────────────────────────────

  void _kaydet() {
    if (!_formKey.currentState!.validate()) return;

    if (_enlem == null || _boylam == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Lütfen arazi konumunu belirleyin'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final musteri = Musteri(
      id: widget.mevcutMusteri?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      tcKimlik: _tcController.text.trim(),
      ad: _adController.text.trim(),
      soyad: _soyadController.text.trim(),
      adres: _adresController.text.trim(),
      araziBoyutu: double.parse(_araziController.text.trim()),
      telefon: _telefonController.text.trim(),
      durum: ZiyaretDurumu.ziyaretEdilecek, // Her zaman "Ziyaret Edilecek"
      enlem: _enlem!,
      boylam: _boylam!,
      olusturmaTarihi: widget.mevcutMusteri?.olusturmaTarihi ?? DateTime.now(),
      ziyaretTarihi: null, // Yeni müşteri ziyaret edilmemiş
      notlar: _notlarController.text.trim().isEmpty
          ? null
          : _notlarController.text.trim(),
    );

    Navigator.pop(context, musteri);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(_duzenleme ? 'Müşteriyi Düzenle' : 'Yeni Müşteri Ekle'),
        actions: [
          TextButton(
            onPressed: _kaydet,
            child: const Text(
              'Kaydet',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Kişisel Bilgiler ─────────────────────────────────────────
            _BolumBasligi(baslik: 'Kişisel Bilgiler', ikon: Icons.person),
            const SizedBox(height: 12),
            _FormAlani(
              controller: _tcController,
              etiket: 'TC Kimlik No',
              ikon: Icons.badge,
              klavye: TextInputType.number,
              maxUzunluk: 11,
              girisiFiltrele: [FilteringTextInputFormatter.digitsOnly],
              dogrulayici: (v) {
                if (v == null || v.isEmpty) return 'TC Kimlik No zorunlu';
                if (v.length != 11) return '11 haneli olmalı';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FormAlani(
                    controller: _adController,
                    etiket: 'Ad',
                    ikon: Icons.person_outline,
                    dogrulayici: (v) =>
                        v == null || v.isEmpty ? 'Ad zorunlu' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FormAlani(
                    controller: _soyadController,
                    etiket: 'Soyad',
                    ikon: Icons.person_outline,
                    dogrulayici: (v) =>
                        v == null || v.isEmpty ? 'Soyad zorunlu' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _FormAlani(
              controller: _telefonController,
              etiket: 'Telefon',
              ikon: Icons.phone,
              klavye: TextInputType.phone,
              girisiFiltrele: [FilteringTextInputFormatter.digitsOnly],
              dogrulayici: (v) {
                if (v == null || v.isEmpty) return 'Telefon zorunlu';
                if (v.length < 10) return 'Geçerli telefon girin';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── Arazi Bilgileri ──────────────────────────────────────────
            _BolumBasligi(baslik: 'Arazi Bilgileri', ikon: Icons.landscape),
            const SizedBox(height: 12),
            _FormAlani(
              controller: _adresController,
              etiket: 'Adres',
              ikon: Icons.location_on,
              maxSatir: 2,
              dogrulayici: (v) =>
                  v == null || v.isEmpty ? 'Adres zorunlu' : null,
            ),
            const SizedBox(height: 12),
            _FormAlani(
              controller: _araziController,
              etiket: 'Arazi Büyüklüğü (Dönüm)',
              ikon: Icons.straighten,
              klavye: const TextInputType.numberWithOptions(decimal: true),
              girisiFiltrele: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))
              ],
              dogrulayici: (v) {
                if (v == null || v.isEmpty) return 'Arazi büyüklüğü zorunlu';
                if (double.tryParse(v) == null) return 'Geçerli sayı girin';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── Arazi Konumu ─────────────────────────────────────────────
            _BolumBasligi(baslik: 'Arazi Konumu', ikon: Icons.map),
            const SizedBox(height: 12),
            _KonumSecici(
              enlem: _enlem,
              boylam: _boylam,
              yukleniyor: _konumYukleniyor,
              onMevcutKonum: _mevcutKonumuAl,
              onHaritadanSec: _haritadanSec,
              onTemizle: () => setState(() {
                _enlem = null;
                _boylam = null;
              }),
            ),
            const SizedBox(height: 24),

            // ── Notlar ───────────────────────────────────────────────────
            _BolumBasligi(baslik: 'Notlar (İsteğe Bağlı)', ikon: Icons.note),
            const SizedBox(height: 12),
            _FormAlani(
              controller: _notlarController,
              etiket: 'Notlar...',
              ikon: Icons.note_alt,
              maxSatir: 4,
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _kaydet,
              icon: Icon(_duzenleme ? Icons.save : Icons.person_add),
              label: Text(
                _duzenleme ? 'Değişiklikleri Kaydet' : 'Müşteri Kartı Oluştur',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _KonumSecici
// ─────────────────────────────────────────────────────────────────────────────

class _KonumSecici extends StatelessWidget {
  final double? enlem;
  final double? boylam;
  final bool yukleniyor;
  final VoidCallback onMevcutKonum;
  final VoidCallback onHaritadanSec;
  final VoidCallback onTemizle;

  const _KonumSecici({
    required this.enlem,
    required this.boylam,
    required this.yukleniyor,
    required this.onMevcutKonum,
    required this.onHaritadanSec,
    required this.onTemizle,
  });

  @override
  Widget build(BuildContext context) {
    final konumVar = enlem != null && boylam != null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KonumButonu(
                ikon: Icons.my_location,
                etiket: 'Mevcut Konumum',
                renk: const Color(0xFF2E7D32),
                yukleniyor: yukleniyor,
                onTap: onMevcutKonum,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KonumButonu(
                ikon: Icons.map_outlined,
                etiket: 'Haritadan Seç',
                renk: Colors.blue.shade700,
                yukleniyor: false,
                onTap: onHaritadanSec,
              ),
            ),
          ],
        ),
        if (konumVar) ...[
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.hardEdge,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.green.shade300),
            ),
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.location_pin,
                          color: Color(0xFF2E7D32), size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${enlem!.toStringAsFixed(6)}, ${boylam!.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: Colors.red),
                        tooltip: 'Konumu Temizle',
                        onPressed: onTemizle,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onHaritadanSec,
                  child: SizedBox(
                    height: 160,
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(enlem!, boylam!),
                            initialZoom: 15,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.visit_app',
                              maxZoom: 19,
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(enlem!, boylam!),
                                  width: 40,
                                  height: 50,
                                  child: const _PinWidget(),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_location_alt,
                                    size: 14, color: Colors.blue.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Konumu Değiştir',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (!konumVar && !yukleniyor) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.orange.shade700, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Müşteri arazisinin haritada görünmesi için konum belirlemelisiniz.',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _KonumButonu extends StatelessWidget {
  final IconData ikon;
  final String etiket;
  final Color renk;
  final bool yukleniyor;
  final VoidCallback onTap;

  const _KonumButonu({
    required this.ikon,
    required this.etiket,
    required this.renk,
    required this.yukleniyor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: yukleniyor ? null : onTap,
      icon: yukleniyor
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: renk),
            )
          : Icon(ikon, size: 18, color: renk),
      label: Text(
        etiket,
        style:
            TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: renk),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        side: BorderSide(color: renk),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _HaritaPinSecici
// ─────────────────────────────────────────────────────────────────────────────

class _HaritaPinSecici extends StatefulWidget {
  final LatLng? baslangicKonum;
  const _HaritaPinSecici({this.baslangicKonum});

  @override
  State<_HaritaPinSecici> createState() => _HaritaPinSeciciState();
}

class _HaritaPinSeciciState extends State<_HaritaPinSecici> {
  late final MapController _mapController;
  LatLng? _secilenKonum;
  bool _konumYukleniyor = false;

  static const _turkiyeMerkez = LatLng(39.1, 35.6);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _secilenKonum = widget.baslangicKonum;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _mevcutKonumaGit() async {
    setState(() => _konumYukleniyor = true);
    try {
      LocationPermission izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
      }
      if (izin == LocationPermission.denied ||
          izin == LocationPermission.deniedForever) {
        _hata('Konum izni verilmedi');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final konum = LatLng(pos.latitude, pos.longitude);
      setState(() => _secilenKonum = konum);
      _mapController.move(konum, 16);
    } catch (e) {
      _hata('Konum alınamadı');
    } finally {
      setState(() => _konumYukleniyor = false);
    }
  }

  void _hata(String mesaj) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mesaj),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.red.shade700,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final baslangic = widget.baslangicKonum ?? _turkiyeMerkez;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: baslangic,
              initialZoom: widget.baslangicKonum != null ? 15 : 6,
              minZoom: 3,
              maxZoom: 19,
              onTap: (_, konum) => setState(() => _secilenKonum = konum),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.visit_app',
                maxZoom: 19,
              ),
              if (_secilenKonum != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _secilenKonum!,
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
                left: 4,
                right: 8,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Arazi Konumunu Seç',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text('Haritaya dokunarak pin bırakın',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                  _konumYukleniyor
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.my_location,
                              color: Colors.white),
                          tooltip: 'Mevcut Konumum',
                          onPressed: _mevcutKonumaGit,
                        ),
                ],
              ),
            ),
          ),

          // Koordinat etiketi
          if (_secilenKonum != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_pin,
                          color: Color(0xFF2E7D32), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${_secilenKonum!.latitude.toStringAsFixed(6)}, '
                        '${_secilenKonum!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // İpucu (pin yok)
          if (_secilenKonum == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 32,
              right: 32,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Arazinin bulunduğu yere dokunun veya mevcut konumunuzu kullanın',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // OSM attribution
          Positioned(
            bottom: 90,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('© OpenStreetMap',
                  style: TextStyle(fontSize: 9, color: Colors.black54)),
            ),
          ),

          // Onayla butonu
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: _secilenKonum != null
                  ? () => Navigator.pop(context, _secilenKonum)
                  : null,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: const Text('Bu Konumu Kullan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Yardımcı widget'lar
// ─────────────────────────────────────────────────────────────────────────────

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

    // ui.Path kullanıyoruz — latlong2.Path ile çakışmaz
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

class _BolumBasligi extends StatelessWidget {
  final String baslik;
  final IconData ikon;

  const _BolumBasligi({required this.baslik, required this.ikon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(ikon, color: const Color(0xFF2E7D32), size: 20),
        const SizedBox(width: 8),
        Text(
          baslik,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: Colors.green.shade200)),
      ],
    );
  }
}

class _FormAlani extends StatelessWidget {
  final TextEditingController controller;
  final String etiket;
  final IconData ikon;
  final TextInputType? klavye;
  final int? maxSatir;
  final int? maxUzunluk;
  final List<TextInputFormatter>? girisiFiltrele;
  final String? Function(String?)? dogrulayici;

  const _FormAlani({
    required this.controller,
    required this.etiket,
    required this.ikon,
    this.klavye,
    this.maxSatir = 1,
    this.maxUzunluk,
    this.girisiFiltrele,
    this.dogrulayici,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: klavye,
      maxLines: maxSatir,
      maxLength: maxUzunluk,
      inputFormatters: girisiFiltrele,
      validator: dogrulayici,
      decoration: InputDecoration(
        labelText: etiket,
        prefixIcon: Icon(ikon, color: const Color(0xFF2E7D32)),
        counterText: '',
      ),
    );
  }
}
