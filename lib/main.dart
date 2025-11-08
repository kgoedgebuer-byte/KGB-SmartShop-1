import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const KGBSmartShop());
}

class KGBSmartShop extends StatelessWidget {
  const KGBSmartShop({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KGB SmartShop',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const ShopListPage(),
    );
  }
}

class ShopListPage extends StatefulWidget {
  const ShopListPage({super.key});

  @override
  State<ShopListPage> createState() => _ShopListPageState();
}

class _ShopListPageState extends State<ShopListPage> {
  final TextEditingController _controller = TextEditingController();

  // lijst van winkel-namen
  final List<String> _shops = [];

  // huidige achtergrondkleur
  Color selectedColor = Colors.white;

  // per winkel een kleur
  final Map<String, Color> shopColors = {};

  // keys voor opslag
  static const _kShopsKey = 'shops_v1';
  static const _kShopColorsKey = 'shop_colors_v1';
  static const _kSelectedColorKey = 'selected_color_v1';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    // namen
    final items = prefs.getStringList(_kShopsKey) ?? [];
    _shops.addAll(items);

    // kleuren per winkel
    final colorsJson = prefs.getString(_kShopColorsKey);
    if (colorsJson != null && colorsJson.isNotEmpty) {
      final decoded = (jsonDecode(colorsJson) as Map).cast<String, dynamic>();
      decoded.forEach((name, argb) {
        shopColors[name] = Color(argb as int);
      });
    }

    // algemene achtergrond
    final bgInt = prefs.getInt(_kSelectedColorKey);
    if (bgInt != null) {
      selectedColor = Color(bgInt);
    }

    setState(() {});
  }

  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kShopsKey, _shops);

    // kleuren mappen naar int
    final map = <String, int>{};
    shopColors.forEach((name, color) {
      map[name] = color.value;
    });
    await prefs.setString(_kShopColorsKey, jsonEncode(map));

    await prefs.setInt(_kSelectedColorKey, selectedColor.value);
  }

  void _addShop() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    if (_shops.contains(name)) return;
    setState(() {
      _shops.add(name);
      // nieuwe winkel krijgt meteen de huidige kleur
      shopColors[name] = selectedColor;
      _controller.clear();
    });
    _saveAll();
  }

  void _removeShop(String name) {
    setState(() {
      _shops.remove(name);
      shopColors.remove(name);
    });
    _saveAll();
  }

  Future<void> _pickBackgroundColor() async {
    final color = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kies een achtergrondkleur"),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: selectedColor,
            onColorChanged: (c) {
              Navigator.pop(context, c);
            },
          ),
        ),
      ),
    );
    if (color != null) {
      setState(() {
        selectedColor = color;
      });
      _saveAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛒 KGB SmartShop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.color_lens_outlined),
            onPressed: _pickBackgroundColor,
            tooltip: 'Achtergrondkleur',
          ),
        ],
      ),
      backgroundColor: selectedColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Winkel toevoegen',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addShop(),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton.small(
                  onPressed: _addShop,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _shops.length,
              itemBuilder: (context, index) {
                final name = _shops[index];
                final color = shopColors[name] ?? Colors.grey.shade200;
                return Card(
                  color: color,
                  child: ListTile(
                    title: Text(name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeShop(name),
                    ),
                    onTap: () async {
                      // kleur van deze winkel apart kiezen
                      final c = await showDialog<Color>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Kleur voor "$name"'),
                          content: SingleChildScrollView(
                            child: BlockPicker(
                              pickerColor: color,
                              onColorChanged: (cc) {
                                Navigator.pop(context, cc);
                              },
                            ),
                          ),
                        ),
                      );
                      if (c != null) {
                        setState(() {
                          shopColors[name] = c;
                        });
                        _saveAll();
                      }
                    },
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

/// eenvoudige kleurkiezer
class BlockPicker extends StatelessWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const BlockPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink,
      Colors.brown,
      Colors.cyan,
      Colors.grey,
      Colors.white,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((c) {
        final selected = c.value == pickerColor.value;
        return GestureDetector(
          onTap: () => onColorChanged(c),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                width: 2,
                color: selected ? Colors.black : Colors.transparent,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
