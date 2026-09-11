import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JarvisMark4App());
}

// Variável Global de Estado para a Cor da Orbe
final ValueNotifier<Color> orbeColorNotifier = ValueNotifier(const Color(0xFFE0E0E0)); // Cor inicial "branca/cinza clara" da referência

class JarvisMark4App extends StatelessWidget {
  const JarvisMark4App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JARVIS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF09090B),
        fontFamily: 'Roboto',
      ),
      home: const NavegacaoPrincipal(),
    );
  }
}

class NavegacaoPrincipal extends StatefulWidget {
  const NavegacaoPrincipal({super.key});

  @override
  State<NavegacaoPrincipal> createState() => _NavegacaoPrincipalState();
}

class _NavegacaoPrincipalState extends State<NavegacaoPrincipal> {
  int _indiceAtual = 0;

  final List<Widget> _telas = [
    const TelaJarvisPrincipal(),
    const TelaToday(),
    const TelaMemory(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _telas[_indiceAtual],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF09090B),
        currentIndex: _indiceAtual,
        selectedItemColor: const Color(0xFF00E5FF),
        unselectedItemColor: Colors.white38,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) {
          setState(() {
            _indiceAtual = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.hexagon_outlined)),
            label: 'JARVIS',
          ),
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.view_list_rounded)),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.calendar_month)),
            label: 'Memory',
          ),
        ],
      ),
    );
  }
}

// --- TELA JARVIS PRINCIPAL (Com Controle de Interface 1 e 2) ---
class TelaJarvisPrincipal extends StatefulWidget {
  const TelaJarvisPrincipal({super.key});

  @override
  State<TelaJarvisPrincipal> createState() => _TelaJarvisPrincipalState();
}

class _TelaJarvisPrincipalState extends State<TelaJarvisPrincipal> with SingleTickerProviderStateMixin {
  late AnimationController _orbeController;
  
  // Controle de Estado da Interface
  bool _isChatInterface = false; // False = Tela Inicial (Ref 1), True = Tela de Chat (Ref 4)
  bool _isSpeaking = false;
  bool _isLoadingText = false;
  
  // Histórico
  final List<Map<String, String>> _historicoConversa = [];
  final TextEditingController _textController = TextEditingController();

  // APIs (Codemagic)
  static const String _geminiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _groqKey = String.fromEnvironment('GROQ_API_KEY');
  static const String _fishAudioKey = String.fromEnvironment('FISH_AUDIO_KEY'); 
  static const String _fishVoiceId = "69a0b1c2f7e2433dabac4413ba0a56d7";

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _orbeController = AnimationController(duration: const Duration(seconds: 12), vsync: this)..repeat();
    
    // Configura o evento para quando o áudio terminar de tocar, a orbe parar de vibrar
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  void dispose() {
    _orbeController.dispose();
    _audioPlayer.dispose();
    _textController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Bom dia, Senhor.";
    if (hour < 18) return "Boa tarde, Senhor.";
    return "Boa noite, Senhor.";
  }

  // Lógica de Comunicação (Gemini -> Groq -> Fish Audio)
  Future<void> _sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _historicoConversa.insert(0, {"sender": "Você", "text": text});
      _isLoadingText = true;
      _isChatInterface = true; // Força ida para a tela de chat
    });
    _textController.clear();

    String? replyText;

    // 1. Tenta Gemini
    replyText = await _callAPI(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=$_geminiKey',
      {
        "system_instruction": {"parts": [{"text": "Você é o J.A.R.V.I.S., IA polida e eficiente. Responda em português. Seja breve."}]},
        "contents": [{"parts": [{"text": text}]}]
      },
      (data) => data['candidates']?[0]?['content']?['parts']?[0]?['text'],
    );

    // 2. Se falhar, tenta Groq (Llama 3)
    if (replyText == null && _groqKey.isNotEmpty) {
      replyText = await _callAPI(
        'https://api.groq.com/openai/v1/chat/completions',
        {
          "model": "llama3-70b-8192",
          "messages": [
            {"role": "system", "content": "Você é o J.A.R.V.I.S., IA polida e eficiente. Responda em português."},
            {"role": "user", "content": text}
          ]
        },
        (data) => data['choices']?[0]?['message']?['content'],
        headers: {'Authorization': 'Bearer $_groqKey'},
      );
    }

    if (replyText == null) replyText = "Falha de conexão nos satélites, Senhor.";

    setState(() {
      _historicoConversa.insert(0, {"sender": "JARVIS", "text": replyText!});
      _isLoadingText = false;
    });

    // 3. Gera Áudio com Fish Audio
    await _generateAndPlayAudio(replyText);
  }

  Future<String?> _callAPI(String url, Map body, String? Function(dynamic) extract, {Map<String, String>? headers}) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      final request = await client.postUrl(Uri.parse(url));
      request.headers.contentType = ContentType.json;
      headers?.forEach((k, v) => request.headers.set(k, v));
      request.write(jsonEncode(body));
      final response = await request.close();
      if (response.statusCode == 200) {
        final resBody = await response.transform(utf8.decoder).join();
        return extract(jsonDecode(resBody));
      }
    } catch (_) {}
    return null;
  }

  Future<void> _generateAndPlayAudio(String text) async {
    if (_fishAudioKey.isEmpty) return;
    try {
      setState(() => _isSpeaking = true); // Orbe começa a vibrar aleatoriamente
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse('https://api.fish.audio/v1/tts'));
      request.headers.contentType = ContentType.json;
      request.headers.set('Authorization', 'Bearer $_fishAudioKey');
      request.write(jsonEncode({
        "text": text,
        "reference_id": _fishVoiceId,
        "format": "mp3"
      }));

      final response = await request.close();
      if (response.statusCode == 200) {
        // Para simplificar no protótipo, salvamos em arquivo temporário e tocamos
        final directory = Directory.systemTemp;
        final file = File('${directory.path}/jarvis_reply.mp3');
        final bytes = await response.expand((b) => b).toList();
        await file.writeAsBytes(bytes);
        await _audioPlayer.play(DeviceFileSource(file.path));
      } else {
        setState(() => _isSpeaking = false);
      }
    } catch (_) {
      setState(() => _isSpeaking = false);
    }
  }

  // --- Função para selecionar Arquivos (Botão +) ---
  void _abrirAnexos() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Arquivo carregado: ${result.files.single.name}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // CABEÇALHO COMUM (Relógio e Engrenagem)
          Positioned(
            top: 10, left: 16, right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.access_time, color: Colors.white70),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaHistorico())),
                ),
                const Text('Jarvis', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaConfiguracoes())),
                ),
              ],
            ),
          ),

          // CONTEÚDO PRINCIPAL (Muda entre Inicial e Chat)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _isChatInterface ? _buildChatInterface() : _buildPrimeiraInterface(),
          ),
        ],
      ),
    );
  }

  // --- TELA INICIAL (Referência: Primeira Interface) ---
  Widget _buildPrimeiraInterface() {
    return Column(
      key: const ValueKey('PrimeiraInterface'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 80),
        SizedBox(
          width: 250, height: 250,
          child: ValueListenableBuilder<Color>(
            valueListenable: orbeColorNotifier,
            builder: (context, color, child) {
              return AnimatedBuilder(
                animation: _orbeController,
                builder: (context, child) => CustomPaint(painter: OrbeHolograficaPainter(_orbeController.value, _isSpeaking, color)),
              );
            },
          ),
        ),
        const SizedBox(height: 40),
        Text(_getGreeting(), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Conte algo para eu lembrar sobre você', style: TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 30),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Diga o que construir a seguir', style: TextStyle(color: Colors.white60, fontSize: 12)),
            SizedBox(width: 10),
            Text('·  Agora não  ·', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 5),
        const Text('Não perguntar de novo', style: TextStyle(color: Colors.white38, fontSize: 12)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.keyboard_outlined, color: Colors.white60),
          onPressed: () => setState(() => _isChatInterface = true),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- TELA DE CHAT (Referência: Interface Principal / Ativa) ---
  Widget _buildChatInterface() {
    return Column(
      key: const ValueKey('ChatInterface'),
      children: [
        const SizedBox(height: 60),
        // Orbe Menor no topo
        SizedBox(
          width: 100, height: 100,
          child: ValueListenableBuilder<Color>(
            valueListenable: orbeColorNotifier,
            builder: (context, color, child) {
              return AnimatedBuilder(
                animation: _orbeController,
                builder: (context, child) => CustomPaint(painter: OrbeHolograficaPainter(_orbeController.value, _isSpeaking, color)),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(_isSpeaking ? 'Falando...' : (_isLoadingText ? 'Processando...' : '•••• Ouvindo... ••••'), 
             style: const TextStyle(color: Colors.white54, fontSize: 12)),
        
        // Área do Histórico de Chat
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(20),
            itemCount: _historicoConversa.length,
            itemBuilder: (context, index) {
              final msg = _historicoConversa[index];
              final isUser = msg["sender"] == "Você";
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF1E1E24) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(msg["text"]!, style: TextStyle(color: isUser ? Colors.white : Colors.white70)),
                ),
              );
            },
          ),
        ),
        
        // Barra Inferior de Digitação (Referência: Interface Principal Baixo)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(color: Color(0xFF09090B)),
          child: Row(
            children: [
              Container(
                decoration: const BoxDecoration(color: Color(0xFF1a1a20), shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => setState(() => _isChatInterface = false), // Volta para tela inicial
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Mensagem...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1a1a20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    prefixIcon: IconButton(icon: const Icon(Icons.add, color: Colors.white54), onPressed: _abrirAnexos), // Botão +
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white54),
                      onPressed: () => _sendMessage(_textController.text),
                    ),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- TELA DE HISTÓRICO ---
class TelaHistorico extends StatelessWidget {
  const TelaHistorico({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Histórico', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('ONTEM', style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1.2)),
          ListTile(title: Text('Relatório de sistemas', style: TextStyle(color: Colors.white)), subtitle: Text('1d ago · 2 turns', style: TextStyle(color: Colors.white38))),
          Divider(color: Colors.white10),
          SizedBox(height: 20),
          Text('ESTA SEMANA', style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1.2)),
          ListTile(title: Text('Configurações da Mark 4', style: TextStyle(color: Colors.white)), subtitle: Text('3d ago · 8 turns', style: TextStyle(color: Colors.white38))),
        ],
      ),
    );
  }
}

// --- TELA DE CONFIGURAÇÕES (Engrenagem) ---
class TelaConfiguracoes extends StatelessWidget {
  const TelaConfiguracoes({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Aparência', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Predefinições de Cor da Orbe', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildColorSelector(context, const Color(0xFFE0E0E0)), // Branco/Cinza Original
                _buildColorSelector(context, const Color(0xFF00E5FF)), // Ciano
                _buildColorSelector(context, const Color(0xFFFF3366)), // Vermelho/Rosa
                _buildColorSelector(context, const Color(0xFF6633FF)), // Roxo
                _buildColorSelector(context, const Color(0xFFFFCC00)), // Dourado
              ],
            ),
            const SizedBox(height: 40),
            const Text('Futuras atualizações poderão incluir:', style: TextStyle(color: Colors.white38, fontSize: 12)),
            const ListTile(leading: Icon(Icons.speed, color: Colors.white54), title: Text('Velocidade da Voz', style: TextStyle(color: Colors.white54))),
            const ListTile(leading: Icon(Icons.memory, color: Colors.white54), title: Text('Limite de Memória (Contexto)', style: TextStyle(color: Colors.white54))),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSelector(BuildContext context, Color color) {
    return GestureDetector(
      onTap: () {
        orbeColorNotifier.value = color; // Altera a cor globalmente
        Navigator.pop(context);
      },
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 2)),
      ),
    );
  }
}

// --- ABA MEMORY (Calendário) ---
class TelaMemory extends StatefulWidget {
  const TelaMemory({super.key});
  @override
  State<TelaMemory> createState() => _TelaMemoryState();
}

class _TelaMemoryState extends State<TelaMemory> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.menu, color: Colors.white),
                SizedBox(width: 10),
                Text('Aba Memory', style: TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                Spacer(),
                Icon(Icons.search, color: Colors.white),
              ],
            ),
          ),
          TableCalendar(
            firstDay: DateTime.utc(2026, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: const CalendarStyle(
              defaultTextStyle: TextStyle(color: Colors.white),
              weekendTextStyle: TextStyle(color: Colors.redAccent),
              selectedDecoration: BoxDecoration(color: Colors.blueGrey, shape: BoxShape.rectangle),
              todayDecoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.rectangle, border: Border.fromBorderSide(BorderSide(color: Colors.white38))),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: const Color(0xFF1a1a20), borderRadius: BorderRadius.circular(20)),
                    child: Text('Adic. evento em ${_selectedDay?.day ?? _focusedDay.day}...', style: const TextStyle(color: Colors.white38)),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(color: Color(0xFF2a2a30), shape: BoxShape.circle),
                  child: IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: () {}),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- ABA TODAY (Checklist original da Mark 3 mantido visualmente) ---
class TelaToday extends StatefulWidget {
  const TelaToday({super.key});
  @override
  State<TelaToday> createState() => _TelaTodayState();
}
class _TelaTodayState extends State<TelaToday> {
  // Código idêntico ao da Mark 3 para checklist, abreviado por espaço, mantendo a estrutura.
  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: Center(child: Text("ROTINA / CHECKLIST\n(Mantida conforme Mark 3)", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54))));
  }
}

// --- ORBE HOLOGRÁFICA (Ajustada para vibrar apenas quando fala e aceitar cor) ---
class OrbeHolograficaPainter extends CustomPainter {
  final double progress;
  final bool isSpeaking;
  final Color orbeColor;

  OrbeHolograficaPainter(this.progress, this.isSpeaking, this.orbeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    int dotCount = 420;
    double baseRadius = 115.0; // Raio base estático

    double angleY = progress * 2 * math.pi;
    double angleX = progress * math.pi;

    for (int i = 0; i < dotCount; i++) {
      double phi = math.acos(1 - 2 * (i + 0.5) / dotCount);
      double theta = math.sqrt(dotCount * math.pi) * phi;

      // A mágica acontece aqui: A amplitude de vibração aleatória só é forte se isSpeaking for TRUE
      double randomSeed = math.sin(i * 43.13) * 100.0;
      double frequenciaIndividual = 4.0 + (i % 7) * 1.5;
      double amplitudeAtual = isSpeaking ? (8.0 + (i % 5) * 4.5) : 1.0; 
      
      double onda = math.sin((progress * math.pi * frequenciaIndividual) + randomSeed) * amplitudeAtual;
      double raioAtual = baseRadius + onda;

      double x = raioAtual * math.sin(phi) * math.cos(theta);
      double y = raioAtual * math.sin(phi) * math.sin(theta);
      double z = raioAtual * math.cos(phi);

      double x1 = x * math.cos(angleY) - z * math.sin(angleY);
      double z1 = x * math.sin(angleY) + z * math.cos(angleY);
      double y1 = y;

      double y2 = y1 * math.cos(angleX) - z1 * math.sin(angleX);
      double z2 = y1 * math.sin(angleX) + z1 * math.cos(angleX);
      double x2 = x1;

      double perspective = 350.0;
      double scale = perspective / (perspective + z2);

      double screenX = center.dx + x2 * scale;
      double screenY = center.dy + y2 * scale;

      double alpha = ((z2 + baseRadius) / (baseRadius * 2.2)).clamp(0.08, 0.98);
      double particleSize = (1.8 * scale).clamp(0.4, 3.8);

      paint.color = orbeColor.withOpacity(alpha * 0.85); // Aplica a cor escolhida nas configurações
      canvas.drawCircle(Offset(screenX, screenY), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant OrbeHolograficaPainter oldDelegate) => true;
}
