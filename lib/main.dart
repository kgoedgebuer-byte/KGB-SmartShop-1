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
        primarySwatch: Colors.blue,
        useMaterial3: true,
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
  final List<String> _shops = [];
  Color selectedColor = Colors.white;
  final Map<String, Color> shopColors = {};

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList('shops') ?? [];
    setState(() => _shops.addAll(items));
  }

  Future<void> _saveShops() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('shops', _shops);
  }

  void _addShop() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _shops.add(_controller.text.trim());
      shopColors[_controller.text.trim()] = selectedColor;
      _controller.clear();
      _saveShops();
    });
  }

  void _removeShop(String name) {
    setState(() {
      _shops.remove(name);
      shopColors.remove(name);
      _saveShops();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛒 KGB SmartShop'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.color_lens_outlined),
            onPressed: () async {
              final color = await showDialog<Color>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Kies een achtergrondkleur"),
                  content: SingleChildScrollView(
                    child: BlockPicker(
                      pickerColor: selectedColor,
                      onColorChanged: (c) => selectedColor = c,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, selectedColor),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
              if (color != null) setState(() => selectedColor = color);
            },
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
      children: colors.map((c) {
        return GestureDetector(
          onTap: () => onColorChanged(c),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                width: 2,
                color: c == pickerColor ? Colors.black : Colors.transparent,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

