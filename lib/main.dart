import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const JarvisApp());
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JARVIS AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
        primaryColor: Colors.cyanAccent,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    JarvisTab(),
    TodayTab(),
    MemoryTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF121824),
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.white38,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'Jarvis'),
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Hoje'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Memória'),
        ],
      ),
    );
  }
}

class FishAudioService {
  final String apiKey;
  final String referenceId;
  final AudioPlayer _audioPlayer = AudioPlayer();

  FishAudioService({
    this.apiKey = 'sk-fish-_b2ElwmkHha1WSkJDdXMqN0YBdY9u82r0ANBLWLeewM',
    this.referenceId = '69a0b1c2f7e2433dabac4413ba0a56d7',
  });

  Future<void> falar(String texto, Function(bool) onSpeakingStateChanged) async {
    try {
      onSpeakingStateChanged(true);
      final response = await http.post(
        Uri.parse('https://api.fish.audio/v1/tts'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': texto,
          'reference_id': referenceId,
          'format': 'mp3',
        }),
      );

      if (response.statusCode == 200) {
        await _audioPlayer.stop();
        await _audioPlayer.play(BytesSource(response.bodyBytes));
        _audioPlayer.onPlayerComplete.listen((_) {
          onSpeakingStateChanged(false);
        });
      } else {
        onSpeakingStateChanged(false);
      }
    } catch (e) {
      onSpeakingStateChanged(false);
    }
  }
}

class OrbeParticulasPainter extends CustomPainter {
  final double progress;
  final bool isSpeaking;

  OrbeParticulasPainter({required this.progress, required this.isSpeaking});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final random = Random(42);

    final paintPoint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    int totalParticulas = 140;

    for (int i = 0; i < totalParticulas; i++) {
      double angle = (i / totalParticulas) * 2 * pi;
      double distanceRatio = random.nextDouble();

      double noise = isSpeaking 
          ? (sin(progress * 2 * pi * 4 + i) * 12.0) 
          : (sin(progress * 2 * pi + i) * 3.0);

      double r = (radius * distanceRatio) + noise;
      double x = center.dx + r * cos(angle + (isSpeaking ? progress * pi : 0));
      double y = center.dy + r * sin(angle + (isSpeaking ? progress * pi : 0));

      double pointRadius = isSpeaking ? (1.5 + random.nextDouble() * 2.5) : 1.8;
      canvas.drawCircle(Offset(x, y), pointRadius, paintPoint);
    }
  }

  @override
  bool shouldRepaint(covariant OrbeParticulasPainter oldDelegate) => true;
}

// --- ABA 1: JARVIS COM CONFIGURAÇÕES NO HUD ---
class JarvisTab extends StatefulWidget {
  const JarvisTab({super.key});

  @override
  State<JarvisTab> createState() => _JarvisTabState();
}

class _JarvisTabState extends State<JarvisTab> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final String _apiKey = "SUA_CHAVE_DE_API_DO_GEMINI_AQUI"; 
  final FishAudioService _fishAudio = FishAudioService();

  late AnimationController _animController;
  bool _isLoading = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _openSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121824),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CONFIGURAÇÕES DO SISTEMA', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              ListTile(
                leading: const Icon(Icons.key, color: Colors.cyanAccent),
                title: const Text('Chaves de API'),
                subtitle: const Text('Gemini & Fish Audio'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.record_voice_over, color: Colors.cyanAccent),
                title: const Text('Voz do JARVIS'),
                subtitle: const Text('ID de referência configurado'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                title: const Text('Limpar Histórico de Chat', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  setState(() => _messages.clear());
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": text});
      _isLoading = true;
    });
    _controller.clear();

    try {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": text}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() {
          _messages.add({"sender": "jarvis", "text": reply});
        });
        
        _fishAudio.falar(reply, (speaking) {
          setState(() {
            _isSpeaking = speaking;
          });
        });

      } else {
        setState(() {
          _messages.add({"sender": "jarvis", "text": "Erro no sistema de resposta."});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"sender": "jarvis", "text": "Falha de conexão: $e"});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildHudButton(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.cyanAccent, size: 16),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHudButton(Icons.memory, "SYS: 98%"),
                _buildHudButton(Icons.shield, "DEFENSE"),
                _buildHudButton(Icons.settings, "CONFIG", onTap: _openSettingsModal),
              ],
            ),
          ),
          
          const SizedBox(height: 10),

          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(130, 130),
                painter: OrbeParticulasPainter(
                  progress: _animController.value,
                  isSpeaking: _isSpeaking,
                ),
              );
            },
          ),
          
          const SizedBox(height: 8),
          Text(
            _isSpeaking ? 'TRANSMITINDO ÁUDIO...' : 'JARVIS SYSTEM',
            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["sender"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.cyan.withOpacity(0.2) : const Color(0xFF1E2638),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUser ? Colors.cyanAccent : Colors.white12,
                      ),
                    ),
                    child: Text(
                      msg["text"] ?? "",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            ),
            
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: const BoxDecoration(
              color: Color(0xFF0B0E14),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.mic, color: Colors.cyanAccent),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Captura de voz acionada.')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Digite um comando...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1A2232),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.cyanAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- ABA 2: HOJE ---
class TodayTab extends StatelessWidget {
  const TodayTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Aba Hoje (Agenda/Tarefas em breve)', style: TextStyle(color: Colors.white)),
    );
  }
}

// --- ABA 3: MEMÓRIA COM CALENDÁRIO VISUAL ---
class MemoryTab extends StatefulWidget {
  const MemoryTab({super.key});

  @override
  State<MemoryTab> createState() => _MemoryTabState();
}

class _MemoryTabState extends State<MemoryTab> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'REGISTROS E MEMÓRIA',
              style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5),
            ),
            const SizedBox(height: 15),
            
            // Calendário Visual
            CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              onDateChanged: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
            ),
            const Divider(color: Colors.cyanAccent),
            const SizedBox(height: 10),
            
            Text(
              'Memórias gravadas em ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}:',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 10),
            
            Expanded(
              child: ListView(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2638),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
                    ),
                    child: const Text(
                      'Nenhum registro encontrado para esta data.',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
