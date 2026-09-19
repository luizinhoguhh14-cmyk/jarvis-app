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

// --- GERENCIADOR DE ESTADO DE CORES E TEMA ---
class AppColors extends ChangeNotifier {
  static final AppColors instance = AppColors();
  Color primaryAccent = const Color(0xFF00E5FF);
  Color orbeColor = const Color(0xFF00E5FF);
  bool orbeSegueDestaque = true;

  void updateAccent(Color color) {
    primaryAccent = color;
    if (orbeSegueDestaque) {
      orbeColor = color;
    }
    notifyListeners();
  }

  void updateOrbeColor(Color color, bool segueDestaque) {
    orbeSegueDestaque = segueDestaque;
    orbeColor = segueDestaque ? primaryAccent : color;
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

// --- SERVIÇO DE VOZ (FISH AUDIO + FALLBACK FLUTTER_TTS) ---
class JarvisVoiceService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  
  // Insira a sua chave API do Fish Audio aqui quando disponível
  String fishAudioApiKey = ""; 
  String referenceId = ""; 

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
            'Authorization': 'Bearer $fishAudioApiKey',
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
      } catch (_) {
        // Se houver erro na API Fish Audio, ativa o fallback nativo abaixo
      }
    }

    // Fallback nativo
    try {
      _flutterTts.setCompletionHandler(() {
        onSpeakingStateChanged(false);
      });
      _flutterTts.setErrorHandler((_) {
        onSpeakingStateChanged(false);
      });
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
      
      double vibracao = isSpeaking
          ? (ruidoBase * 7.5 + (random.nextDouble() - 0.5) * 6.0)
          : (ruidoBase * 1.5);

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

// --- ABA 1: JARVIS VOICE & CHAT ---
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

  Future<void> _toggleMicrophone() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão de microfone necessária para ouvir o Senhor.')),
          );
        }
        return;
      }
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
        onError: (val) {
          setState(() => _isListening = false);
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
          _recognizedText = '';
        });
        _speech.listen(
          localeId: 'pt_BR',
          onResult: (val) {
            setState(() {
              _recognizedText = val.recognizedWords;
            });
          },
        );
      } else {
        _sendMessage(predefinedText: "Comando de voz do Senhor.");
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Bom dia, Senhor.';
    if (hour >= 12 && hour < 18) return 'Boa tarde, Senhor.';
    return 'Boa noite, Senhor.';
  }

  void _sendMessage({String? predefinedText}) {
    final text = predefinedText ?? _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": text});
      _inputController.clear();
      _showChatOverlay = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      final reply = "Comando recebido, Senhor. Todos os sistemas de voz, áudio e captura do microfone estão operando perfeitamente.";
      setState(() {
        _messages.add({"sender": "jarvis", "text": reply});
      });
      
      _voiceService.falar(reply, (speaking) {
        if (mounted) setState(() => _isJarvisSpeaking = speaking);
      });
    });
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
            Text(_getGreeting(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              _isListening ? 'Ouvindo o Senhor: "$_recognizedText"...' : 'Pressione o microfone para falar',
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

// --- ABA 2: TODAY ---
class TodayTab extends StatefulWidget {
  const TodayTab({super.key});
  @override
  State<TodayTab> createState() => _TodayTabState();
}
class _TodayTabState extends State<TodayTab> {
  final List<Map<String, dynamic>> _tarefas = [
    {"titulo": "Revisar protocolos táticos", "horario": "09:00", "concluido": true},
    {"titulo": "Sincronizar dados de memória", "horario": "14:30", "concluido": false},
  ];
  final TextEditingController _taskController = TextEditingController();
  void _addTarefa() {
    if (_taskController.text.trim().isEmpty) return;
    setState(() {
      _tarefas.add({"titulo": _taskController.text.trim(), "horario": "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}", "concluido": false});
      _taskController.clear();
    });
  }
  @override
  Widget build(BuildContext context) {
    final accent = AppColors.instance.primaryAccent;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PAINEL HOJE', style: TextStyle(color: accent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 6),
            const Text('Gerenciamento de rotina e prioridades do dia.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: TextField(controller: _taskController, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Nova tarefa ou protocolo...', hintStyle: const TextStyle(color: Colors.white38, fontSize: 13), filled: true, fillColor: const Color(0xFF121218), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF22222E)))))),
                const SizedBox(width: 10),
                IconButton(icon: Icon(Icons.add_box_rounded, color: accent, size: 36), onPressed: _addTarefa),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _tarefas.length,
                itemBuilder: (context, index) {
                  final item = _tarefas[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: const Color(0xFF121218), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF22222E))),
                    child: ListTile(
                      leading: IconButton(icon: Icon(item["concluido"] ? Icons.check_circle : Icons.radio_button_unchecked, color: item["concluido"] ? accent : Colors.white38), onPressed: () => setState(() => item["concluido"] = !item["concluido"])),
                      title: Text(item["titulo"], style: TextStyle(color: item["concluido"] ? Colors.white38 : Colors.white, decoration: item["concluido"] ? TextDecoration.lineThrough : null)),
                      subtitle: Text(item["horario"], style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20), onPressed: () => setState(() => _tarefas.removeAt(index))),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ABA 3: MEMORY ---
class MemoryTab extends StatefulWidget {
  const MemoryTab({super.key});
  @override
  State<MemoryTab> createState() => _MemoryTabState();
}
class _MemoryTabState extends State<MemoryTab> {
  DateTime _currentMonth = DateTime(2026, 8, 1);
  DateTime? _selectedDate;
  final Map<String, List<Map<String, dynamic>>> _eventos = {
    "2026-8-9": [{"titulo": "Dia dos Pais", "cor": Colors.green}],
    "2026-8-30": [{"titulo": "Estudar Inglês", "cor": Colors.blue}],
  };
  void _previousMonth() { if (_currentMonth.year > 2026 || _currentMonth.month > 1) setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1)); }
  void _nextMonth() { if (_currentMonth.year < 2030) setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1)); }
  String _getMonthName(int month) { const meses = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ']; return meses[month - 1]; }
  @override
  Widget build(BuildContext context) {
    final accent = AppColors.instance.primaryAccent;
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white70), onPressed: _previousMonth),
                Text('${_getMonthName(_currentMonth.month)}. ${_currentMonth.year}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white70), onPressed: _nextMonth),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [Text('D', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)), Text('S', style: TextStyle(color: Colors.white70)), Text('T', style: TextStyle(color: Colors.white70)), Text('Q', style: TextStyle(color: Colors.white70)), Text('Q', style: TextStyle(color: Colors.white70)), Text('S', style: TextStyle(color: Colors.white70)), Text('S', style: TextStyle(color: Colors.white70))],
            ),
            const Divider(color: Colors.white12, height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.85),
                itemCount: firstWeekday + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < firstWeekday) return const SizedBox.shrink();
                  final dayNumber = index - firstWeekday + 1;
                  final isSunday = (index % 7) == 0;
                  final eventKey = "${_currentMonth.year}-${_currentMonth.month}-$dayNumber";
                  final temEvento = _eventos.containsKey(eventKey);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, dayNumber)),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: const Color(0xFF101016), borderRadius: BorderRadius.circular(6), border: Border.all(color: _selectedDate?.day == dayNumber && _selectedDate?.month == _currentMonth.month ? accent : Colors.white.withOpacity(0.05))),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$dayNumber', style: TextStyle(color: isSunday ? Colors.redAccent : Colors.white, fontWeight: FontWeight.w500)),
                          if (temEvento) Container(margin: const EdgeInsets.only(top: 4), width: 6, height: 6, decoration: BoxDecoration(color: _eventos[eventKey]![0]['cor'], shape: BoxShape.circle)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
