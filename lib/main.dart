import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  try {
    await FirebaseAuth.instance.signInAnonymously();
    debugPrint("Signed in with temp user.");
  } catch (e) {
    debugPrint("Failed to sign in anonymously: $e");
  }
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
  List<int> _capturedIds = [1, 4, 7, 25, 133, 143];
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
    if (_party.length >= 6) return;
    
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
        'stat_modifiers': {
          'attack': 0,
          'defense': 0,
        },
        'moves': (pokemon['moves'] as List)
            .where((m) => selectedMoveNames.contains(m['name_ja']))
            .map((m) => {
                  'name': m['name_ja'],
                  'details': m['details']
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
          _buildOnlineBattleScreen(),
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
          Text("捕まえた数: ${_capturedIds.length}/151"),
          const SizedBox(height: 20),
          Image.network("https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png", width: 80, filterQuality: FilterQuality.none),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => _startWildBattle(),
            child: const Text("草むらに入る"),
          ),
        ],
      ),
    );
  }

  void _startWildBattle() {
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
      'stat_modifiers': {
        'attack': 0,
        'defense': 0,
      },
      'moves': (wildData['moves'] as List).take(4).map((m) => {
        'name': m['name_ja'],
        'details': m['details']
      }).toList(),
    };

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => OnlineBattlePage( // Changed to OnlineBattlePage for consistency, but logic will be different
        roomId: "wild_battle_${DateTime.now().millisecondsSinceEpoch}", // Not a real room
        isWildBattle: true,
        initialMeParty: json.decode(json.encode(_party.sublist(0, min(3, _party.length)))),
        initialOppParty: [opp],
        assetBase: _assetBase,
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
          child: Text("パーティ（最大6体）"),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
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
    if (_party.length >= 6) return;
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
                    subtitle: Text("威力: ${m['details']['power'] ?? '-'} | ${m['details']['type_ja']}"),
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
              onPressed: selected.length > 0 && selected.length <= 4 ? () {
                _addToParty(p, selected);
                Navigator.pop(context);
              } : null,
              child: const Text("決定"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineBattleScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("オンライン対戦"),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_party.length < 3) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("対戦には3体以上のポケモンが必要です")));
                return;
              }
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => OnlineLobbyScreen(party: _party, assetBase: _assetBase)
              ));
            },
            child: const Text("トレーナーと対戦"),
          ),
        ],
      ),
    );
  }
}

class OnlineLobbyScreen extends StatelessWidget {
  final List<Map<String, dynamic>> party;
  final String assetBase;
  const OnlineLobbyScreen({super.key, required this.party, required this.assetBase});

  Future<void> _createBattleRoom(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final room = await FirebaseFirestore.instance.collection('battle_rooms').add({
      'player1Id': currentUser.uid,
      'player1Name': 'トレーナー1', // You can add a name field later
      'player1Party': party.sublist(0, 3),
      'player2Id': null,
      'player2Name': null,
      'player2Party': null,
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
      'turn': currentUser.uid, 
      'logs': [
        '対戦相手を待っています...'
      ],
      'player1_active_index': 0,
      'player2_active_index': 0,
      'last_move_p1': null,
      'last_move_p2': null,
    });

    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => OnlineBattlePage(roomId: room.id, assetBase: assetBase),
    ));
  }

  Future<void> _joinBattleRoom(BuildContext context, String roomId, Map<String, dynamic> roomData) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await FirebaseFirestore.instance.collection('battle_rooms').doc(roomId).update({
      'player2Id': currentUser.uid,
      'player2Name': 'トレーナー2',
      'player2Party': party.sublist(0, 3),
      'status': 'in_progress',
      'logs': FieldValue.arrayUnion(['${roomData['player1Name']} は しょうぶをしかけてきた！'])
    });

    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => OnlineBattlePage(roomId: roomId, assetBase: assetBase),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("オンラインロビー")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              onPressed: () => _createBattleRoom(context),
              child: const Text("対戦部屋を作成する"),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("待機中の部屋"),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('battle_rooms')
                  .where('status', isEqualTo: 'waiting')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final rooms = snapshot.data!.docs;
                if (rooms.isEmpty) return const Center(child: Text("待機中の部屋がありません"));

                return ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final roomData = room.data() as Map<String, dynamic>;
                    if (roomData['player1Id'] == FirebaseAuth.instance.currentUser?.uid) {
                       return const SizedBox.shrink(); // Don't show your own room
                    }
                    return Card(
                      child: ListTile(
                        title: Text("${roomData['player1Name'] ?? 'P1'}の部屋"),
                        subtitle: Text("タップして参加する"),
                        onTap: () => _joinBattleRoom(context, room.id, roomData),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class OnlineBattlePage extends StatefulWidget {
  final String roomId;
  final String assetBase;
  final bool isWildBattle;
  final List<dynamic>? initialMeParty;
  final List<dynamic>? initialOppParty;
  final Function(int)? onWin;

  const OnlineBattlePage({
    super.key,
    required this.roomId,
    required this.assetBase,
    this.isWildBattle = false,
    this.initialMeParty,
    this.initialOppParty,
    this.onWin,
  });

  @override
  State<OnlineBattlePage> createState() => _OnlineBattlePageState();
}

class _OnlineBattlePageState extends State<OnlineBattlePage> {
  final Map<int, double> _statStageMultipliers = {
    -6: 2/8, -5: 2/7, -4: 2/6, -3: 2/5, -2: 2/4, -1: 2/3,
    0: 1.0,
    1: 3/2, 2: 4/2, 3: 5/2, 4: 6/2, 5: 7/2, 6: 8/2,
  };

  Future<void> _runTurn(Map<String, dynamic> roomData, dynamic move) async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final isPlayer1 = roomData['player1Id'] == currentUser.uid;
    if (roomData['turn'] != currentUser.uid || roomData['status'] != 'in_progress') return;

    final moveKey = isPlayer1 ? 'last_move_p1' : 'last_move_p2';
    final otherPlayerMoveKey = isPlayer1 ? 'last_move_p2' : 'last_move_p1';
    final otherPlayerId = isPlayer1 ? roomData['player2Id'] : roomData['player1Id'];

    // Store my move
    await FirebaseFirestore.instance.collection('battle_rooms').doc(widget.roomId).update({ moveKey: move });

    // Check if other player has moved
    final otherMove = roomData[otherPlayerMoveKey];
    if (otherMove != null) {
      await _processTurn(roomData, move, otherMove, isPlayer1);
    } else {
      // wait for other player
      await FirebaseFirestore.instance.collection('battle_rooms').doc(widget.roomId).update({'logs': FieldValue.arrayUnion(['相手の選択を待っています...'])});
    }
  }
  
  Future<void> _processTurn(Map<String, dynamic> roomData, dynamic p1Move, dynamic p2Move, bool amIPlayer1) async {
    
    final p1 = roomData['player1Party'][roomData['player1_active_index']];
    final p2 = roomData['player2Party'][roomData['player2_active_index']];
    List<String> newLogs = [];

    // This is a simplified version; a real game would have speed checks
    // Player 1 goes first, then Player 2

    // Player 1's Move
    _processMove(p1Move, p1, p2, (roomData['player1Party'] as List), (roomData['player2Party'] as List), newLogs);
    int p2newIdx = (p2['hp'] <= 0) ? roomData['player2_active_index'] + 1 : roomData['player2_active_index'];

    if (p2newIdx >= roomData['player2Party'].length) {
        newLogs.add("しょうぶに かった！");
        await FirebaseFirestore.instance.collection('battle_rooms').doc(widget.roomId).update({
            'status': amIPlayer1 ? 'p1_wins' : 'p2_loses',
            'logs': FieldValue.arrayUnion(newLogs),
        });
        return;
    }

    // Player 2's Move (if not fainted)
    if (p2['hp'] > 0) {
      _processMove(p2Move, p2, p1, (roomData['player2Party'] as List), (roomData['player1Party'] as List), newLogs);
    }
    int p1newIdx = (p1['hp'] <= 0) ? roomData['player1_active_index'] + 1 : roomData['player1_active_index'];
    
    if (p1newIdx >= roomData['player1Party'].length) {
        newLogs.add("目の前が 真っ暗になった...");
        await FirebaseFirestore.instance.collection('battle_rooms').doc(widget.roomId).update({
            'status': amIPlayer1 ? 'p1_loses' : 'p2_wins',
            'logs': FieldValue.arrayUnion(newLogs),
        });
        return;
    }

    // Update Firestore with the results of the turn
    await FirebaseFirestore.instance.collection('battle_rooms').doc(widget.roomId).update({
        'player1Party': roomData['player1Party'],
        'player2Party': roomData['player2Party'],
        'player1_active_index': p1newIdx,
        'player2_active_index': p2newIdx,
        'logs': FieldValue.arrayUnion(newLogs),
        'last_move_p1': null, // Reset moves
        'last_move_p2': null,
        'turn': roomData['turn'] == roomData['player1Id'] ? roomData['player2Id'] : roomData['player1Id'], // Swap turns
    });
  }

  void _processMove(dynamic move, dynamic user, dynamic target, List userParty, List targetParty, List<String> logs) {
    final moveName = move['name'];
    final userName = user['name'];
    final targetName = target['name'];

    logs.add("$userName の $moveName！");

    final details = move['details'];
    final category = details['category']['name'];

    if (category == 'damage' || category.startsWith('damage+')) {
      final res = _calculateDamage(move, user, target);
      target['hp'] = max<int>(0, (target['hp'] as num).toInt() - (res['dmg'] as num).toInt());
      if (res['msg'] != null) logs.add(res['msg'] as String);

    } else if (category == 'net-good-stats') {
      _applyStatChange(move, user, target, logs);
    } else {
      logs.add("しかし うまくいかなかった！");
    }

    if ((target['hp'] as num) <= 0) {
      logs.add("$targetName は たおれた！");
    }
  }

  void _applyStatChange(dynamic move, dynamic user, dynamic target, List<String> logs) {
    final details = move['details'];
    final moveTarget = details['target']['name'];
    final statChanges = details['stat_changes'] as List;
    final affectedPokemon = (moveTarget == 'user') ? user : target;

    for (var change in statChanges) {
      final statName = (change['stat']['name'] as String).replaceFirst('special-','');
      if (!affectedPokemon['stat_modifiers'].containsKey(statName)) continue;

      final changeAmount = change['change'] as int;
      int currentStage = affectedPokemon['stat_modifiers'][statName];
      int newStage = (currentStage + changeAmount).clamp(-6, 6);

      if (newStage == currentStage) {
        logs.add("${affectedPokemon['name']}の ${_getStatName(statName)} は これ以上 かわらない！");
      } else {
        affectedPokemon['stat_modifiers'][statName] = newStage;
        String verb = changeAmount > 0 ? "あがった" : "さがった";
        logs.add("${affectedPokemon['name']}の ${_getStatName(statName)} が$verb！");
      }
    }
  }

  Map<String, dynamic> _calculateDamage(dynamic move, dynamic user, dynamic target) {
    final details = move['details'];
    if ((details['power'] ?? 0) == 0) return {'dmg': 0, 'hits': 1, 'msg': null};

    int hits = 1;
    final hi = details['hit_info'];
    if (hi != null && hi['min_hits'] != null && hi['max_hits'] != null) {
      hits = Random().nextInt((hi['max_hits'] as int) - (hi['min_hits'] as int) + 1) + (hi['min_hits'] as int);
    }

    double mult = 1.0;
    final List targetTypes = target['types'] as List;
    final rel = details['damage_relations'];
    if (rel != null) {
      for (var t in targetTypes) {
        if (rel['double_damage_to']?.contains(t) ?? false) mult *= 2.0;
        if (rel['half_damage_to']?.contains(t) ?? false) mult *= 0.5;
        if (rel['no_damage_to']?.contains(t) ?? false) mult *= 0.0;
      }
    }

    final atkStg = user['stat_modifiers']['attack'] as int;
    final defStg = target['stat_modifiers']['defense'] as int;

    final double userAtk = (user['atk'] as num).toDouble() * _statStageMultipliers[atkStg]!;
    final double targetDef = (target['def'] as num).toDouble() * _statStageMultipliers[defStg]!;
    final double movePower = (details['power'] as num).toDouble();
    
    int totalDmg = 0;
    for (int i = 0; i < hits; i++) {
      final baseDmg = ((22.0 * movePower * userAtk / targetDef) / 50.0 + 2.0);
      double rand = (85 + Random().nextInt(16)) / 100.0;
      totalDmg += (baseDmg * mult * rand).floor();
    }

    String? msg;
    if (mult >= 2.0) msg = "こうかは ばつぐんだ！";
    else if (mult > 0 && mult < 1.0) msg = "こうかは いまひとつの ようだ...";
    else if (mult == 0) msg = "こうかが ない みたいだ...";

    return {'dmg': totalDmg, 'hits': hits, 'msg': msg};
  }
   String _getStatName(String stat) {
    if (stat == 'attack') return 'こうげき';
    if (stat == 'defense') return 'ぼうぎょ';
    return stat;
  }


  @override
  Widget build(BuildContext context) {
    if (widget.isWildBattle) {
        // Simplified wild battle can remain as-is for now
        return const Scaffold(body: Center(child: Text("Wild Battle not implemented in online version")));
    }
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Scaffold(body: Center(child: Text("Not logged in")));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('battle_rooms').doc(widget.roomId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final roomData = snapshot.data!.data() as Map<String, dynamic>;
        final status = roomData['status'];

        if (status == 'waiting') {
          return const Scaffold(body: Center(child: Text("対戦相手を待っています...")));
        }

        final bool isPlayer1 = roomData['player1Id'] == currentUser.uid;
        final meParty = isPlayer1 ? roomData['player1Party'] : roomData['player2Party'];
        final oppParty = isPlayer1 ? roomData['player2Party'] : roomData['player1Party'];
        final meIdx = isPlayer1 ? roomData['player1_active_index'] : roomData['player2_active_index'];
        final oppIdx = isPlayer1 ? roomData['player2_active_index'] : roomData['player1_active_index'];
        
        if (meParty == null || oppParty == null) {
            return const Scaffold(body: Center(child: Text("パーティ情報がありません")));
        }

        final me = meParty[meIdx];
        final opp = oppParty[oppIdx];
        final logs = (roomData['logs'] as List).cast<String>();
        final bool isMyTurn = roomData['turn'] == currentUser.uid;
        final bool isFinished = status.contains('wins') || status.contains('loses');

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
                      alignment: Alignment.center,
                      children: [
                        Positioned(top: 10, right: 10, child: _buildStatusBox(opp, true)),
                        Positioned(bottom: 10, left: 10, child: _buildStatusBox(me, false)),
                        Positioned(top: 50, left: 150, child: Image.network(opp['front'] as String, width: 140, filterQuality: FilterQuality.none, fit: BoxFit.contain)),
                        Positioned(bottom: 50, right: 150, child: Image.network(me['back'] as String, width: 160, filterQuality: FilterQuality.none, fit: BoxFit.contain)),
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
                            reverse: true,
                            itemCount: logs.length,
                            itemBuilder: (context, i) => Text(logs[i]),
                          ),
                        ),
                        const Divider(color: Colors.white),
                        if (!isFinished)
                          SizedBox(
                            height: 100,
                            child: GridView.count(
                              crossAxisCount: 2,
                              childAspectRatio: 3.5,
                              children: (me['moves'] as List).map<Widget>((m) => Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: ElevatedButton(
                                  onPressed: isMyTurn ? () => _runTurn(roomData, m) : null,
                                  child: Text(m['name'] as String, textAlign: TextAlign.center),
                                ),
                              )).toList(),
                            ),
                          )
                        else
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                            child: const Text("トップに戻る"),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBox(dynamic p, bool isOpponent) {
    final hp = p['hp'] as num;
    final maxHp = p['maxHp'] as num;
    double ratio = maxHp > 0 ? (hp / maxHp).clamp(0.0, 1.0) : 0;
    return Container(
      padding: const EdgeInsets.all(8),
      width: 180,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Colors.black,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: ratio > 0.5 ? Colors.green : (ratio > 0.2 ? Colors.orange : Colors.red),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text("$hp / $maxHp"),
        ],
      ),
    );
  }
}

// Placeholder for old BattlePage to avoid breaking wild battles completely
class BattlePage extends StatelessWidget {
  const BattlePage({super.key, required this.meParty, required this.oppParty, required this.assetBase, required this.onWin, required this.isWildBattle, this.fullMeParty, this.fullOppParty});
  final List<dynamic> meParty;
  final List<dynamic> oppParty;
  final String assetBase;
  final Function(int) onWin;
  final bool isWildBattle;
  final List<dynamic>? fullMeParty;
  final List<dynamic>? fullOppParty;
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("This page is for local battles only.")));
  }
}
