import 'package:geolocator/geolocator.dart';

/// Konum ile ilgili yardımcı işlemleri barındıran servis sınıfı.
/// Hiçbir API key gerektirmez — cihaz GPS'i ve URL şeması kullanır.
class KonumServisi {
  KonumServisi._(); // instantiate edilemesin

  // ── Google Maps yol tarifi URL'i ──────────────────────────────────────────

  /// Verilen koordinata Google Maps navigasyonu açan URL döner.
  /// Uygulama yüklüyse doğrudan açar, yoksa tarayıcıya düşer.
  static String googleMapsYolTarifi(double enlem, double boylam) {
    return 'https://www.google.com/maps/dir/?api=1&destination=$enlem,$boylam&travelmode=driving';
  }

  /// Koordinatı Google Maps'te sadece göstermek (navigasyon değil) için URL.
  static String googleMapsGoster(double enlem, double boylam) {
    return 'https://www.google.com/maps/search/?api=1&query=$enlem,$boylam';
  }

  // ── Cihaz GPS'i ───────────────────────────────────────────────────────────

  /// İzin durumunu kontrol eder; gerekirse kullanıcıdan ister.
  /// [LocationPermission] döner — çağıran taraf karar verir.
  static Future<LocationPermission> izinKontrol() async {
    LocationPermission izin = await Geolocator.checkPermission();
    if (izin == LocationPermission.denied) {
      izin = await Geolocator.requestPermission();
    }
    return izin;
  }

  /// İzin reddedilmiş mi?
  static bool izinReddedildi(LocationPermission izin) {
    return izin == LocationPermission.denied ||
        izin == LocationPermission.deniedForever;
  }

  /// Mevcut GPS konumunu döner.
  /// İzin yoksa ya da konum servisi kapalıysa [Exception] fırlatır.
  static Future<Position> mevcutKonumAl() async {
    final servisAcik = await Geolocator.isLocationServiceEnabled();
    if (!servisAcik) {
      throw Exception('Konum servisi kapalı. Lütfen cihaz ayarlarından açın.');
    }

    final izin = await izinKontrol();
    if (izinReddedildi(izin)) {
      throw Exception('Konum izni verilmedi.');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // ── İki nokta arası mesafe ────────────────────────────────────────────────

  /// İki koordinat arasındaki mesafeyi **metre** cinsinden döner.
  static double mesafeHesapla({
    required double baslangicEnlem,
    required double baslangicBoylam,
    required double bitisEnlem,
    required double bitisBoylam,
  }) {
    return Geolocator.distanceBetween(
      baslangicEnlem,
      baslangicBoylam,
      bitisEnlem,
      bitisBoylam,
    );
  }

  /// Mesafeyi okunabilir string'e çevirir: "1.2 km" veya "340 m"
  static String mesafeFomatli(double metre) {
    if (metre >= 1000) {
      return '${(metre / 1000).toStringAsFixed(1)} km';
    }
    return '${metre.toStringAsFixed(0)} m';
  }
}