import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  MyApp({required this.prefs});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(prefs),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'أذكار',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Sans',
        ),
        home: HomeScreen(),
      ),
    );
  }
}

class AppState extends ChangeNotifier {
  final SharedPreferences prefs;
  List<Zikr> all = [];
  Set<String> favorites = {};
  Map<String,int> counters = {};
  AppState(this.prefs) {
    final favs = prefs.getStringList('favorites') ?? [];
    favorites = favs.toSet();
    final storedCounters = prefs.getString('counters_json');
    if (storedCounters != null) {
      try {
        final Map m = json.decode(storedCounters);
        counters = m.map((k,v) => MapEntry(k as String, v as int));
      } catch(_) {}
    }
  }

  Future<void> loadAzkarFromAssets() async {
    final data = await rootBundle.loadString('assets/azkar.json');
    final list = json.decode(data) as List;
    all = list.map((e) => Zikr.fromMap(e)).toList();
    notifyListeners();
  }

  void toggleFavorite(String id) {
    if (favorites.contains(id)) favorites.remove(id); else favorites.add(id);
    prefs.setStringList('favorites', favorites.toList());
    notifyListeners();
  }

  void resetCounter(String id, [int val = 0]) {
    counters[id] = val;
    _saveCounters();
    notifyListeners();
  }

  void incCounter(String id) {
    counters[id] = (counters[id] ?? 0) + 1;
    _saveCounters();
    notifyListeners();
  }

  void _saveCounters() {
    prefs.setString('counters_json', json.encode(counters));
  }
}

class Zikr {
  final String id;
  final String category;
  final String title;
  final String text;
  final int count;
  final String notes;
  final String source;
  Zikr({
    required this.id, required this.category, required this.title,
    required this.text, required this.count, this.notes = '', this.source = ''
  });
  factory Zikr.fromMap(Map m) => Zikr(
    id: m['id'] ?? UniqueKey().toString(),
    category: m['category'] ?? 'عام',
    title: m['title'] ?? '',
    text: m['text'] ?? '',
    count: (m['count'] is int) ? m['count'] : int.tryParse('${m['count']}') ?? 1,
    notes: m['notes'] ?? '',
    source: m['source'] ?? '',
  );
}

class HomeScreen extends StatefulWidget { @override State<HomeScreen> createState() => _HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  bool loaded = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!loaded) {
      Provider.of<AppState>(context, listen: false).loadAzkarFromAssets().then((_) {
        setState(() { loaded = true; });
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final cats = <String>{ ...state.all.map((e) => e.category) }.toList();
    cats.sort();
    return Scaffold(
      appBar: AppBar(title: Text('أذكار الصباح والمساء'), centerTitle: true),
      body: loaded ? ListView(
        padding: EdgeInsets.all(12),
        children: [
          Text('الأقسام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: cats.map((c) => ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryScreen(category: c))),
              child: Text(c),
            )).toList(),
          ),
          SizedBox(height: 20),
          Text('المفضلة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...state.all.where((z) => state.favorites.contains(z.id)).map((z) => ListTile(
            title: Text(z.title),
            subtitle: Text(z.text, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Icon(Icons.favorite, color: Colors.red),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ZikrScreen(zikr: z))),
          )).toList()
        ],
      ) : Center(child: CircularProgressIndicator()),
    );
  }
}

class CategoryScreen extends StatelessWidget {
  final String category;
  CategoryScreen({required this.category});
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final items = state.all.where((z) => z.category == category).toList();
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) {
          final z = items[i];
          final fav = state.favorites.contains(z.id);
          return ListTile(
            title: Text(z.title),
            subtitle: Text('${z.text.substring(0, (z.text.length>80?80:z.text.length))}...'),
            trailing: IconButton(
              icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav?Colors.red:null),
              onPressed: () => state.toggleFavorite(z.id),
            ),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ZikrScreen(zikr: z))),
          );
        },
      ),
    );
  }
}

class ZikrScreen extends StatefulWidget {
  final Zikr zikr;
  ZikrScreen({required this.zikr});
  @override State<ZikrScreen> createState() => _ZikrScreenState();
}
class _ZikrScreenState extends State<ZikrScreen> {
  late FlutterTts tts;
  bool speaking = false;
  @override
  void initState() {
    super.initState();
    tts = FlutterTts();
  }
  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final id = widget.zikr.id;
    final current = state.counters[id] ?? 0;
    final remaining = (widget.zikr.count - current).clamp(0, widget.zikr.count);
    final isFav = state.favorites.contains(id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.zikr.title),
        actions: [
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav?Colors.red:null),
            onPressed: () => state.toggleFavorite(id),
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => Share.share('${widget.zikr.title}\n\n${widget.zikr.text}'),
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: SingleChildScrollView(child: Text(widget.zikr.text, style: TextStyle(fontSize: 20, height: 1.4)))),
            SizedBox(height: 12),
            Text('تكرار مطلوب: ${widget.zikr.count} — المتبقي: $remaining', textAlign: TextAlign.center),
            SizedBox(height: 8),
            Row(children: [
              Expanded(child: ElevatedButton.icon(
                onPressed: () { state.incCounter(id); },
                icon: Icon(Icons.add), label: Text('عدّاد +1'),
              )),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () { state.resetCounter(id); },
                child: Text('إعادة'),
              )
            ]),
            SizedBox(height: 8),
            Row(children: [
              Expanded(child: ElevatedButton.icon(
                onPressed: () async {
                  await tts.setLanguage('ar-SA');
                  await tts.speak(widget.zikr.text);
                },
                icon: Icon(Icons.volume_up), label: Text('استماع (TTS)'),
              )),
            ])
          ],
        ),
      ),
    );
  }
}
