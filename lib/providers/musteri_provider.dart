import 'package:flutter/foundation.dart';
import '../models/customer.dart';

class MusteriProvider extends ChangeNotifier {
  final List<Musteri> _musteriler = [
    // Demo veriler
    Musteri(
      id: '1',
      tcKimlik: '12345678901',
      ad: 'Ahmet',
      soyad: 'Yılmaz',
      adres: 'Konya, Karatay İlçesi, Merkez Mah. No:12',
      araziBoyutu: 45.5,
      telefon: '05321234567',
      durum: ZiyaretDurumu.ziyaretEdildi,
      olusturmaTarihi: DateTime.now().subtract(const Duration(days: 5)),
      ziyaretTarihi: DateTime.now().subtract(const Duration(days: 2)),
      notlar: 'Buğday ekimi yapılacak. Sulama sistemi kurulacak.',
    ),
    Musteri(
      id: '2',
      tcKimlik: '98765432109',
      ad: 'Fatma',
      soyad: 'Kaya',
      adres: 'Ankara, Polatlı, Bağlum Köyü',
      araziBoyutu: 120.0,
      telefon: '05437654321',
      durum: ZiyaretDurumu.ziyaretEdilecek,
      olusturmaTarihi: DateTime.now().subtract(const Duration(days: 1)),
      notlar: 'Arpa hasatı için görüşülecek.',
    ),
  ];

  List<Musteri> get musteriler => List.unmodifiable(_musteriler);

  List<Musteri> get ziyaretEdilenler =>
      _musteriler.where((m) => m.durum == ZiyaretDurumu.ziyaretEdildi).toList();

  List<Musteri> get ziyaretEdilecekler =>
      _musteriler.where((m) => m.durum == ZiyaretDurumu.ziyaretEdilecek).toList();

  void musteriEkle(Musteri musteri) {
    _musteriler.add(musteri);
    notifyListeners();
  }

  void musteriGuncelle(Musteri guncelMusteri) {
    final index = _musteriler.indexWhere((m) => m.id == guncelMusteri.id);
    if (index != -1) {
      _musteriler[index] = guncelMusteri;
      notifyListeners();
    }
  }

  void musteriSil(String id) {
    _musteriler.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  void durumDegistir(String id, ZiyaretDurumu yeniDurum) {
    final index = _musteriler.indexWhere((m) => m.id == id);
    if (index != -1) {
      _musteriler[index] = _musteriler[index].copyWith(
        durum: yeniDurum,
        ziyaretTarihi: yeniDurum == ZiyaretDurumu.ziyaretEdildi
            ? DateTime.now()
            : null,
      );
      notifyListeners();
    }
  }

  List<Musteri> ara(String query) {
    if (query.isEmpty) return musteriler;
    final q = query.toLowerCase();
    return _musteriler.where((m) {
      return m.ad.toLowerCase().contains(q) ||
          m.soyad.toLowerCase().contains(q) ||
          m.tcKimlik.contains(q) ||
          m.telefon.contains(q) ||
          m.adres.toLowerCase().contains(q);
    }).toList();
  }
}
