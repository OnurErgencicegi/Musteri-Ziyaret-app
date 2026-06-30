enum ZiyaretDurumu { ziyaretEdildi, ziyaretEdilecek }

class Musteri {
  final String id;
  
  String tcKimlik;
  String ad;
  String soyad;
  String adres;
  double araziBoyutu; // dönüm
  String telefon;
  ZiyaretDurumu durum;
  DateTime olusturmaTarihi;
  DateTime? ziyaretTarihi;
  String? notlar;
  double? enlem;
  double? boylam;

  Musteri({
    required this.id,
    required this.tcKimlik,
    required this.ad,
    required this.soyad,
    required this.adres,
    required this.araziBoyutu,
    required this.telefon,
    required this.durum,
    required this.olusturmaTarihi,
    this.ziyaretTarihi,
    this.notlar,
    this.enlem,
    this.boylam,
  });

  String get tamAd => '$ad $soyad';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tcKimlik': tcKimlik,
      'ad': ad,
      'soyad': soyad,
      'adres': adres,
      'araziBoyutu': araziBoyutu,
      'telefon': telefon,
      'durum': durum.name,
      'olusturmaTarihi': olusturmaTarihi.toIso8601String(),
      'ziyaretTarihi': ziyaretTarihi?.toIso8601String(),
      'notlar': notlar,
      'enlem': enlem,
      'boylam': boylam,
    };
  }

  factory Musteri.fromMap(Map<String, dynamic> map) {
    return Musteri(
      id: map['id'],
      tcKimlik: map['tcKimlik'],
      ad: map['ad'],
      soyad: map['soyad'],
      adres: map['adres'],
      araziBoyutu: (map['araziBoyutu'] as num).toDouble(),
      telefon: map['telefon'],
      durum: ZiyaretDurumu.values.firstWhere((e) => e.name == map['durum']),
      olusturmaTarihi: DateTime.parse(map['olusturmaTarihi']),
      ziyaretTarihi: map['ziyaretTarihi'] != null
          ? DateTime.parse(map['ziyaretTarihi'])
          : null,
      notlar: map['notlar'],
      enlem: map['enlem'] != null ? (map['enlem'] as num).toDouble() : null,
      boylam: map['boylam'] != null ? (map['boylam'] as num).toDouble() : null,
    );
  }

  Musteri copyWith({
    String? tcKimlik,
    String? ad,
    String? soyad,
    String? adres,
    double? araziBoyutu,
    String? telefon,
    ZiyaretDurumu? durum,
    DateTime? ziyaretTarihi,
    String? notlar,
    double? enlem,
    double? boylam,
  }) {
    return Musteri(
      id: id,
      tcKimlik: tcKimlik ?? this.tcKimlik,
      ad: ad ?? this.ad,
      soyad: soyad ?? this.soyad,
      adres: adres ?? this.adres,
      araziBoyutu: araziBoyutu ?? this.araziBoyutu,
      telefon: telefon ?? this.telefon,
      durum: durum ?? this.durum,
      olusturmaTarihi: olusturmaTarihi,
      ziyaretTarihi: ziyaretTarihi ?? this.ziyaretTarihi,
      notlar: notlar ?? this.notlar,
      enlem: enlem ?? this.enlem,
      boylam: boylam ?? this.boylam,
    );
  }
}