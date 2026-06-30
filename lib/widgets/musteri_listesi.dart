import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../providers/musteri_provider.dart';

class MusteriListesi extends StatelessWidget {
  final List<Musteri> musteriler;
  final void Function(Musteri) onMusteriTap;
  final MusteriProvider provider;
  final VoidCallback onGuncelle;

  const MusteriListesi({
    super.key,
    required this.musteriler,
    required this.onMusteriTap,
    required this.provider,
    required this.onGuncelle,
  });

  @override
  Widget build(BuildContext context) {
    if (musteriler.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Müşteri bulunamadı',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: musteriler.length,
      itemBuilder: (context, index) {
        final musteri = musteriler[index];
        return _MusteriKartWidget(
          musteri: musteri,
          onTap: () => onMusteriTap(musteri),
          provider: provider,
          onGuncelle: onGuncelle,
        );
      },
    );
  }
}

class _MusteriKartWidget extends StatelessWidget {
  final Musteri musteri;
  final VoidCallback onTap;
  final MusteriProvider provider;
  final VoidCallback onGuncelle;

  const _MusteriKartWidget({
    required this.musteri,
    required this.onTap,
    required this.provider,
    required this.onGuncelle,
  });

  @override
  Widget build(BuildContext context) {
    final isEdildi = musteri.durum == ZiyaretDurumu.ziyaretEdildi;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    backgroundColor: isEdildi
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    radius: 24,
                    child: Text(
                      musteri.ad[0].toUpperCase(),
                      style: TextStyle(
                        color: isEdildi ? Colors.green.shade800 : Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                musteri.tamAd,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            _DurumBadge(isEdildi: isEdildi),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'TC: ${musteri.tcKimlik}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Detaylar
              Row(
                children: [
                  _BilgiChip(
                    ikon: Icons.phone,
                    metin: musteri.telefon,
                    renk: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _BilgiChip(
                    ikon: Icons.landscape,
                    metin: '${musteri.araziBoyutu} dönüm',
                    renk: Colors.teal,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      musteri.adres,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (musteri.ziyaretTarihi != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Ziyaret: ${_tarihFormat(musteri.ziyaretTarihi!)}',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              // Hızlı durum değiştir
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      provider.durumDegistir(
                        musteri.id,
                        isEdildi
                            ? ZiyaretDurumu.ziyaretEdilecek
                            : ZiyaretDurumu.ziyaretEdildi,
                      );
                      onGuncelle();
                    },
                    icon: Icon(
                      isEdildi ? Icons.undo : Icons.check,
                      size: 16,
                      color: isEdildi ? Colors.orange : Colors.green,
                    ),
                    label: Text(
                      isEdildi ? 'Geri Al' : 'Ziyaret Edildi',
                      style: TextStyle(
                        color: isEdildi ? Colors.orange : Colors.green,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _tarihFormat(DateTime tarih) {
    return '${tarih.day.toString().padLeft(2, '0')}.${tarih.month.toString().padLeft(2, '0')}.${tarih.year}';
  }
}

class _DurumBadge extends StatelessWidget {
  final bool isEdildi;
  const _DurumBadge({required this.isEdildi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isEdildi ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEdildi ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Text(
        isEdildi ? '✓ Ziyaret Edildi' : '◷ Edilecek',
        style: TextStyle(
          color: isEdildi ? Colors.green.shade700 : Colors.orange.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BilgiChip extends StatelessWidget {
  final IconData ikon;
  final String metin;
  final Color renk;

  const _BilgiChip({
    required this.ikon,
    required this.metin,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: renk.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 13, color: renk),
          const SizedBox(width: 4),
          Text(
            metin,
            style: TextStyle(
              color: renk.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
