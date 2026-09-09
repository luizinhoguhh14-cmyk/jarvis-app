import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JarvisAppClone());
}

class JarvisAppClone extends StatelessWidget {
  const JarvisAppClone({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JARVIS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050301),
        primaryColor: const Color(0xFFFF8C00),
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
  int indiceAtual = 0;

  final List<Widget> telas = [
    const TelaJarvisVoice(),
    const TelaToday(),
    const TelaMemory(),
    const TelaRadar(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: telas[indiceAtual],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF050301),
        currentIndex: indiceAtual,
        selectedItemColor: const Color(0xFFFF8C00),
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) {
          setState(() {
            indiceAtual = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.blur_circular),
            label: 'Jarvis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list_rounded),
            label: 'Today',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.memory), label: 'Memory'),
          BottomNavigationBarItem(
            icon: Icon(Icons.radar),
            label: 'Radar',
          ),
        ],
      ),
    );
  }
}

class TelaJarvisVoice extends StatefulWidget {
  const TelaJarvisVoice({super.key});

  @override
  State<TelaJarvisVoice> createState() => _TelaJarvisVoiceState();
}

class _TelaJarvisVoiceState extends State<TelaJarvisVoice>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  bool jarvisFalando = false;
  bool mostrandoTeclado = false;
  final TextEditingController _textController = TextEditingController();

  static const String _apiKey = String.fromEnvironment("GEMINI_API_KEY");

  final List<Map<String, dynamic>> _mensagensChat = [
    {
      "sender": "Jarvis",
      "text": "Sistemas online, Senhor. Como posso ajudar?",
      "showRadar": false,
    },
  ];

  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _enviarParaGemini(String texto) async {
    if (texto.trim().isEmpty) return;

    final comandoEnviado = texto;
    final bool pedeRadar =
        comandoEnviado.toLowerCase().contains("mapa") ||
        comandoEnviado.toLowerCase().contains("onde estou") ||
        comandoEnviado.toLowerCase().contains("radar") ||
        comandoEnviado.toLowerCase().contains("localização");

    setState(() {
      _carregando = true;
      jarvisFalando = true;
      _mensagensChat.add({
        "sender": "Você",
        "text": comandoEnviado,
        "showRadar": false,
      });
    });

    _textController.clear();

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey',
      );

      final client = HttpClient();
      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": "Aja como J.A.R.V.I.S., assistente de elite do Tony Stark. Seja polido, sarcástico e chame o usuário de Senhor. Responda em PT-BR: $comandoEnviado"},
            ],
          },
        ],
      }));

      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        final aiResponse = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() {
          _mensagensChat.add({
            "sender": "Jarvis",
            "text": aiResponse,
            "showRadar": pedeRadar,
          });
        });
      } else {
        setState(() {
          _mensagensChat.add({
            "sender": "Jarvis",
            "text": "Erro nos servidores centrais, Senhor.",
            "showRadar": false,
          });
        });
      }
    } catch (e) {
      setState(() {
        _mensagensChat.add({
          "sender": "Jarvis",
          "text": "Comando recebido e processado localmente, Senhor.",
          "showRadar": pedeRadar,
        });
      });
    } finally {
      setState(() {
        _carregando = false;
        jarvisFalando = false;
        mostrandoTeclado = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48),
                const Text(
                  'J.A.R.V.I.S.',
                  style: TextStyle(
                    color: Color(0xFFFF8C00),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          SizedBox(
            width: 140,
            height: 140,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) => CustomPaint(
                painter: OrbeHolograficaPainter(controller.value, jarvisFalando),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _mensagensChat.length,
              itemBuilder: (context, index) {
                final msg = _mensagensChat[index];
                final isUser = msg["sender"] == "Você";
                final showRadar = msg["showRadar"] == true;

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF261A0A) : const Color(0xFF120E0A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUser
                            ? const Color(0xFFFF8C00).withOpacity(0.5)
                            : const Color(0xFF332211),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg["sender"],
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFFF8C00),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          msg["text"],
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        if (showRadar)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFF8C00)),
                            ),
                            child: const Center(
                              child: Text(
                                'RADAR TÁTICO ATIVO\n[Área Mapeada com Sucesso]',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFFFF8C00), fontSize: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_carregando)
            const LinearProgressIndicator(
              color: Color(0xFFFF8C00),
              backgroundColor: Colors.transparent,
            ),
          if (!mostrandoTeclado) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_outlined, color: Colors.white60, size: 28),
                    onPressed: () => setState(() => mostrandoTeclado = true),
                  ),
                  const SizedBox(width: 40),
                  GestureDetector(
                    onTap: () => setState(() => jarvisFalando = !jarvisFalando),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: jarvisFalando ? const Color(0xFFFF8C00) : const Color(0xFF261A0A),
                      child: Icon(
                        jarvisFalando ? Icons.mic_off : Icons.mic,
                        color: jarvisFalando ? Colors.black : const Color(0xFFFF8C00),
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                  const SizedBox(width: 28),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_hide, color: Colors.white60),
                    onPressed: () => setState(() => mostrandoTeclado = false),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Comando...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF120E0A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onSubmitted: (val) => _enviarParaGemini(val),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFFFF8C00)),
                    onPressed: () => _enviarParaGemini(_textController.text),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TelaRadar extends StatelessWidget {
  const TelaRadar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'RADAR GLOBAL TÁTICO',
              style: TextStyle(
                color: Color(0xFFFF8C00),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF050301),
                border: Border.all(
                  color: const Color(0xFFFF8C00).withOpacity(0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.radar, size: 80, color: Color(0xFFFF8C00)),
                    SizedBox(height: 16),
                    Text(
                      'VARREDURA DE SATÉLITE ATIVA',
                      style: TextStyle(color: Colors.white, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sistemas de geolocalização operando em modo seguro, Senhor.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TelaToday extends StatelessWidget {
  const TelaToday({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: Text("PROTOCOLOS DIÁRIOS", style: TextStyle(color: Color(0xFFFF8C00), letterSpacing: 1.5)),
  );
}

class TelaMemory extends StatelessWidget {
  const TelaMemory({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: Text("MEMORY MATRIX", style: TextStyle(color: Color(0xFFFF8C00), letterSpacing: 1.5)),
  );
}

class OrbeHolograficaPainter extends CustomPainter {
  final double progress;
  final bool isSpeaking;
  OrbeHolograficaPainter(this.progress, this.isSpeaking);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;
    int dotCount = 350;
    double baseRadius = isSpeaking ? 60.0 : 55.0;

    for (int i = 0; i < dotCount; i++) {
      double phi = math.acos(1 - 2 * (i + 0.5) / dotCount);
      double theta = math.sqrt(dotCount * math.pi) * phi;
      double onda =
          math.sin((progress * math.pi * 5.0) + (i * 0.1)) *
          (isSpeaking ? 5.0 : 1.0);
      double raioAtual = baseRadius + onda;

      double x = raioAtual * math.sin(phi) * math.cos(theta);
      double y = raioAtual * math.sin(phi) * math.sin(theta);
      double z = raioAtual * math.cos(phi);

      double scale = 300.0 / (300.0 + z);
      double opacity = ((z + baseRadius) / (baseRadius * 2.5)).clamp(0.1, 0.9);
      paint.color = const Color(0xFFFF8C00).withOpacity(opacity);
      canvas.drawCircle(
        Offset(center.dx + x * scale, center.dy + y * scale),
        1.5 * scale,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant OrbeHolograficaPainter oldDelegate) => true;
}
