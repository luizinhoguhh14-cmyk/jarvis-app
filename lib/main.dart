import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JarvisApp());
}

class AppColors extends ChangeNotifier {
  static final AppColors instance = AppColors();
  Color primaryAccent = const Color(0xFF00E5FF);
  Color orbeColor = const Color(0xFF00E5FF);
  bool orbeSegueDestaque = true;

  void updateAccent(Color color) {
    primaryAccent = color;
    if (orbeSegueDestaque) orbeColor = color;
    notifyListeners();
  }
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppColors.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'JARVIS',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF09090B),
            primaryColor: AppColors.instance.primaryAccent,
            colorScheme: ColorScheme.dark(
              primary: AppColors.instance.primaryAccent,
              surface: const Color(0xFF121218),
            ),
          ),
          home: const MainNavigation(),
        );
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _pages = const [JarvisVoiceTab(), TodayTab(), MemoryTab()];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppColors.instance,
      builder: (context, _) {
        final accent = AppColors.instance.primaryAccent;
        return Scaffold(
          body: IndexedStack(index: _currentIndex, children: _pages),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: const Color(0xFF09090B),
            currentIndex: _currentIndex,
            selectedItemColor: accent,
            unselectedItemColor: Colors.white38,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.hexagon_outlined)), label: 'JARVIS'),
              BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.view_list_rounded)), label: 'Today'),
              BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.memory)), label: 'Memory'),
            ],
          ),
        );
      },
    );
  }
}

// --- SERVIÇO DE VOZ (FISH AUDIO) ---
class JarvisVoiceService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  
  final String fishAudioApiKey = const String.fromEnvironment(
    'FISH_AUDIO_API_KEY',
    defaultValue: 'sk-fish-_b2ElwmkHha1WSJDdXMqN0YBdY9u82r0ANBLWLeewM',
  );
  final String referenceId = const String.fromEnvironment(
    'FISH_VOICE_ID',
    defaultValue: '69a0b1c2f7e2433dabac4413ba0a56d7',
  );

  JarvisVoiceService() {
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setPitch(0.85);
    await _flutterTts.setSpeechRate(0.48);
  }

  Future<void> falar(String texto, Function(bool) onSpeakingStateChanged) async {
    onSpeakingStateChanged(true);

    if (fishAudioApiKey.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('https://api.fish.audio/v1/tts'),
          headers: {
            'Authorization': 'Bearer ${fishAudioApiKey.trim()}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'text': texto,
            'reference_id': referenceId,
            'format': 'mp3',
          }),
        );

        if (response.statusCode == 200) {
          Uint8List audioBytes = response.bodyBytes;
          await _audioPlayer.play(BytesSource(audioBytes));
          _audioPlayer.onPlayerComplete.listen((_) {
            onSpeakingStateChanged(false);
          });
          return;
        }
      } catch (_) {}
    }

    try {
      _flutterTts.setCompletionHandler(() => onSpeakingStateChanged(false));
      _flutterTts.setErrorHandler((_) => onSpeakingStateChanged(false));
      await _flutterTts.speak(texto);
    } catch (_) {
      onSpeakingStateChanged(false);
    }
  }

  Future<void> parar() async {
    await _audioPlayer.stop();
    await _flutterTts.stop();
  }
}

// --- ORBE DE POEIRA ESTELAR ---
class OrbeOrganicaPainter extends CustomPainter {
  final double progress;
  final bool isSpeaking;
  final Color baseColor;

  OrbeOrganicaPainter({required this.progress, required this.isSpeaking, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2.6;
    final paint = Paint()..style = PaintingStyle.fill;
    const int totalParticulas = 380;
    final random = Random(1337);

    double rotY = progress * 2 * pi;
    double rotX = progress * pi * 0.5;

    for (int i = 0; i < totalParticulas; i++) {
      double phi = acos(1 - 2 * (i + 0.5) / totalParticulas);
      double theta = sqrt(totalParticulas * pi) * phi;
      double ruidoFrequencia = 3.0 + (i % 5) * 1.2; 
      double ruidoBase = sin(progress * 2 * pi * ruidoFrequencia + random.nextDouble() * 10);
      double vibracao = isSpeaking ? (ruidoBase * 7.5 + (random.nextDouble() - 0.5) * 6.0) : (ruidoBase * 1.5);
      double r = baseRadius + vibracao;

      double x = r * sin(phi) * cos(theta);
      double y = r * sin(phi) * sin(theta);
      double z = r * cos(phi);

      double x1 = x * cos(rotY) - z * sin(rotY);
      double z1 = x * sin(rotY) + z * cos(rotY);
      double y2 = y * cos(rotX) - z1 * sin(rotX);
      double z2 = y * sin(rotX) + z1 * cos(rotX);

      double perspective = 300.0;
      double scale = perspective / (perspective + z2);

      double screenX = center.dx + x1 * scale;
      double screenY = center.dy + y2 * scale;
      double alpha = ((z2 + baseRadius) / (baseRadius * 2.2)).clamp(0.15, 0.95);
      double particleSize = (1.6 * scale).clamp(0.6, 3.2);

      paint.color = baseColor.withOpacity(alpha);
      canvas.drawCircle(Offset(screenX, screenY), particleSize, paint);
    }
  }
  @override
  bool shouldRepaint(covariant OrbeOrganicaPainter oldDelegate) => true;
}

// --- ABA 1: JARVIS VOICE & IA CHAT ---
class JarvisVoiceTab extends StatefulWidget {
  const JarvisVoiceTab({super.key});
  @override
  State<JarvisVoiceTab> createState() => _JarvisVoiceTabState();
}

class _JarvisVoiceTabState extends State<JarvisVoiceTab> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final TextEditingController _inputController = TextEditingController();
  final JarvisVoiceService _voiceService = JarvisVoiceService();
  late stt.SpeechToText _speech;

  bool _isListening = false;
  bool _isJarvisSpeaking = false;
  bool _showChatOverlay = false;
  String _recognizedText = '';
  final List<Map<String, String>> _messages = [];

  final String geminiApiKey = const String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  final String groqApiKey = const String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  Future<String> _obterRespostaIA(String pergunta) async {
    String logErro = "";
    
    if (geminiApiKey.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey.trim()}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [{"parts": [{"text": "Responda curto: $pergunta"}]}]
          }),
        );
        if (response.statusCode == 200) {
          return jsonDecode(response.body)['candidates'][0]['content']['parts'][0]['text'];
        } else {
          logErro += "Gemini HTTP ${response.statusCode}. ";
        }
      } catch (e) {
        logErro += "Gemini Erro: $e. ";
      }
    }

    if (groqApiKey.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer ${groqApiKey.trim()}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "model": "llama3-8b-8192",
            "messages": [{"role": "user", "content": pergunta}]
          }),
        );
        if (response.statusCode == 200) {
          return jsonDecode(response.body)['choices'][0]['message']['content'];
        } else {
          logErro += "Groq HTTP ${response.statusCode}. ";
        }
      } catch (e) {
        logErro += "Groq Erro: $e. ";
      }
    }

    return "ERRO REAL: $logErro";
  }

  Future<void> _toggleMicrophone() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) return;
    }

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (_isListening) {
              setState(() => _isListening = false);
              if (_recognizedText.trim().isNotEmpty) {
                _sendMessage(predefinedText: _recognizedText);
                _recognizedText = '';
              }
            }
          }
        },
        onError: (_) => setState(() => _isListening = false),
      );

      if (available) {
        setState(() { _isListening = true; _recognizedText = ''; });
        _speech.listen(
          localeId: 'pt_BR',
          onResult: (val) => setState(() => _recognizedText = val.recognizedWords),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_recognizedText.trim().isNotEmpty) {
        _sendMessage(predefinedText: _recognizedText);
        _recognizedText = '';
      }
    }
  }

  void _sendMessage({String? predefinedText}) async {
    final text = predefinedText ?? _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": text});
      _inputController.clear();
      _showChatOverlay = true;
    });

    final reply = await _obterRespostaIA(text);

    if (mounted) {
      setState(() {
        _messages.add({"sender": "jarvis", "text": reply});
      });
      _voiceService.falar(reply, (speaking) {
        if (mounted) setState(() => _isJarvisSpeaking = speaking);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.instance.primaryAccent;
    final orbeColor = AppColors.instance.orbeColor;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.access_time, color: Colors.white70), onPressed: () {}),
                Text('JARVIS', style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.5)),
                IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white70), onPressed: () {}),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 260,
            height: 260,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  painter: OrbeOrganicaPainter(progress: _animController.value, isSpeaking: _isJarvisSpeaking, baseColor: orbeColor),
                );
              },
            ),
          ),
          const SizedBox(height: 15),
          if (!_showChatOverlay) ...[
            Text('CHAVES -> Gem: ${geminiApiKey.length > 4 ? geminiApiKey.substring(0,5) : "Erro"} | Groq: ${groqApiKey.length > 4 ? groqApiKey.substring(0,5) : "Erro"} | Fish: ${_voiceService.fishAudioApiKey.length > 4 ? _voiceService.fishAudioApiKey.substring(0,5) : "Erro"}', style: const TextStyle(color: Colors.yellow, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              _isListening ? 'Ouvindo: "$_recognizedText"...' : 'Pressione o microfone para falar',
              style: TextStyle(color: _isListening ? accent : Colors.white54, fontSize: 13),
            ),
          ] else
            Text(
              _isJarvisSpeaking ? '• TRANSMITINDO VOZ •' : (_isListening ? '• OUVINDO SENHOR •' : '• SISTEMA PRONTO •'),
              style: TextStyle(color: (_isJarvisSpeaking || _isListening) ? accent : Colors.white60, fontSize: 12, letterSpacing: 1.5),
            ),
          const Spacer(),
          if (_showChatOverlay)
            Container(
              height: 160,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[_messages.length - 1 - index];
                  final isUser = msg["sender"] == "user";
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isUser ? accent.withOpacity(0.15) : const Color(0xFF1E2638),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isUser ? accent : Colors.white12),
                      ),
                      child: Text(msg["text"] ?? "", style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                if (!_showChatOverlay)
                  IconButton(icon: const Icon(Icons.keyboard_outlined, color: Colors.white60), onPressed: () => setState(() => _showChatOverlay = true)),
                const SizedBox(height: 8),
                if (_showChatOverlay)
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.cyanAccent), onPressed: () {}),
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Digite para o JARVIS...',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFF16161E),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(icon: Icon(Icons.send_rounded, color: accent), onPressed: () => _sendMessage()),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        decoration: const BoxDecoration(color: Color(0xFF16161E), shape: BoxShape.circle),
                        child: IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => setState(() => _showChatOverlay = false)),
                      ),
                      GestureDetector(
                        onTap: _toggleMicrophone,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: _isListening ? 64 : 72,
                          height: _isListening ? 64 : 72,
                          decoration: BoxDecoration(
                            color: _isListening ? Colors.redAccent : const Color(0xFF142C33),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: _isListening ? Colors.redAccent.withOpacity(0.3) : accent.withOpacity(0.3), blurRadius: 12, spreadRadius: 2)
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.stop_rounded : Icons.mic,
                            color: _isListening ? Colors.white : accent,
                            size: 34,
                          ),
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(color: Color(0xFF16161E), shape: BoxShape.circle),
                        child: IconButton(icon: const Icon(Icons.add, color: Colors.white70), onPressed: () {}),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TodayTab extends StatelessWidget {
  const TodayTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Painel Hoje', style: TextStyle(color: Colors.white)));
  }
}

class MemoryTab extends StatelessWidget {
  const MemoryTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Memória', style: TextStyle(color: Colors.white)));
  }
}
