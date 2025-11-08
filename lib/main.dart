import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

void main() {
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
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
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
  final Map<String, Color> _shopCardColors = {};
  final Map<String, Color> _shopBorderColors = {};

  Color _backgroundColor = const Color(0xFFF8FAFC);

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

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedShops = prefs.getStringList('shops') ??
        ['Delhaize', 'Lidl', 'Colruyt', 'Aldi', 'Action', 'Kruidvat', 'Zeeman'];
    final bgValue = prefs.getInt('backgroundColor');

    setState(() {
      _shops.addAll(savedShops);
      _backgroundColor = bgValue != null ? Color(bgValue) : _backgroundColor;
      for (var shop in _shops) {
        _shopCardColors[shop] = _randomPastel();
        _shopBorderColors[shop] = _randomPastel();
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('shops', _shops);
    await prefs.setInt('backgroundColor', _backgroundColor.value);
  }

  Color _randomPastel() {
    final random = Random();
    return _pastelColors[random.nextInt(_pastelColors.length)];
  }

  void _addShop() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _shops.add(name);
      _shopCardColors[name] = _randomPastel();
      _shopBorderColors[name] = _randomPastel();
      _controller.clear();
      _saveData();
    });
  }

  void _removeShop(String name) {
    setState(() {
      _shops.remove(name);
      _shopCardColors.remove(name);
      _shopBorderColors.remove(name);
      _saveData();
    });
  }

  void _changeBackgroundColor() async {
    setState(() {
      _backgroundColor = _randomPastel();
      _saveData();
    });
  }

  void _changeBorderColors() {
    setState(() {
      for (var shop in _shops) {
        _shopBorderColors[shop] = _randomPastel();
      }
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade600,
        title: const Text(
          "🛒 KGB SmartShop",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_color_fill, color: Colors.white),
            tooltip: "Wijzig achtergrondkleur",
            onPressed: _changeBackgroundColor,
          ),
          IconButton(
            icon: const Icon(Icons.color_lens_outlined, color: Colors.white),
            tooltip: "Wijzig randen",
            onPressed: _changeBorderColors,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Winkel toevoegen...",
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
                  backgroundColor: Colors.blue.shade600,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: _shops.isEmpty
                ? const Center(
                    child: Text(
                      "Nog geen winkels toegevoegd 🛍️",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: _shops.length,
                    itemBuilder: (context, index) {
                      final shop = _shops[index];
                      final cardColor =
                          _shopCardColors[shop] ?? _randomPastel();
                      final borderColor =
                          _shopBorderColors[shop] ?? _randomPastel();
                      return Card(
                        elevation: 4,
                        color: cardColor,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: borderColor, width: 2.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(
                            shop,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.black54,
                            onPressed: () => _removeShop(shop),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
