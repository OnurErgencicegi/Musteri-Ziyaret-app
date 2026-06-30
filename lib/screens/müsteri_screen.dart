import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../providers/musteri_provider.dart';
import 'musteri_karti_screen.dart';
import 'musteri_ekle_screen.dart';
import '../widgets/musteri_listesi.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MusteriProvider _provider = MusteriProvider();
  final TextEditingController _aramaController = TextEditingController();
  String _aramaQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aramaController.dispose();
    super.dispose();
  }

  void _musteriEkle() async {
    final yeniMusteri = await Navigator.push<Musteri>(
      context,
      MaterialPageRoute(
        builder: (_) => MusteriEkleScreen(provider: _provider),
      ),
    );
    if (yeniMusteri != null) {
      _provider.musteriEkle(yeniMusteri);
      setState(() {});
    }
  }

  void _musteriAc(Musteri musteri) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MusteriKartiScreen(
          musteri: musteri,
          provider: _provider,
          onGuncelle: () => setState(() {}),
        ),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tumMusteriler = _aramaQuery.isEmpty
        ? _provider.musteriler
        : _provider.ara(_aramaQuery);
    final ziyaretEdilenler = tumMusteriler
        .where((m) => m.durum == ZiyaretDurumu.ziyaretEdildi)
        .toList();
    final ziyaretEdilecekler = tumMusteriler
        .where((m) => m.durum == ZiyaretDurumu.ziyaretEdilecek)
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.agriculture, size: 24),
            SizedBox(width: 8),
            Text(
              'Ziyaret Yönetimi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Arama çubuğu
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _aramaController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ad, TC, telefon veya adres ara...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.8)),
                    suffixIcon: _aramaQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white),
                            onPressed: () {
                              _aramaController.clear();
                              setState(() => _aramaQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white54),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _aramaQuery = v),
                ),
              ),
              // Tab bar
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: [
                  Tab(text: 'Tümü (${tumMusteriler.length})'),
                  Tab(text: '✓ Edildi (${ziyaretEdilenler.length})'),
                  Tab(text: '◷ Edilecek (${ziyaretEdilecekler.length})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Özet kartları
          _OzetKartlari(provider: _provider),
          // Liste
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                MusteriListesi(
                  musteriler: tumMusteriler,
                  onMusteriTap: _musteriAc,
                  provider: _provider,
                  onGuncelle: () => setState(() {}),
                ),
                MusteriListesi(
                  musteriler: ziyaretEdilenler,
                  onMusteriTap: _musteriAc,
                  provider: _provider,
                  onGuncelle: () => setState(() {}),
                ),
                MusteriListesi(
                  musteriler: ziyaretEdilecekler,
                  onMusteriTap: _musteriAc,
                  provider: _provider,
                  onGuncelle: () => setState(() {}),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _musteriEkle,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Yeni Müşteri', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _OzetKartlari extends StatelessWidget {
  final MusteriProvider provider;
  const _OzetKartlari({required this.provider});

  @override
  Widget build(BuildContext context) {
    final toplam = provider.musteriler.length;
    final edildi = provider.ziyaretEdilenler.length;
    final edilecek = provider.ziyaretEdilecekler.length;
    final toplamArazi = provider.musteriler
        .fold<double>(0, (sum, m) => sum + m.araziBoyutu);

    return Container(
      color: const Color(0xFF2E7D32),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _OzetKart(
            ikon: Icons.people,
            deger: '$toplam',
            etiket: 'Toplam',
            renk: Colors.blue.shade300,
          ),
          const SizedBox(width: 8),
          _OzetKart(
            ikon: Icons.check_circle,
            deger: '$edildi',
            etiket: 'Ziyaret Edildi',
            renk: Colors.green.shade300,
          ),
          const SizedBox(width: 8),
          _OzetKart(
            ikon: Icons.schedule,
            deger: '$edilecek',
            etiket: 'Ziyaret Edilecek',
            renk: Colors.orange.shade300,
          ),
          const SizedBox(width: 8),
          _OzetKart(
            ikon: Icons.landscape,
            deger: '${toplamArazi.toStringAsFixed(0)}',
            etiket: 'Toplam Dönüm',
            renk: Colors.teal.shade300,
          ),
        ],
      ),
    );
  }
}

class _OzetKart extends StatelessWidget {
  final IconData ikon;
  final String deger;
  final String etiket;
  final Color renk;

  const _OzetKart({
    required this.ikon,
    required this.deger,
    required this.etiket,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(ikon, color: renk, size: 20),
            const SizedBox(height: 4),
            Text(
              deger,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              etiket,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
