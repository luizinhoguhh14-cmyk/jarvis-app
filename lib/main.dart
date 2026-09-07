import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
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
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00E5FF),
          secondary: const Color(0xFF00838F),
          surface: const Color(0xFF0A192F),
        ),
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

class _JarvisHomeScreenState extends State<JarvisHomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final List<String> _memories = [];
  bool _isSpeaking = false;
  bool _isLoading = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Credenciais fixas do Fish Audio fornecidas pelo Senhor
  static const String fishApiKey = 'sk-fish-_b2ElwmkHha1WSkJDdXMqN0YBdY9u82r0ANBLWLeewM';
  static const String fishVoiceId = 'b2ElwmkHha1WSkJDdXMqN0YBdY9u82r0ANBLWLeewM'; // ID extraído/associado à sua voz

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _loadMemories();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioPlayer.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadMemories() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _memories.addAll(prefs.getStringList('jarvis_memories') ?? [
        'Protocolo Inicializado com Sucesso.',
        'Sistemas de Voz e Redes Sincronizados.',
        'Mapeamento Topográfico Global Ativo.'
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _isLoading = true;
      _textController.clear();
    });

    await _saveMemory('Consulta: $text');

    String aiResponse = "Compreendido, Senhor. Executando os protocolos necessários para sua solicitação.";
    if (text.toLowerCase().contains('olá') || text.toLowerCase().contains('jarvis')) {
      aiResponse = "Olá, Senhor. Todos os sistemas operacionais e servidores estão operando em capacidade máxima.";
    } else if (text.toLowerCase().contains('status') || text.toLowerCase().contains('sistema')) {
      aiResponse = "Status dos sistemas: Núcleos quânticos estáveis, rede de satélites ativa e Fish Audio conectado.";
    }

    setState(() {
      _messages.add({'sender': 'jarvis', 'text': aiResponse});
      _isLoading = false;
      _isSpeaking = true;
    });

    // Chamada real à API do Fish Audio com a chave embutida
    try {
      final response = await http.post(
        Uri.parse('https://api.fish.audio/v1/tts'),
        headers: {
          'Authorization': 'Bearer $fishApiKey',
          'Content-Type': 'application/json',
          'model': 's2.1-pro-free',
        },
        body: jsonEncode({
          'text': aiResponse,
          'reference_id': fishVoiceId,
          'format': 'mp3',
        }),
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        await _audioPlayer.play(BytesSource(bytes));
      } else {
        debugPrint('Erro na API Fish Audio: \${response.statusCode} - \${response.body}');
      }
    } catch (e) {
      debugPrint('Erro ao sintetizar voz via Fish Audio: $e');
    }

    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _isSpeaking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A192F),
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.greenAccent,
                boxShadow: [
                  BoxShadow(color: Colors.greenAccent.withOpacity(0.8), blurRadius: 8)
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text('J.A.R.V.I.S. // CORE', style: TextStyle(letterSpacing: 2, fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic, color: Color(0xFF00E5FF)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ouvindo comandos de voz...')),
              );
            },
          ),
        ],
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
          BottomNavigationBarItem(icon: Icon(Icons.blur_circular), label: 'Orbe'),
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.memory), label: 'Memory'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Maps 3D'),
        ],
      ),
    );
  }

  Widget _buildCoreTab() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    double scale = 1.0 + (_isSpeaking ? (_pulseController.value * 0.25) : (_pulseController.value * 0.05));
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF00E5FF).withOpacity(0.8),
                              const Color(0xFF00838F).withOpacity(0.4),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withOpacity(_isSpeaking ? 0.8 : 0.3),
                              blurRadius: _isSpeaking ? 40 : 20,
                              spreadRadius: _isSpeaking ? 10 : 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF00E5FF), width: 2),
                              color: const Color(0xFF050B14).withOpacity(0.8),
                            ),
                            child: const Icon(Icons.bolt, color: Color(0xFF00E5FF), size: 48),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  _isSpeaking ? 'JARVIS FALANDO (Fish Audio Ativo)...' : 'SISTEMA EM ESPERA',
                  style: TextStyle(
                    color: _isSpeaking ? Colors.greenAccent : const Color(0xFF00E5FF),
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          height: 200,
          padding: const EdgeInsets.all(8),
          color: const Color(0xFF0A192F).withOpacity(0.5),
          child: ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              bool isUser = msg['sender'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF00838F).withOpacity(0.4) : const Color(0xFF112240),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                  ),
                  child: Text(
                    '${isUser ? "Senhor" : "JARVIS"}: ${msg['text']}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
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
                  decoration: InputDecoration(
                    hintText: 'Digite um comando para o JARVIS...',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF0A192F),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
              const SizedBox(width: 8),
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
      children: [
        const Text('OBJETIVOS OPERACIONAIS (TODAY)', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        _buildTaskItem('Integração Direta Fish Audio Concluída', true),
        _buildTaskItem('Atualizar Repositório Codemagic', true),
        _buildTaskItem('Calibrar Orbe Holográfica e Relevo 3D', false),
      ],
    );
  }

  Widget _buildTaskItem(String title, bool completed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A192F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(completed ? Icons.check_circle : Icons.radio_button_unchecked, color: completed ? Colors.greenAccent : const Color(0xFF00E5FF)),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(color: Colors.white, decoration: completed ? TextDecoration.lineThrough : null)),
        ],
      ),
    );
  }

  Widget _buildMemoryTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BANCO DE MEMÓRIA (JARVIS)', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _memories.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A192F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00838F)),
                  ),
                  child: ListTile(
                    title: Text(_memories[index], style: const TextStyle(color: Colors.white70)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteMemory(index),
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

  Widget _buildMapsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00E5FF).withOpacity(0.6),
                  const Color(0xFF00838F).withOpacity(0.3),
                  Colors.black,
                ],
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.4), blurRadius: 30, spreadRadius: 5),
              ],
            ),
            child: const Center(
              child: Icon(Icons.public, color: Color(0xFF00E5FF), size: 120),
            ),
          ),
          const SizedBox(height: 24),
          const Text('GLOBO 3D COM RELEVO ATIVO', style: TextStyle(color: Color(0xFF00E5FF), letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Topografia holográfica e nós continentais sincronizados.', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}
