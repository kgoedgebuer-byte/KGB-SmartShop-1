import 'firebase_web_registration.dart';
import 'firebase_web_registration.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFirebaseWebPlugins();
  registerFirebaseWebPlugins();
  await Firebase.initializeApp();
  runApp(const KGBSmartShopApp());
}

class KGBSmartShopApp extends StatelessWidget {
  const KGBSmartShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KGB SmartShop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7F9FB),
        useMaterial3: true,
      ),
      home: const SmartShopHome(),
    );
  }
}

class SmartShopHome extends StatefulWidget {
  const SmartShopHome({super.key});

  @override
  State<SmartShopHome> createState() => _SmartShopHomeState();
}

class _SmartShopHomeState extends State<SmartShopHome> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _shops = [];
  final Map<String, Color> _shopColors = {};
  final Map<String, Color> _shopBorders = {};

  Color _backgroundColor = const Color(0xFFF7F9FB);

  final List<Color> _pastelColors = [
    const Color(0xFFFFC1CC),
    const Color(0xFFFFE0B2),
    const Color(0xFFFFF9C4),
    const Color(0xFFC8E6C9),
    const Color(0xFFB3E5FC),
    const Color(0xFFD1C4E9),
    const Color(0xFFFFCCBC),
    const Color(0xFFE1BEE7),
    const Color(0xFFDCEDC8),
    const Color(0xFFFFF176),
    const Color(0xFF80DEEA),
    const Color(0xFFFFAB91),
    const Color(0xFFFFF59D),
    const Color(0xFFCFD8DC),
    const Color(0xFFF0F4C3),
    const Color(0xFFFFCDD2),
    const Color(0xFFE6EE9C),
    const Color(0xFFB2EBF2),
    const Color(0xFFC5CAE9),
    const Color(0xFFFFF8E1),
    const Color(0xFFFFE57F),
    const Color(0xFFFFCC80),
    const Color(0xFF80CBC4),
    const Color(0xFF9FA8DA),
    const Color(0xFFCE93D8),
    const Color(0xFFB39DDB),
    const Color(0xFFA5D6A7),
    const Color(0xFF81D4FA),
    const Color(0xFFB0BEC5),
    const Color(0xFFF8BBD0),
    const Color(0xFFFFECB3),
    const Color(0xFFE0E0E0),
    const Color(0xFFFFF3E0),
    const Color(0xFFE3F2FD),
    const Color(0xFFF1F8E9),
    const Color(0xFFFFFDE7),
    const Color(0xFFFBE9E7),
    const Color(0xFFE8EAF6),
    const Color(0xFFF3E5F5),
    const Color(0xFFFCE4EC),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 🔄 Laden van lokale data + Firestore sync
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('shops');
    final bg = prefs.getInt('bg');

    if (saved == null || saved.isEmpty) {
      _shops.addAll(['Delhaize', 'Colruyt', 'Lidl', 'Aldi', 'Action', 'Zeeman', 'Kruidvat']);
    } else {
      _shops.addAll(saved);
    }
    if (bg != null) _backgroundColor = Color(bg);

    // 🔥 Probeer online data te laden (Firestore)
    try {
      final firestore = FirebaseFirestore.instance.collection('smartshop_users');
      final doc = await firestore.doc('kurt').get();
      if (doc.exists) {
        final data = doc.data()!;
        final cloudShops = List<String>.from(data['shops'] ?? []);
        final cloudBg = data['bg'];
        if (cloudShops.isNotEmpty) {
          _shops
            ..clear()
            ..addAll(cloudShops);
        }
        if (cloudBg != null) _backgroundColor = Color(cloudBg);
      }
    } catch (e) {
      debugPrint('⚠️ Firestore niet bereikbaar, lokale data gebruikt: $e');
    }

    setState(() {
      for (var s in _shops) {
        _shopColors[s] = _randomPastel();
        _shopBorders[s] = _randomPastel();
      }
    });
  }

  // 🔐 Opslaan lokaal + Firestore
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('shops', _shops);
    await prefs.setInt('bg', _backgroundColor.value);

    try {
      final firestore = FirebaseFirestore.instance.collection('smartshop_users');
      await firestore.doc('kurt').set({
        'shops': _shops,
        'bg': _backgroundColor.value,
      });
    } catch (e) {
      debugPrint('⚠️ Kon Firestore niet updaten: $e');
    }
  }

  Color _randomPastel() {
    final random = Random();
    return _pastelColors[random.nextInt(_pastelColors.length)];
  }

  void _addShop() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _shops.add(text);
      _shopColors[text] = _randomPastel();
      _shopBorders[text] = _randomPastel();
      _controller.clear();
      _saveData();
    });
  }

  void _deleteShop(String name) {
    setState(() {
      _shops.remove(name);
      _shopColors.remove(name);
      _shopBorders.remove(name);
      _saveData();
    });
  }

  void _changeBackground() {
    setState(() {
      _backgroundColor = _randomPastel();
      _saveData();
    });
  }

  void _changeBorders() {
    setState(() {
      for (var s in _shops) {
        _shopBorders[s] = _randomPastel();
      }
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text(
          '🛒 KGB SmartShop',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _changeBackground,
            icon: const Icon(Icons.format_color_fill, color: Colors.white),
            tooltip: 'Wijzig achtergrondkleur',
          ),
          IconButton(
            onPressed: _changeBorders,
            icon: const Icon(Icons.color_lens_outlined, color: Colors.white),
            tooltip: 'Wijzig randen',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Winkel toevoegen...',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_) => _addShop(),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton.small(
                  onPressed: _addShop,
                  backgroundColor: Colors.blueAccent,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _shops.length,
              itemBuilder: (context, i) {
                final shop = _shops[i];
                return Card(
                  color: _shopColors[shop] ?? _randomPastel(),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                        color: _shopBorders[shop] ?? _randomPastel(),
                        width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(shop,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteShop(shop),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

