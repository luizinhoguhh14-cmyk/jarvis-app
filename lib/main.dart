import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const JarvisApp());
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'J.A.R.V.I.S.',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050B14),
        primaryColor: const Color(0xFF00E5FF),
      ),
      home: const JarvisHomeScreen(),
    );
  }
}

class JarvisHomeScreen extends StatefulWidget {
  const JarvisHomeScreen({super.key});

  @override
  State<JarvisHomeScreen> createState() => _JarvisHomeScreenState();
}

class _JarvisHomeScreenState extends State<JarvisHomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final List<String> _memories = [];

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _memories.addAll(prefs.getStringList('jarvis_memories') ?? [
        'Protocolo Inicializado com Sucesso.',
        'Sistemas de Voz Sincronizados.',
      ]);
    });
  }

  Future<void> _saveMemory(String memory) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _memories.add(memory);
    });
    await prefs.setStringList('jarvis_memories', _memories);
  }

  Future<void> _deleteMemory(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _memories.removeAt(index);
    });
    await prefs.setStringList('jarvis_memories', _memories);
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _messages.add({'sender': 'jarvis', 'text': 'Compreendido, Senhor. Executando diretiva.'});
      _textController.clear();
    });
    _saveMemory('Consulta: $text');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A192F),
        title: const Text('J.A.R.V.I.S.', style: TextStyle(letterSpacing: 2, color: Color(0xFF00E5FF))),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildCoreTab(),
          _buildTodayTab(),
          _buildMemoryTab(),
          _buildMapsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF0A192F),
        selectedItemColor: const Color(0xFF00E5FF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'JARVIS'),
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.memory), label: 'Memory'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Maps'),
        ],
      ),
    );
  }

  Widget _buildCoreTab() {
    return Column(
      children: [
        const Expanded(
          child: Center(
            child: Text('ORBE HOLOGRÁFICA ATIVA', style: TextStyle(color: Color(0xFF00E5FF), letterSpacing: 2, fontWeight: FontWeight.bold)),
          ),
        ),
        Container(
          height: 150,
          color: const Color(0xFF0A192F).withOpacity(0.5),
          child: ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return ListTile(
                title: Text('${msg['sender'] == 'user' ? 'Senhor' : 'JARVIS'}: ${msg['text']}', style: const TextStyle(color: Colors.white70)),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Comando...', hintStyle: TextStyle(color: Colors.white54)),
                  onSubmitted: _sendMessage,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF00E5FF)),
                onPressed: () => _sendMessage(_textController.text),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTodayTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('PROTOCOLOS DE HOJE', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        ListTile(title: Text('Sincronizar APIs', style: TextStyle(color: Colors.white)), leading: Icon(Icons.check_circle, color: Color(0xFF00E5FF))),
      ],
    );
  }

  Widget _buildMemoryTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MEMÓRIA DO JARVIS', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _memories.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_memories[index], style: const TextStyle(color: Colors.white70)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteMemory(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapsTab() {
    return const Center(
      child: Text('GLOBO 3D ATIVO', style: TextStyle(color: Color(0xFF00E5FF), letterSpacing: 2, fontWeight: FontWeight.bold)),
    );
  }
}
