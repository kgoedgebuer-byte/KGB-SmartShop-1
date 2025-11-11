// SmartShopList KGB — Web-stabiel (LAN-IP) + blijvende opslag via 
localStorage
// Opslaat: kleuren/taal/thema + lijsten per winkel (één JSON blob in 
localStorage)
import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';

void main() => runApp(const SmartShopApp());

class SmartShopApp extends StatefulWidget {
  const SmartShopApp({super.key});

  @override
  State<SmartShopApp> createState() => _SmartShopAppState();
}

class _SmartShopAppState extends State<SmartShopApp> {
  // --- Pastelkleuren ---
  final List<Color> pastel = [
    Colors.pink.shade100, Colors.purple.shade100, Colors.blue.shade100,
    Colors.lightBlue.shade100, Colors.teal.shade100, 
Colors.green.shade100,
    Colors.lime.shade100, Colors.yellow.shade100, Colors.orange.shade100,
    Colors.red.shade100, Colors.grey.shade200, const Color(0xFFFFC1E3),
    const Color(0xFFB2EBF2), const Color(0xFFE1BEE7), const 
Color(0xFFFFE0B2),
    const Color(0xFFFFF9C4), const Color(0xFFC8E6C9), const 
Color(0xFFD1C4E9),
    const Color(0xFFBBDEFB), const Color(0xFFFFCDD2), const 
Color(0xFFD7CCC8),
    const Color(0xFFB3E5FC), const Color(0xFFDCEDC8), const 
Color(0xFFF8BBD0),
    const Color(0xFFFFF59D), const Color(0xFFA5D6A7), const 
Color(0xFFFFAB91),
    const Color(0xFFCE93D8), const Color(0xFF80DEEA), const 
Color(0xFFB0BEC5),
    const Color(0xFFCFD8DC), const Color(0xFFFFFDE7), const 
Color(0xFFFFE57F),
    const Color(0xFFDCEDC8), const Color(0xFFFFCCBC), const 
Color(0xFFE6EE9C),
    const Color(0xFFD7CCC8), const Color(0xFFB2DFDB), const 
Color(0xFFC5CAE9),
    const Color(0xFFFFF8E1), const Color(0xFFD1C4E9),
  ];

  // Thema & voorkeuren
  Color bg = Colors.pink.shade50;
  Color border = Colors.pink.shade200;
  ThemeMode mode = ThemeMode.light;
  String taal = "NL";

  // UI toggles
  bool paletteOpen = false;
  bool pickBorder = false;
  String toast = "";
  Timer? _toastTimer;

  // Winkels & data
  final winkels = const [
    "Aldi","Lidl","Colruyt","Delhaize","Albert 
Heijn","Kruidvat","Action","Algemeen"
  ];
  int winkelIndex = 7; // Algemeen
  Map<String, List<Item>> data = {};

  final TextEditingController newCtrl = TextEditingController();
  final TextEditingController searchCtrl = TextEditingController();

  bool winkelModus = false; // verberg aangekochte items

  // Storage keys
  final String _prefsKey = 'smartshop_prefs_v1';
  final String _dataKey  = 'smartshop_data_v1';

  @override
  void initState() {
    super.initState();
    for (final w in winkels) { data[w] = <Item>[]; }
    _loadAll();
    searchCtrl.addListener(() => setState((){}));
  }

  // ---------- Opslag ----------
  void _savePrefs() {
    try {
      final prefs = {
        'bg': bg.value,
        'border': border.value,
        'taal': taal,
        'mode': mode==ThemeMode.dark ? 'dark' : 'light',
      };
      html.window.localStorage[_prefsKey] = jsonEncode(prefs);
    } catch (_) {}
  }

  void _loadPrefs() {
    try {
      final raw = html.window.localStorage[_prefsKey];
      if (raw == null) return;
      final prefs = jsonDecode(raw);
      bg = Color(prefs['bg']);
      border = Color(prefs['border']);
      taal = prefs['taal'];
      mode = (prefs['mode']=='dark') ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {}
  }

  void _saveData() {
    try {
      final map = <String, dynamic>{};
      for (final w in winkels) {
        map[w] = data[w]!.map((e)=>e.toJson()).toList();
      }
      html.window.localStorage[_dataKey] = jsonEncode(map);
    } catch (_) {}
  }

  void _loadData() {
    try {
      final raw = html.window.localStorage[_dataKey];
      if (raw == null) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final rebuilt = <String, List<Item>>{};
      for (final w in winkels) {
        final lst = (map[w] ?? []) as List;
        rebuilt[w] = lst.map((j)=> Item.fromJson(j)).toList();
      }
      data = rebuilt;
    } catch (_) {}
  }

  void _loadAll() {
    _loadPrefs();
    _loadData();
    setState((){});
  }

  void _resetStorage() {
    html.window.localStorage.remove(_prefsKey);
    html.window.localStorage.remove(_dataKey);
    bg = Colors.pink.shade50;
    border = Colors.pink.shade200;
    mode = ThemeMode.light;
    taal = "NL";
    for (final w in winkels) { data[w] = <Item>[]; }
    setState((){});
    _showToast("🔄 Opslag gewist");
  }

  // ---------- Helpers ----------
  void _showToast(String msg) {
    setState(() => toast = msg);
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => toast = "");
    });
  }

  List<Item> _filtered(String winkel) {
    final list = data[winkel]!;
    final q = searchCtrl.text.trim().toLowerCase();
    final base = winkelModus ? list.where((i)=>!i.checked) : list;
    if (q.isEmpty) return base.toList();
    return base.where((i)=> i.name.toLowerCase().contains(q)).toList();
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: mode==ThemeMode.dark ? const ColorScheme.dark() : const 
ColorScheme.light(),
      scaffoldBackgroundColor: bg,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: border,
        foregroundColor: Colors.black87,
        titleTextStyle: const TextStyle(fontWeight: FontWeight.w800, 
fontSize: 18),
      ),
      cardTheme: const CardTheme(elevation: 0.8, margin: EdgeInsets.zero),
    );

    final currentWinkel = winkels[winkelIndex];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: mode,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("🛒 SmartShopList KGB"),
          actions: [
            IconButton(
              tooltip: "Winkelmodus (verberg aangekochte items)",
              icon: Icon(winkelModus ? Icons.store_mall_directory : 
Icons.storefront),
              onPressed: () => setState(()=> winkelModus = !winkelModus),
            ),
            IconButton(
              tooltip: "Normale tegels",
              icon: const Icon(Icons.grid_view),
              onPressed: () => setState(()=> { winkelModus = false, 
searchCtrl.text = "" }),
            ),
            IconButton(
              tooltip: "Licht / Donker",
              icon: Icon(mode==ThemeMode.dark ? Icons.light_mode : 
Icons.dark_mode),
              onPressed: () {
                setState(()=> mode = mode==ThemeMode.dark ? 
ThemeMode.light : ThemeMode.dark);
                _savePrefs();
              },
            ),
            PopupMenuButton<String>(
              tooltip: "Taal",
              icon: const Icon(Icons.language, color: Colors.black87),
              onSelected: (v) { setState(()=> taal=v); _savePrefs(); },
              itemBuilder: (_) => ["NL","EN","FR","DE","ES","IT"]
                .map((t)=>PopupMenuItem(value: t, child: 
Text(t))).toList(),
            ),
            IconButton(
              tooltip: "Achtergrondkleur",
              icon: const Icon(Icons.format_paint),
              onPressed: ()=> setState(()=> { paletteOpen = !paletteOpen, 
pickBorder=false }),
            ),
            IconButton(
              tooltip: "Randkleur",
              icon: const Icon(Icons.border_color),
              onPressed: ()=> setState(()=> { paletteOpen = !paletteOpen, 
pickBorder=true }),
            ),
            IconButton(
              tooltip: "Opslag resetten (lang ingedrukt)",
              icon: const Icon(Icons.restart_alt),
              onPressed: (){}, 
              onLongPress: _resetStorage,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(54),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: TextField(
                controller: searchCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: "Zoek product…",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  border: OutlineInputBorder(borderRadius: 
BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Winkeltabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 
6),
              child: Row(
                children: List.generate(winkels.length, (i) {
                  final selected = i==winkelIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(winkels[i]),
                      selected: selected,
                      onSelected: (_)=> setState(()=> winkelIndex=i),
                    ),
                  );
                }),
              ),
            ),
            // Lijst
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _ItemList(
                  items: _filtered(currentWinkel),
                  onToggle: (it){ setState(()=> it.checked = !it.checked); 
_saveData(); },
                  onPlus: (it){ setState(()=> it.qty++); _saveData(); },
                  onMinus: (it){ setState(()=> it.qty = it.qty>1 ? 
it.qty-1 : 1); _saveData(); },
                  borderColor: border,
                ),
              ),
            ),
            if (paletteOpen)
              Container(
                padding: const EdgeInsets.all(8),
                height: 200,
                child: GridView.count(
                  crossAxisCount: 8,
                  children: pastel.map((kleur) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (pickBorder) border = kleur; else bg = kleur;
                          paletteOpen = false;
                          _savePrefs();
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: kleur,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black26),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            if (toast.isNotEmpty)
              Container(
                color: Colors.black87,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(toast, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 
15)),
              ),
            Container(
              color: border,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 
8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(icon: const Icon(Icons.mic, color: 
Colors.black87),
                    onPressed: ()=> _showToast("🎙 Spraakfunctie volgt")),
                  IconButton(icon: const Icon(Icons.camera_alt, color: 
Colors.black87),
                    onPressed: ()=> _showToast("📸 Scanner volgt")),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: 
BorderRadius.circular(14)),
                    ),
                    onPressed: (){
                      if (newCtrl.text.trim().isEmpty) { _showToast("Typ 
een item"); return; }
                      setState(()=> 
data[winkels[winkelIndex]]!.add(Item(newCtrl.text.trim())));
                      newCtrl.clear(); _showToast("➕ Item toegevoegd"); 
_saveData();
                    },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text("Nieuw item"),
                  ),
                  IconButton(icon: const Icon(Icons.cleaning_services, 
color: Colors.black87),
                    onPressed: (){
                      setState(()=> data[winkels[winkelIndex]]!.clear());
                      _saveData(); _showToast("🧹 Lijst geleegd");
                    }),
                  IconButton(icon: const Icon(Icons.save_alt, color: 
Colors.black87),
                    onPressed: (){ _saveData(); _showToast("💾 Lijst 
opgeslagen"); }),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: TextField(
                controller: newCtrl,
                onSubmitted: (_){
                  if (newCtrl.text.trim().isEmpty) return;
                  setState(()=> 
data[winkels[winkelIndex]]!.add(Item(newCtrl.text.trim())));
                  newCtrl.clear(); _showToast("➕ Item toegevoegd"); 
_saveData();
                },
                decoration: InputDecoration(
                  hintText: "Nieuw item",
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: (){
                      if (newCtrl.text.trim().isEmpty) return;
                      setState(()=> 
data[winkels[winkelIndex]]!.add(Item(newCtrl.text.trim())));
                      newCtrl.clear(); _showToast("➕ Item toegevoegd"); 
_saveData();
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: 
BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  final List<Item> items;
  final void Function(Item) onToggle;
  final void Function(Item) onPlus;
  final void Function(Item) onMinus;
  final Color borderColor;

  const _ItemList({
    required this.items,
    required this.onToggle,
    required this.onPlus,
    required this.onMinus,
    required this.borderColor,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text("Nog geen 
items."));
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __)=> const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final it = items[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            leading: Checkbox(value: it.checked, onChanged: (_)=> 
onToggle(it)),
            title: Text(
              it.name,
              style: TextStyle(decoration: it.checked ? 
TextDecoration.lineThrough : null),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(onPressed: ()=> onMinus(it), icon: const 
Icon(Icons.remove)),
                Text("${it.qty}", style: const TextStyle(fontWeight: 
FontWeight.bold)),
                IconButton(onPressed: ()=> onPlus(it), icon: const 
Icon(Icons.add)),
              ],
            ),
            onTap: ()=> onToggle(it),
          ),
        );
      },
    );
  }
}

class Item {
  String name;
  int qty;
  bool checked;

  Item(this.name) : qty = 1, checked = false;

  Map<String, dynamic> toJson() => {'name': name, 'qty': qty, 'checked': 
checked};

  factory Item.fromJson(Map<String, dynamic> j) =>
      Item(j['name'])..qty = (j['qty'] ?? 1)..checked = (j['checked'] ?? 
false);
}

