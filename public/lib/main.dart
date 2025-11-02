// ~/Desktop/Oud_SmartShop/smartshoplist_v140/lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const KGBApp());
}

class KGBApp extends StatefulWidget {
  const KGBApp({super.key});
  @override
  State<KGBApp> createState() => _KGBAppState();
}

class _KGBAppState extends State<KGBApp> {
  ThemeMode _mode = ThemeMode.light;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KGB Boodschappenlijst',
      debugShowCheckedModeBanner: false,
      themeMode: _mode,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal), useMaterial3: true),
      darkTheme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark), useMaterial3: true),
      home: HomeScreen(onToggleTheme: () => setState(() => _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light)),
    );
  }
}

/// ───────────────────────────────────────── I18N ─────────────────────────────────────────
class I18n {
  static const supported = ['nl','en','fr','de','es'];
  static String lang = 'nl';
  static const _t = {
    'nl': {'title':'KGB Boodschappenlijst','hint':'Nieuw product…','add':'Toevoegen','clearBought':'Gekochte wissen','clearAll':'Lijst leegmaken','noItems':'Nog geen items voor deze winkel.','synced':'Gesynchroniseerd ✓','offline':'Geen verbinding','confirmClearTitle':'Alles verwijderen?','confirmClearMsg':'Weet je zeker dat je de hele lijst wilt leegmaken?','cancel':'Annuleren','confirm':'Bevestigen','export':'Exporteren','import':'Importeren','summary':'Totaal: {all} • Gekocht: {done}','palette':'Kleurenpalet','bg':'Achtergrond (app)','listbg':'Achtergrond (blad)','border':'Randkleur','shop':'Winkel','saved':'Opgeslagen','addedTo':'Toegevoegd aan','removed':'Verwijderd','clearedBought':'Gekochte verwijderd','clearedAll':'Lijst leeggemaakt','beep':'Beep bij acties','readonly':'Alleen-lezen (host schrijft)'},
    'en': {'title':'KGB Shopping List','hint':'New item…','add':'Add','clearBought':'Clear purchased','clearAll':'Clear list','noItems':'No items for this store yet.','synced':'Synced ✓','offline':'Offline','confirmClearTitle':'Remove all?','confirmClearMsg':'Are you sure you want to clear the list?','cancel':'Cancel','confirm':'Confirm','export':'Export','import':'Import','summary':'Total: {all} • Purchased: {done}','palette':'Palette','bg':'Background (app)','listbg':'Background (sheet)','border':'Border color','shop':'Store','saved':'Saved','addedTo':'Added to','removed':'Removed','clearedBought':'Purchased removed','clearedAll':'List cleared','beep':'Beep on actions','readonly':'Read-only (host writes)'},
    'fr': {'title':'Liste de courses KGB','hint':'Nouvel article…','add':'Ajouter','clearBought':'Effacer achetés','clearAll':'Vider la liste','noItems':'Aucun article pour ce magasin.','synced':'Synchronisé ✓','offline':'Hors ligne','confirmClearTitle':'Tout supprimer ?','confirmClearMsg':'Voulez-vous vraiment vider la liste ?','cancel':'Annuler','confirm':'Confirmer','export':'Exporter','import':'Importer','summary':'Total : {all} • Achetés : {done}','palette':'Palette','bg':'Arrière-plan (app)','listbg':'Arrière-plan (feuille)','border':'Couleur de bordure','shop':'Magasin','saved':'Enregistré','addedTo':'Ajouté à','removed':'Supprimé','clearedBought':'Achetés supprimés','clearedAll':'Liste vidée','beep':'Bip sur actions','readonly':'Lecture seule (l’hôte écrit)'},
    'de': {'title':'KGB Einkaufsliste','hint':'Neues Produkt…','add':'Hinzufügen','clearBought':'Gekaufte löschen','clearAll':'Liste leeren','noItems':'Noch keine Artikel für diesen Laden.','synced':'Synchronisiert ✓','offline':'Offline','confirmClearTitle':'Alles löschen?','confirmClearMsg':'Möchten Sie die Liste wirklich leeren?','cancel':'Abbrechen','confirm':'Bestätigen','export':'Exportieren','import':'Importieren','summary':'Gesamt: {all} • Gekauft: {done}','palette':'Palette','bg':'Hintergrund (App)','listbg':'Hintergrund (Blatt)','border':'Randfarbe','shop':'Laden','saved':'Gespeichert','addedTo':'Hinzugefügt zu','removed':'Entfernt','clearedBought':'Gekaufte entfernt','clearedAll':'Liste geleert','beep':'Beep bei Aktionen','readonly':'Nur Lesen (Host schreibt)'},
    'es': {'title':'Lista de compras KGB','hint':'Producto nuevo…','add':'Añadir','clearBought':'Borrar comprados','clearAll':'Vaciar lista','noItems':'Aún no hay artículos para esta tienda.','synced':'Sincronizado ✓','offline':'Sin conexión','confirmClearTitle':'¿Eliminar todo?','confirmClearMsg':'¿Seguro que quieres vaciar la lista?','cancel':'Cancelar','confirm':'Confirmar','export':'Exportar','import':'Importar','summary':'Total: {all} • Comprados: {done}','palette':'Paleta','bg':'Fondo (app)','listbg':'Fondo (hoja)','border':'Color del borde','shop':'Tienda','saved':'Guardado','addedTo':'Añadido a','removed':'Eliminado','clearedBought':'Comprados borrados','clearedAll':'Lista vaciada','beep':'Beep en acciones','readonly':'Solo lectura (escribe el host)'},
  };
  static String t(String key,{Map<String,String> vars=const{}}){var s=_t[lang]![key]??key;vars.forEach((k,v)=>s=s.replaceAll('{$k}',v));return s;}
  static String detect(){ if(!kIsWeb) return 'nl'; final l=(html.window.navigator.language??'nl').toLowerCase(); if(l.startsWith('nl')) return 'nl'; if(l.startsWith('fr')) return 'fr'; if(l.startsWith('de')) return 'de'; if(l.startsWith('es')) return 'es'; return 'en'; }
}

/// ───────────────────────────────────────── MODEL/PERSIST ─────────────────────────────────────────
class ShopItem {
  String name; int qty; bool done;
  ShopItem({required this.name,this.qty=1,this.done=false});
  Map<String,dynamic> toJson()=>{'name':name,'qty':qty,'done':done};
  static ShopItem fromJson(Map<String,dynamic> j)=>ShopItem(name:(j['name']??'').toString(),qty:(j['qty'] is num)?(j['qty'] as num).toInt():1,done:(j['done']??false)==true);
}

class Persist {
  static const _dataKey='smartshop:data', _prefsKey='smartshop:prefs';
  static Map<String,List<ShopItem>> data={};
  static Color bgColor=const Color(0xFFF6F7FB);     // app
  static Color listColor=const Color(0xFFFFFFFF);   // blad
  static Map<String,Color> borders={};
  static String lang='nl', lastShop='Colruyt';
  static bool beepEnabled=true;

  static Future<void> load() async {
    if(!kIsWeb) return;
    try{
      final d=html.window.localStorage[_dataKey];
      if(d!=null&&d.isNotEmpty){final decoded=jsonDecode(d) as Map<String,dynamic>;
        data=decoded.map((s,l)=>MapEntry(s,(l as List).map((e)=>ShopItem.fromJson(e as Map<String,dynamic>)).toList()));}
      final p=html.window.localStorage[_prefsKey];
      if(p!=null&&p.isNotEmpty){final prefs=jsonDecode(p) as Map<String,dynamic>;
        bgColor=Color((prefs['bg']??bgColor.value) as int);
        listColor=Color((prefs['listbg']??listColor.value) as int);
        final bd=(prefs['borders']??{}) as Map<String,dynamic>;
        borders=bd.map((k,v)=>MapEntry(k,Color((v as num).toInt())));
        lang=(prefs['lang']??I18n.detect()).toString(); lastShop=(prefs['lastShop']??lastShop).toString();
        beepEnabled=(prefs['beep']??true)==true;
      } else { lang=I18n.detect(); }
      I18n.lang = I18n.supported.contains(lang)?lang:'nl';
    } catch(_){ data={}; borders={}; bgColor=const Color(0xFFF6F7FB); listColor=const Color(0xFFFFFFFF); lang='nl'; lastShop='Colruyt'; I18n.lang='nl'; beepEnabled=true; }
  }
  static Future<void> save() async {
    if(!kIsWeb) return;
    html.window.localStorage[_dataKey]=jsonEncode(data.map((s,l)=>MapEntry(s,l.map((e)=>e.toJson()).toList())));
    html.window.localStorage[_prefsKey]=jsonEncode({'bg':bgColor.value,'listbg':listColor.value,'borders':borders.map((k,v)=>MapEntry(k,v.value)),'lang':I18n.lang,'lastShop':lastShop,'beep':beepEnabled});
  }
}

/// ───────────────────────────────────────── BEEP (web) ─────────────────────────────────────────
class WebBeep{
  static const _wav='data:audio/wav;base64,UklGRiQAAABXQVZFZm10IBAAAAABAAEAESsAACJWAAACABYAAAAAAABbAAABAAAAAA==';
  static void play(){ if(!kIsWeb||!Persist.beepEnabled) return; try{ html.AudioElement(_wav)..play(); }catch(_){}}}

/// ───────────────────────────────────────── SYNC ─────────────────────────────────────────
class Sync{
  static String server=''; static Timer? _t; static bool online=false;
  static Future<void> start() async { server=await _detect(); _t??=Timer.periodic(const Duration(seconds:10), (_)=>pull()); }
  static Future<String> _detect() async { try{ final host=html.window.location.host.split(':').first; return 'http://$host:9000/sync'; }catch(_){ return 'http://localhost:9000/sync'; } }
  static Future<void> push(Map<String,List<ShopItem>> data) async {
    try{ final res=await http.post(Uri.parse(server), headers:{'Content-Type':'application/json'}, body: jsonEncode(data.map((k,v)=>MapEntry(k,v.map((e)=>e.toJson()).toList())))); online=res.statusCode==200; }catch(_){ online=false; }
  }
  static Future<void> pull() async {
    try{ final res=await http.get(Uri.parse(server)); if(res.statusCode==200&&res.body.isNotEmpty){
        final decoded=jsonDecode(res.body) as Map<String,dynamic>;
        Persist.data=decoded.map((k,v)=>MapEntry(k,(v as List).map((e)=>ShopItem.fromJson(e as Map<String,dynamic>)).toList())); online=true;
      } else { online=false; } }catch(_){ online=false; }
  }
}

/// ───────────────────────────────────────── UI ─────────────────────────────────────────
class HomeScreen extends StatefulWidget{
  final VoidCallback onToggleTheme; const HomeScreen({super.key,required this.onToggleTheme});
  @override State<HomeScreen> createState()=>_HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  final List<String> shops=const['Colruyt','Lidl','Aldi','Carrefour','Action','Kruidvat','Delhaize','Albert Heijn'];
  final List<Color> pastel=const[
    Color(0xFFFFC1CC),Color(0xFFFFD6E0),Color(0xFFFFE6F2),Color(0xFFFDE2FF),Color(0xFFE5DEFF),
    Color(0xFFD7E3FC),Color(0xFFCFE8FF),Color(0xFFBEE3F8),Color(0xFFB3ECFF),Color(0xFFA7F3D0),
    Color(0xFFBBF7D0),Color(0xFFDCFCE7),Color(0xFFFEF9C3),Color(0xFFFFF1A6),Color(0xFFFFE4A1),
    Color(0xFFFDE68A),Color(0xFFFFD89B),Color(0xFFFFE0B2),Color(0xFFFFF3E0),Color(0xFFE0F2F1),
    Color(0xFFF1F5F9),Color(0xFFE2E8F0),Color(0xFFF8FAFC),Color(0xFFF5F5F4),Color(0xFFECEFF1),
    Color(0xFFFFCDD2),Color(0xFFF8BBD0),Color(0xFFE1BEE7),Color(0xFFD1C4E9),Color(0xFFC5CAE9),
    Color(0xFFBBDEFB),Color(0xFFB3E5FC),Color(0xFFB2EBF2),Color(0xFFB2DFDB),Color(0xFFC8E6C9),
    Color(0xFFDCEDC8),Color(0xFFF0F4C3),Color(0xFFFFF9C4),Color(0xFFFFECB3),Color(0xFFFFE0B2),
  ];
  final TextEditingController _ctrl=TextEditingController();
  String currentShop=Persist.lastShop;
  bool hostMode=false; // bepaalt schrijfrechten

  @override void initState(){ super.initState(); _boot(); }

  Future<void> _boot() async{
    await Persist.load();
    // hostMode via URL ?host=1
    final qp=html.window.location.search; hostMode = qp.contains('host=1');
    // init data + auto shop-kleuren
    for(int i=0;i<shops.length;i++){final s=shops[i];
      Persist.data.putIfAbsent(s, ()=> <ShopItem>[]);
      Persist.borders.putIfAbsent(s, ()=> pastel[i%pastel.length]);}
    await Sync.start();
    setState(()=>currentShop=Persist.lastShop);
  }

  List<ShopItem> get _items=>Persist.data[currentShop]??<ShopItem>[];
  int get _countAll=>_items.length; int get _countDone=>_items.where((e)=>e.done).length;

  void _snack(String msg,{Color? color}){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(msg),backgroundColor:color,behavior:SnackBarBehavior.floating,duration:const Duration(milliseconds:900))); }
  bool _guardWrite(){ if(hostMode) return true; _snack(I18n.t('readonly'), color: Colors.orange); return false; }

  Future<void> _add() async { if(!_guardWrite()) return;
    final name=_ctrl.text.trim(); if(name.isEmpty) return;
    _items.add(ShopItem(name:name)); _ctrl.clear();
    await Persist.save(); await Sync.push(Persist.data); WebBeep.play(); setState((){});
    _snack('${I18n.t('addedTo')} $currentShop', color: Colors.green);
  }
  Future<void> _toggleDone(int i,bool? v) async { if(!_guardWrite()) return;
    _items[i].done=v??false; await Persist.save(); await Sync.push(Persist.data); setState((){}); }
  Future<void> _inc(int i) async { if(!_guardWrite()) return;
    _items[i].qty++; await Persist.save(); await Sync.push(Persist.data); WebBeep.play(); setState((){}); }
  Future<void> _dec(int i) async { if(!_guardWrite()) return;
    if(_items[i].qty>1){ _items[i].qty--; await Persist.save(); await Sync.push(Persist.data); setState((){});} }
  Future<void> _remove(int i) async { if(!_guardWrite()) return;
    final name=_items[i].name; _items.removeAt(i); await Persist.save(); await Sync.push(Persist.data); setState((){});
    _snack('${I18n.t('removed')}: $name', color: Colors.red); }
  Future<void> _clearBought() async { if(!_guardWrite()) return;
    Persist.data[currentShop]=_items.where((e)=>!e.done).toList(growable:true); await Persist.save(); await Sync.push(Persist.data); setState((){});
    _snack(I18n.t('clearedBought'), color: Colors.orange); }
  Future<void> _clearAllConfirm() async { if(!_guardWrite()) return;
    final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(
      title:Text(I18n.t('confirmClearTitle')),content:Text(I18n.t('confirmClearMsg')),
      actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:Text(I18n.t('cancel'))), FilledButton(onPressed:()=>Navigator.pop(context,true),child:Text(I18n.t('confirm')))]));
    if(ok==true){ Persist.data[currentShop]=[]; await Persist.save(); await Sync.push(Persist.data); setState((){}); _snack(I18n.t('clearedAll'), color: Colors.orange); }
  }

  void _showPalette(){
    showModalBottomSheet(context:context,showDragHandle:true,builder:(_){
      return Padding(padding:const EdgeInsets.all(12),child:
        LayoutBuilder(builder:(_,box){final cross=(box.maxWidth~/48).clamp(6,12);
          return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(I18n.t('palette'),style:Theme.of(context).textTheme.titleLarge),
            const SizedBox(height:8), Text(I18n.t('bg')), const SizedBox(height:6),
            _colorGrid(cross,pastel,(c) async { Persist.bgColor=c; await Persist.save(); setState((){}); }),
            const SizedBox(height:8), Text(I18n.t('listbg')), const SizedBox(height:6),
            _colorGrid(cross,pastel,(c) async { Persist.listColor=c; await Persist.save(); setState((){}); }),
            const SizedBox(height:8), Text('${I18n.t('border')} — ${I18n.t('shop')}: $currentShop'), const SizedBox(height:6),
            _colorGrid(cross,pastel,(c) async { Persist.borders[currentShop]=c; await Persist.save(); setState((){}); }),
            const SizedBox(height:8),
            SwitchListTile(value:Persist.beepEnabled,onChanged:(v) async { Persist.beepEnabled=v; await Persist.save(); setState((){}); },title:Text(I18n.t('beep'))),
            Align(alignment:Alignment.centerRight,child:TextButton(onPressed:()=>Navigator.pop(context),child:const Text('OK'))),
          ]);
        }),
      );
    });
  }
  Widget _colorGrid(int cross,List<Color> colors,Future<void> Function(Color) onPick){
    return SizedBox(height:120,child:GridView.count(crossAxisCount:cross,mainAxisSpacing:6,crossAxisSpacing:6,
      children:colors.map((c)=>InkWell(onTap:()=>onPick(c),child:Container(
        decoration:BoxDecoration(color:c,borderRadius:BorderRadius.circular(6),border:Border.all(color:Colors.black12)),))).toList()));
  }

  Future<void> _exportJson() async {
    final export={'data':Persist.data.map((k,v)=>MapEntry(k,v.map((e)=>e.toJson()).toList())),'prefs':{'bg':Persist.bgColor.value,'listbg':Persist.listColor.value,'borders':Persist.borders.map((k,v)=>MapEntry(k,v.value)),'lang':I18n.lang,'lastShop':Persist.lastShop,'beep':Persist.beepEnabled}};
    final bytes=utf8.encode(const JsonEncoder.withIndent('  ').convert(export));
    final blob=html.Blob([bytes],'application/json'); final url=html.Url.createObjectUrlFromBlob(blob);
    final a=html.AnchorElement(href:url)..download='smartshop.json'..click(); html.Url.revokeObjectUrl(url);
  }
  Future<void> _importJson() async {
    if(!_guardWrite()) return;
    final input=html.FileUploadInputElement()..accept='application/json'; input.click(); await input.onChange.first;
    final file=input.files?.first; if(file==null) return; final reader=html.FileReader(); reader.readAsText(file); await reader.onLoadEnd.first;
    final text=reader.result?.toString()??''; if(text.isEmpty) return;
    try{ final map=jsonDecode(text) as Map<String,dynamic>;
      Persist.data=(map['data'] as Map<String,dynamic>).map((k,v)=>MapEntry(k,(v as List).map((e)=>ShopItem.fromJson(e as Map<String,dynamic>)).toList()));
      final prefs=map['prefs'] as Map<String,dynamic>? ?? {};
      Persist.bgColor=Color((prefs['bg']??Persist.bgColor.value) as int);
      Persist.listColor=Color((prefs['listbg']??Persist.listColor.value) as int);
      final bd=(prefs['borders']??{}) as Map<String,dynamic>;
      Persist.borders=bd.map((k,v)=>MapEntry(k,Color((v as num).toInt())));
      final l=(prefs['lang']??I18n.lang).toString(); if(I18n.supported.contains(l)) I18n.lang=l;
      Persist.lastShop=(prefs['lastShop']??Persist.lastShop).toString();
      Persist.beepEnabled=(prefs['beep']??Persist.beepEnabled)==true;
      await Persist.save(); await Sync.push(Persist.data); setState((){}); _snack(I18n.t('saved'), color: Colors.green);
    }catch(_){ _snack('Import mislukt', color: Colors.red); }
  }

  @override Widget build(BuildContext context){
    final t=I18n.t;
    final borderColor=Persist.borders[currentShop]??Colors.teal.shade400;
    final items=[..._items]..sort((a,b){ if(a.done!=b.done) return a.done?1:-1; return a.name.toLowerCase().compareTo(b.name.toLowerCase()); });

    return Container(color:Persist.bgColor,child:Scaffold(
      backgroundColor:Colors.transparent,
      appBar:AppBar(
        title: Text(I18n.t('title'), style: const TextStyle(fontWeight: FontWeight.w700)),
        actions:[
          Padding(padding:const EdgeInsets.symmetric(horizontal:6),child:Icon(Sync.online?Icons.circle:Icons.circle_outlined,size:12,color:Sync.online?Colors.green:Colors.red)),
          IconButton(tooltip:'Sync',onPressed:() async { await Sync.pull(); setState((){}); _snack(Sync.online?t('synced'):t('offline'), color: Sync.online?Colors.green:Colors.red); },icon:const Icon(Icons.sync)),
          IconButton(tooltip:t('palette'),onPressed:_showPalette,icon:const Icon(Icons.palette_outlined)),
          PopupMenuButton<String>(tooltip:'Taal',icon:const Icon(Icons.language),
            onSelected:(v) async { I18n.lang=v; await Persist.save(); setState((){}); },
            itemBuilder:(_)=>const[
              PopupMenuItem(value:'nl',child:Text('Nederlands 🇳🇱')),
              PopupMenuItem(value:'en',child:Text('English 🇬🇧')),
              PopupMenuItem(value:'fr',child:Text('Français 🇫🇷')),
              PopupMenuItem(value:'de',child:Text('Deutsch 🇩🇪')),
              PopupMenuItem(value:'es',child:Text('Español 🇪🇸')),
            ]),
          PopupMenuButton<String>(tooltip:'Menu',icon:const Icon(Icons.more_vert),
            onSelected:(v){ if(v=='export') _exportJson(); if(v=='import') _importJson(); },
            itemBuilder:(_)=>[ PopupMenuItem(value:'export',child:Text(t('export'))), PopupMenuItem(value:'import',child:Text(t('import'))), ]),
          IconButton(tooltip:'Thema',onPressed:widget.onToggleTheme,icon:const Icon(Icons.brightness_6)),
        ],
      ),
      body:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        SizedBox(height:44,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:shops.length,separatorBuilder:(_,__)=>const SizedBox(width:8),
          itemBuilder:(_,i){final s=shops[i];final selected=s==currentShop;final sColor=Persist.borders[s]??Colors.teal.shade400;
            return ChoiceChip(label:Text(s),selected:selected,onSelected:(_) async { currentShop=s; Persist.lastShop=s; await Persist.save(); setState((){}); },
              shape:StadiumBorder(side:BorderSide(color:sColor,width:3)), selectedColor:sColor.withOpacity(0.20)); })),
        const SizedBox(height:10),
        Row(children:[
          Expanded(child:TextField(controller:_ctrl,decoration:InputDecoration(hintText:t('hint'),filled:true,border:const OutlineInputBorder(borderSide:BorderSide.none)),
            onSubmitted:(_)=>_add(), enabled: hostMode)),
          const SizedBox(width:8),
          ElevatedButton.icon(onPressed:hostMode?_add:null, icon:const Icon(Icons.add_shopping_cart), label:Text(t('add'))),
        ]),
        const SizedBox(height:12),
        Expanded(child:Container(
          decoration:BoxDecoration(color:Persist.listColor,borderRadius:BorderRadius.circular(12),border:Border.all(color:borderColor.withOpacity(0.85),width:3)),
          child:items.isEmpty?Center(child:Text(t('noItems'))):ListView.separated(padding:const EdgeInsets.all(8),itemCount:items.length,separatorBuilder:(_,__)=>const SizedBox(height:6),
            itemBuilder:(_,i){final it=items[i];final idx=_items.indexOf(it);
              return Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:8),
                decoration:BoxDecoration(color:it.done?Theme.of(context).colorScheme.primaryContainer.withOpacity(0.18):Persist.listColor,
                  borderRadius:BorderRadius.circular(10),border:Border.all(color:borderColor.withOpacity(0.45))),
                child:Row(children:[
                  Checkbox(value:it.done,onChanged:hostMode?(v)=>_toggleDone(idx,v):null),
                  Expanded(child:Text(it.name,style:TextStyle(decoration:it.done?TextDecoration.lineThrough:null,color:it.done?Colors.grey:null))),
                  Row(children:[
                    IconButton(tooltip:'-',onPressed:hostMode?()=>_dec(idx):null,icon:const Icon(Icons.remove_circle_outline)),
                    Text('${it.qty}',style:const TextStyle(fontWeight:FontWeight.w600)),
                    IconButton(tooltip:'+',onPressed:hostMode?()=>_inc(idx):null,icon:const Icon(Icons.add_circle_outline)),
                    IconButton(tooltip:I18n.t('removed'),onPressed:hostMode?()=>_remove(idx):null,icon:const Icon(Icons.delete_outline)),
                  ]),
                ]),
              );}),
        )),
        const SizedBox(height:10),
        Text(I18n.t('summary', vars:{'all':'$_countAll','done':'$_countDone'})),
        const SizedBox(height:8),
        Wrap(spacing:8,runSpacing:8,children:[
          OutlinedButton.icon(onPressed:hostMode?_clearBought:null,icon:const Icon(Icons.check_box),label:Text(I18n.t('clearBought'))),
          OutlinedButton.icon(onPressed:hostMode?_clearAllConfirm:null,icon:const Icon(Icons.delete_sweep_outlined),label:Text(I18n.t('clearAll'))),
        ]),
        if(!hostMode) Padding(padding:const EdgeInsets.only(top:6),child:Text(I18n.t('readonly'),style:TextStyle(color:Colors.orange.shade700))),
      ])),
    ));
  }
}
