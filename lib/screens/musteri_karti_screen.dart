import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import '../providers/musteri_provider.dart';
import '../widgets/harita_onizleme.dart';
import 'musteri_ekle_screen.dart';

class MusteriKartiScreen extends StatefulWidget {
  final Musteri musteri;
  final MusteriProvider provider;
  final VoidCallback onGuncelle;

  const MusteriKartiScreen({
    super.key,
    required this.musteri,
    required this.provider,
    required this.onGuncelle,
  });

  @override
  State<MusteriKartiScreen> createState() => _MusteriKartiScreenState();
}

class _MusteriKartiScreenState extends State<MusteriKartiScreen> {
  late Musteri _musteri;

  @override
  void initState() {
    super.initState();
    _musteri = widget.musteri;
  }

  // ── Google Maps'i Aç ───────────────────────────────────────────────────────
  Future<void> _haritaAc(double enlem, double boylam) async {
    final String mapsUrl = 'geo:$enlem,$boylam?q=$enlem,$boylam';
    final String googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&destination=$enlem,$boylam&travelmode=driving';

    try {
      // Önce Google Maps uygulamasını dene
      if (await canLaunchUrl(Uri.parse(mapsUrl))) {
        await launchUrl(Uri.parse(mapsUrl));
      }
      // Sonra web versiyonunu dene
      else if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Harita uygulaması bulunamadı'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Telefon Ara ────────────────────────────────────────────────────────────
  Future<void> _telefonAra(String telefonNumarasi) async {
    final String telUrl = 'tel:$telefonNumarasi';

    try {
      if (await canLaunchUrl(Uri.parse(telUrl))) {
        await launchUrl(Uri.parse(telUrl));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Telefon uygulaması bulunamadı'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Ziyaret durumunu hızlı değiştir ──────────────────────────────────────

  Future<void> _durumDegistir() async {
    final yeniDurum = _musteri.durum == ZiyaretDurumu.ziyaretEdilecek
        ? ZiyaretDurumu.ziyaretEdildi
        : ZiyaretDurumu.ziyaretEdilecek;

    final guncellendi = _musteri.copyWith(
      durum: yeniDurum,
      ziyaretTarihi:
          yeniDurum == ZiyaretDurumu.ziyaretEdildi ? DateTime.now() : null,
    );

    widget.provider.musteriGuncelle(guncellendi);
    setState(() => _musteri = guncellendi);
    widget.onGuncelle();
  }

  // ── Düzenle ───────────────────────────────────────────────────────────────

  Future<void> _duzenle() async {
    final guncellendi = await Navigator.push<Musteri>(
      context,
      MaterialPageRoute(
        builder: (_) => MusteriEkleScreen(
          provider: widget.provider,
          mevcutMusteri: _musteri,
        ),
      ),
    );
    if (guncellendi != null) {
      widget.provider.musteriGuncelle(guncellendi);
      setState(() => _musteri = guncellendi);
      widget.onGuncelle();
    }
  }

  // ── Sil ───────────────────────────────────────────────────────────────────

  Future<void> _sil() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Müşteriyi Sil'),
        content: Text(
          '${_musteri.ad} ${_musteri.soyad} adlı müşteriyi silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (onay == true && mounted) {
      widget.provider.musteriSil(_musteri.id);
      widget.onGuncelle();
      Navigator.pop(context);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ziyaretEdildi = _musteri.durum == ZiyaretDurumu.ziyaretEdildi;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('${_musteri.ad} ${_musteri.soyad}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Düzenle',
            onPressed: _duzenle,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Sil',
            onPressed: _sil,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Durum kartı ─────────────────────────────────────────────────
          _DurumKarti(
            ziyaretEdildi: ziyaretEdildi,
            ziyaretTarihi: _musteri.ziyaretTarihi,
            onDurumDegistir: _durumDegistir,
          ),
          const SizedBox(height: 16),

          // ── Kişisel bilgiler ─────────────────────────────────────────────
          _BilgiKarti(
            baslik: 'Kişisel Bilgiler',
            ikon: Icons.person,
            satirlar: [
              _BilgiSatiri(
                  etiket: 'Ad Soyad',
                  deger: '${_musteri.ad} ${_musteri.soyad}'),
              _BilgiSatiri(etiket: 'TC Kimlik', deger: _musteri.tcKimlik),
              _BilgiSatiriTiklnabilir(
                etiket: 'Telefon',
                deger: _musteri.telefon,
                onTap: () => _telefonAra(_musteri.telefon),
                ikon: Icons.call,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Arazi bilgileri ──────────────────────────────────────────────
          _BilgiKarti(
            baslik: 'Arazi Bilgileri',
            ikon: Icons.landscape,
            satirlar: [
              _BilgiSatiri(etiket: 'Adres', deger: _musteri.adres),
              _BilgiSatiri(
                  etiket: 'Büyüklük', deger: '${_musteri.araziBoyutu} Dönüm'),
            ],
          ),
          const SizedBox(height: 12),

          // ── Harita önizleme ──────────────────────────────────────────────
          if (_musteri.enlem != null && _musteri.boylam != null) ...[
            _BolumBasligi(baslik: 'Arazi Konumu', ikon: Icons.map),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _haritaAc(_musteri.enlem!, _musteri.boylam!),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      HaritaOnizleme(
                        enlem: _musteri.enlem!,
                        boylam: _musteri.boylam!,
                        musteriAdi: '${_musteri.ad} ${_musteri.soyad}',
                      ),
                      // Tıklanabilir olduğunu gösteren overlay
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                _haritaAc(_musteri.enlem!, _musteri.boylam!),
                            splashColor: Colors.blue.withAlpha(50),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(76),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.directions,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Yol Tarifi Aç',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Notlar ──────────────────────────────────────────────────────
          if (_musteri.notlar != null && _musteri.notlar!.isNotEmpty) ...[
            _BilgiKarti(
              baslik: 'Notlar',
              ikon: Icons.note,
              satirlar: [
                _BilgiSatiri(etiket: '', deger: _musteri.notlar!),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // ── Kayıt tarihi ─────────────────────────────────────────────────
          _BilgiKarti(
            baslik: 'Kayıt Bilgisi',
            ikon: Icons.info_outline,
            satirlar: [
              _BilgiSatiri(
                etiket: 'Oluşturulma',
                deger: _tarihFormatla(_musteri.olusturmaTarihi),
              ),
              if (_musteri.ziyaretTarihi != null)
                _BilgiSatiri(
                  etiket: 'Ziyaret',
                  deger: _tarihFormatla(_musteri.ziyaretTarihi!),
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),

      // ── Hızlı durum butonu ───────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ElevatedButton.icon(
            onPressed: _durumDegistir,
            icon: Icon(
              ziyaretEdildi ? Icons.schedule : Icons.check_circle_outline,
              size: 20,
            ),
            label: Text(
              ziyaretEdildi
                  ? 'Ziyaret Edilecek Olarak İşaretle'
                  : 'Ziyaret Edildi Olarak İşaretle',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  ziyaretEdildi ? Colors.orange : const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _tarihFormatla(DateTime tarih) {
    return '${tarih.day.toString().padLeft(2, '0')}.'
        '${tarih.month.toString().padLeft(2, '0')}.'
        '${tarih.year}  '
        '${tarih.hour.toString().padLeft(2, '0')}:'
        '${tarih.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Durum Kartı ───────────────────────────────────────────────────────────

class _DurumKarti extends StatelessWidget {
  final bool ziyaretEdildi;
  final DateTime? ziyaretTarihi;
  final VoidCallback onDurumDegistir;

  const _DurumKarti({
    required this.ziyaretEdildi,
    required this.ziyaretTarihi,
    required this.onDurumDegistir,
  });

  @override
  Widget build(BuildContext context) {
    final renk = ziyaretEdildi ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: renk.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: renk.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: renk.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              ziyaretEdildi ? Icons.check_circle : Icons.schedule,
              color: renk.shade700,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ziyaretEdildi ? 'Ziyaret Edildi' : 'Ziyaret Edilecek',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: renk.shade800,
                  ),
                ),
                if (ziyaretEdildi && ziyaretTarihi != null)
                  Text(
                    '${ziyaretTarihi!.day.toString().padLeft(2, '0')}.'
                    '${ziyaretTarihi!.month.toString().padLeft(2, '0')}.'
                    '${ziyaretTarihi!.year}',
                    style: TextStyle(fontSize: 12, color: renk.shade600),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bilgi Kartı ───────────────────────────────────────────────────────────

class _BilgiKarti extends StatelessWidget {
  final String baslik;
  final IconData ikon;
  final List<dynamic> satirlar;

  const _BilgiKarti({
    required this.baslik,
    required this.ikon,
    required this.satirlar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BolumBasligi(baslik: baslik, ikon: ikon),
            const SizedBox(height: 12),
            ...satirlar.map((s) {
              if (s is _BilgiSatiriTiklnabilir) {
                return _SatirTiklnabilirWidget(satir: s);
              } else {
                return _SatirWidget(satir: s as _BilgiSatiri);
              }
            }),
          ],
        ),
      ),
    );
  }
}

class _BilgiSatiri {
  final String etiket;
  final String deger;
  const _BilgiSatiri({required this.etiket, required this.deger});
}

class _BilgiSatiriTiklnabilir {
  final String etiket;
  final String deger;
  final VoidCallback onTap;
  final IconData ikon;
  const _BilgiSatiriTiklnabilir({
    required this.etiket,
    required this.deger,
    required this.onTap,
    required this.ikon,
  });
}

class _SatirWidget extends StatelessWidget {
  final _BilgiSatiri satir;
  const _SatirWidget({required this.satir});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: satir.etiket.isEmpty
          ? Text(satir.deger,
              style: const TextStyle(fontSize: 14, color: Colors.black87))
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    satir.etiket,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    satir.deger,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SatirTiklnabilirWidget extends StatelessWidget {
  final _BilgiSatiriTiklnabilir satir;
  const _SatirTiklnabilirWidget({required this.satir});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: satir.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  satir.etiket,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        satir.deger,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      satir.ikon,
                      color: Colors.blue,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bölüm Başlığı ─────────────────────────────────────────────────────────

class _BolumBasligi extends StatelessWidget {
  final String baslik;
  final IconData ikon;

  const _BolumBasligi({required this.baslik, required this.ikon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(ikon, color: const Color(0xFF2E7D32), size: 18),
        const SizedBox(width: 6),
        Text(
          baslik,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: Colors.green.shade200)),
      ],
    );
  }
}
