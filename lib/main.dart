import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const PokemonApp());
}

class PokemonApp extends StatelessWidget {
  const PokemonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokemon Champions',
      theme: ThemeData(
        fontFamily: 'DotGothic16',
        brightness: Brightness.dark,
        primaryColor: Colors.red,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 12.0),
          bodyMedium: TextStyle(fontSize: 10.0),
          labelLarge: TextStyle(fontSize: 14.0),
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
          backgroundColor: Colors.black,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _currentTabIndex = 0;
  bool _isLoading = true;
  List<dynamic> _pokedex = [];
  List<int> _capturedIds = [1, 4, 7]; 
  List<Map<String, dynamic>> _party = [];
  
  final String _assetBase = "https://masa-chat-web-app.pages.dev";
  final String _dataUrl = "https://masa-chat-web-app.pages.dev/pokemon_gen1_full_data.json";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await http.get(Uri.parse(_dataUrl));
      if (response.statusCode == 200) {
        setState(() {
          _pokedex = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Data load error: $e");
    }
  }

  int _calculateStat(int base, String type) {
    if (type == 'hp') return (base * 2 + 110).toInt();
    return (base * 2 + 5).toInt();
  }

  void _addToParty(dynamic pokemon, List<String> selectedMoveNames) {
    if (_party.length >= 3) return;
    
    final stats = pokemon['base_stats'];
    final hp = _calculateStat(stats['hp'], 'hp');
    
    setState(() {
      _party.add({
        'id': pokemon['id'],
        'name': pokemon['name_ja'],
        'types': pokemon['types'],
        'front': "$_assetBase/${pokemon['id']}/${pokemon['id']}_FrontDefault.gif",
        'back': "$_assetBase/${pokemon['id']}/${pokemon['id']}_BackDefault.gif",
        'hp': hp,
        'maxHp': hp,
        'atk': _calculateStat(stats['attack'] as int, 'atk'),
        'def': _calculateStat(stats['defense'] as int, 'def'),
        'moves': (pokemon['moves'] as List)
            .where((m) => selectedMoveNames.contains(m['name_ja']))
            .map((m) => {
                  'name': m['name_ja'],
                  'power': m['details']['power'] ?? 0,
                  'type': m['details']['type_en'],
                  'rel': m['details']['damage_relations'],
                  'hitInfo': m['details']['hit_info'],
                })
            .toList(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokemon Champions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildRushScreen(),
          _buildSetupScreen(),
          const Center(child: Text("オンライン対戦（準備中）")),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'とっくん'),
          BottomNavigationBarItem(icon: Icon(Icons.catching_pokemon), label: 'パーティ'),
          BottomNavigationBarItem(icon: Icon(Icons.online_prediction), label: 'たいせん'),
        ],
      ),
    );
  }

  Widget _buildRushScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Captured: ${_capturedIds.length}/151"),
          const SizedBox(height: 20),
          Image.network("https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png", width: 80, filterQuality: FilterQuality.none),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => _startBattle(),
            child: const Text("草むらに入る"),
          ),
        ],
      ),
    );
  }

  void _startBattle() {
    if (_party.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("パーティを組んでください")));
      return;
    }
    
    final wildData = _pokedex[Random().nextInt(151)];
    final s = wildData['base_stats'];
    final hp = _calculateStat(s['hp'] as int, 'hp');
    final opp = {
      'id': wildData['id'],
      'name': wildData['name_ja'],
      'types': wildData['types'],
      'front': "$_assetBase/${wildData['id']}/${wildData['id']}_FrontDefault.gif",
      'hp': hp,
      'maxHp': hp,
      'atk': _calculateStat(s['attack'] as int, 'atk'),
      'def': _calculateStat(s['defense'] as int, 'def'),
      'moves': (wildData['moves'] as List).take(4).map((m) => {
        'name': m['name_ja'],
        'power': m['details']['power'] ?? 0,
        'type': m['details']['type_en'],
        'rel': m['details']['damage_relations'],
        'hitInfo': m['details']['hit_info'],
      }).toList(),
    };

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => BattlePage(
        meParty: json.decode(json.encode(_party)), 
        opp: opp,
        onWin: (id) {
          if (!_capturedIds.contains(id)) {
            setState(() => _capturedIds.add(id));
          }
        },
      ),
    ));
  }

  Widget _buildSetupScreen() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("パーティ（最大3体）"),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              final p = index < _party.length ? _party[index] : null;
              return Container(
                width: 100,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(border: Border.all(color: Colors.white)),
                child: p == null 
                  ? const Center(child: Icon(Icons.add, color: Colors.grey))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(p['front'], height: 60, filterQuality: FilterQuality.none),
                        Text(p['name']),
                        IconButton(icon: const Icon(Icons.close, size: 12), onPressed: () => setState(() => _party.removeAt(index))),
                      ],
                    ),
              );
            },
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
            itemCount: 151,
            itemBuilder: (context, index) {
              final p = _pokedex[index];
              final isCaptured = _capturedIds.contains(p['id']);
              return GestureDetector(
                onTap: isCaptured ? () => _showMoveSelection(p) : null,
                child: Opacity(
                  opacity: isCaptured ? 1.0 : 0.2,
                  child: Card(
                    color: Colors.grey[850],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network("$_assetBase/${p['id']}/${p['id']}_FrontDefault.gif", height: 50, filterQuality: FilterQuality.none),
                        Text(isCaptured ? p['name_ja'] : '???'),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  void _showMoveSelection(dynamic p) {
    if (_party.length >= 3) return;
    List<String> selected = [];
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(p['name_ja']),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: p['moves'].length,
              itemBuilder: (context, index) {
                final m = p['moves'][index];
                final name = m['name_ja'];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 2.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                  ),
                  child: CheckboxListTile(
                    title: Text(name),
                    value: selected.contains(name),
                    onChanged: (val) {
                      setModalState(() {
                        if (val == true && selected.length < 4) {
                          selected.add(name);
                        } else {
                          selected.remove(name);
                        }
                      });
                    },
                    activeColor: Colors.red,
                    checkColor: Colors.white,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("キャンセル")),
            TextButton(
              onPressed: selected.isEmpty ? null : () {
                _addToParty(p, selected);
                Navigator.pop(context);
              },
              child: const Text("決定"),
            ),
          ],
        ),
      ),
    );
  }
}

class BattlePage extends StatefulWidget {
  final List<dynamic> meParty;
  final dynamic opp;
  final Function(int) onWin;

  const BattlePage({super.key, required this.meParty, required this.opp, required this.onWin});

  @override
  State<BattlePage> createState() => _BattlePageState();
}

class _BattlePageState extends State<BattlePage> {
  int _meIdx = 0;
  List<String> _logs = ["やせいの ポケモンが あらわれた！"];
  bool _isTurnProcessing = false;
  bool _isFinished = false;

  void _addLog(String msg) {
    setState(() => _logs.insert(0, msg));
  }

  Future<void> _runTurn(dynamic move) async {
    if (_isTurnProcessing || _isFinished) return;
    setState(() => _isTurnProcessing = true);

    final me = widget.meParty[_meIdx];
    final opp = widget.opp;

    _addLog("${me['name']}の ${move['name']}！");
    await Future.delayed(const Duration(milliseconds: 600));
    final res1 = _calculateDamage(move, me, opp);
    
    setState(() {
      int currentOppHp = (opp['hp'] as num).toInt();
      int dmg = (res1['dmg'] as num).toInt();
      opp['hp'] = max<int>(0, currentOppHp - dmg);
    });

    if (res1['hits'] > 1) _addLog("${res1['hits']}かい ヒットした！");
    if (res1['msg'] != null) _addLog(res1['msg'] as String);

    if ((opp['hp'] as num) <= 0) {
      _addLog("${opp['name']}を たおした！");
      widget.onWin(opp['id'] as int);
      setState(() { _isFinished = true; _isTurnProcessing = false; });
      return;
    }

    await Future.delayed(const Duration(milliseconds: 800));
    final oppMoves = opp['moves'] as List;
    final oppMove = oppMoves[Random().nextInt(oppMoves.length)];
    _addLog("あいての ${oppMove['name']}！");
    await Future.delayed(const Duration(milliseconds: 600));
    final res2 = _calculateDamage(oppMove, opp, me);

    setState(() {
      int currentMeHp = (me['hp'] as num).toInt();
      int dmg = (res2['dmg'] as num).toInt();
      me['hp'] = max<int>(0, currentMeHp - dmg);
    });

    if (res2['hits'] > 1) _addLog("${res2['hits']}かい ヒットした！");
    if (res2['msg'] != null) _addLog(res2['msg'] as String);

    if ((me['hp'] as num) <= 0) {
      _addLog("${me['name']}は たおれた...");
      if (_meIdx < widget.meParty.length - 1) {
        _meIdx++;
        _addLog("ゆけっ！ ${widget.meParty[_meIdx]['name']}！");
      } else {
        _addLog("目の前が 真っ暗になった...");
        setState(() => _isFinished = true);
      }
    }

    setState(() => _isTurnProcessing = false);
  }

  Map<String, dynamic> _calculateDamage(dynamic move, dynamic user, dynamic target) {
    if (move['power'] == 0) return {'dmg': 0, 'hits': 1, 'msg': 'しかし うまくいかなかった！'};

    int hits = 1;
    final hi = move['hitInfo'];
    if (hi != null && hi['min_hits'] != null && hi['max_hits'] != null) {
      hits = Random().nextInt((hi['max_hits'] as int) - (hi['min_hits'] as int) + 1) + (hi['min_hits'] as int);
    }

    double mult = 1.0;
    final List targetTypes = target['types'] as List;
    final rel = move['rel'];
    if (rel != null) {
      for (var t in targetTypes) {
        if (rel['double_damage_to']?.contains(t) ?? false) mult *= 2.0;
        if (rel['half_damage_to']?.contains(t) ?? false) mult *= 0.5;
        if (rel['no_damage_to']?.contains(t) ?? false) mult *= 0.0;
      }
    }

    int totalDmg = 0;
    final double userAtk = (user['atk'] as num).toDouble();
    final double targetDef = (target['def'] as num).toDouble();
    final double movePower = (move['power'] as num).toDouble();
    final baseDmg = ((22.0 * movePower * userAtk / targetDef) / 50.0 + 2.0);
    
    for (int i = 0; i < hits; i++) {
      double rand = (85 + Random().nextInt(16)) / 100.0;
      totalDmg += (baseDmg * mult * rand).floor();
    }

    String? msg;
    if (mult >= 2.0) msg = "こうかは ばつぐんだ！";
    else if (mult > 0 && mult < 1.0) msg = "こうかは いまひとつの ようだ...";
    else if (mult == 0) msg = "こうかが ない みたいだ...";

    return {'dmg': totalDmg, 'hits': hits, 'msg': msg};
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.meParty[_meIdx];
    final opp = widget.opp;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.blueGrey[100],
                child: Stack(
                  children: [
                    Positioned(
                      top: 40, right: 20,
                      child: _buildStatusBox(opp['name'] as String, (opp['hp'] as num).toInt(), (opp['maxHp'] as num).toInt()),
                    ),
                    Positioned(
                      top: 40, left: 40,
                      child: Image.network(opp['front'] as String, width: 120, filterQuality: FilterQuality.none),
                    ),
                    Positioned(
                      bottom: 40, left: 20,
                      child: _buildStatusBox(me['name'] as String, (me['hp'] as num).toInt(), (me['maxHp'] as num).toInt()),
                    ),
                    Positioned(
                      bottom: 20, right: 40,
                      child: Image.network((me['back'] ?? me['front']) as String, width: 150, filterQuality: FilterQuality.none),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, i) => Text(_logs[i]),
                      ),
                    ),
                    const Divider(color: Colors.white),
                    if (!_isFinished)
                      SizedBox(
                        height: 80,
                        child: GridView.count(
                          crossAxisCount: 2,
                          childAspectRatio: 3,
                          children: (me['moves'] as List).map<Widget>((m) => Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: ElevatedButton(
                              onPressed: _isTurnProcessing ? null : () => _runTurn(m),
                              child: Text(m['name'] as String),
                            ),
                          )).toList(),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("戻る"),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBox(String name, int hp, int maxHp) {
    double ratio = (hp / maxHp).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(8),
      width: 160,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name),
          const SizedBox(height: 4),
          Container(
            height: 8,
            width: double.infinity,
            color: Colors.black,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio,
              child: Container(color: ratio > 0.5 ? Colors.green : (ratio > 0.2 ? Colors.orange : Colors.red)),
            ),
          ),
          Text("$hp / $maxHp"),
        ],
      ),
    );
  }
}
