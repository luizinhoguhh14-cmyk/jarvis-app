import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;

void main() {
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
  int indiceAtual = 0;

  final List<Widget> telas = [
    const TelaJarvisVoice(),
    const TelaToday(),
    const Center(
      child: Text(
        'Memory Matrix [Standby]', 
        style: TextStyle(color: Colors.white54, letterSpacing: 1.5, fontSize: 14),
      ),
    ),
    const TelaRadarMaps(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  resizeToAvoidBottomInset: false,
      body: telas[indiceAtual],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF09090B),
        currentIndex: indiceAtual,
        selectedItemColor: const Color(0xFF00E5FF),
        unselectedItemColor: Colors.white38,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            indiceAtual = index;
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
            icon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.memory)),
            label: 'Memory',
          ),
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.radar)),
            label: 'Maps',
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

class _TelaJarvisVoiceState extends State<TelaJarvisVoice> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  bool jarvisFalando = false;
  final TextEditingController _textController = TextEditingController();
  String _respostaGemini = 'Aguardando diretrizes, Senhor...';
  bool _isLoading = false;

  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
  defaultValue: 'SUA_CHAVE_DE_API_DO_GEMINI_AQUI',
  );

  @override
  void initState() {
    super.initState();
    controller = AnimationController(duration: const Duration(seconds: 12), vsync: this)..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _enviarParaGemini(String texto) async {
    if (texto.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      jarvisFalando = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": "Você é o J.A.R.V.I.S., assistente avançado do Tony Stark. Responda de forma elegante, técnica e concisa, chamando o usuário de Senhor. Pergunta: $texto"}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _respostaGemini = data['candidates'][0]['content']['parts'][0]['text'].trim();
        });
      } else {
        setState(() {
          _respostaGemini = 'Erro nos circuitos da API (${response.statusCode}). Verifique o Codemagic, Senhor.';
        });
      }
    } catch (e) {
      setState(() {
        _respostaGemini = 'Falha de conexão com os satélites.';
      });
    } finally {
      setState(() {
        _isLoading = false;
        jarvisFalando = false;
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
                IconButton(icon: const Icon(Icons.access_time, color: Colors.white70), onPressed: () {}),
                const Text(
                  'JARVIS', 
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.5,
                  ),
                ),
                IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white70), onPressed: () {}),
              ],
            ),
          ),

          const Spacer(),

          SizedBox(
            width: 320,
            height: 320,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: OrbeHolograficaPainter(controller.value, jarvisFalando),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              _isLoading ? 'Processando dados...' : _respostaGemini,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: jarvisFalando ? Colors.white : Colors.white60, 
                fontSize: 13,
              ),
            ),
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Comando para o JARVIS...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF121218),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (val) {
                      _enviarParaGemini(val);
                      _textController.clear();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF00E5FF)),
                  onPressed: () {
                    _enviarParaGemini(_textController.text);
                    _textController.clear();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
class TelaToday extends StatefulWidget {
  const TelaToday({super.key});

  @override
  State<TelaToday> createState() => _TelaTodayState();
}

class _TelaTodayState extends State<TelaToday> {
  final List<Map<String, dynamic>> tarefas = [];
  final TextEditingController _controllerTarefa = TextEditingController();

  void _adicionarTarefa() {
    if (_controllerTarefa.text.trim().isEmpty) return;
    setState(() {
      tarefas.add({
        'titulo': _controllerTarefa.text.trim(),
        'horario': TimeOfDay.now().format(context),
        'concluido': false,
      });
      _controllerTarefa.clear();
    });
  }

  void _removerTarefa(int index) {
    setState(() {
      tarefas.removeAt(index);
    });
  }

  void _alternarConclusao(int index) {
    setState(() {
      tarefas[index]['concluido'] = !tarefas[index]['concluido'];
    });
  }

  @override
  void dispose() {
    _controllerTarefa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PROTOCOLOS DE HOJE',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Senhor, insira ou gerencie seus objetivos operacionais abaixo.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controllerTarefa,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Novo protocolo ou tarefa...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF121218),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _adicionarTarefa(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(color: const Color(0xFF00E5FF), borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.black87),
                    onPressed: _adicionarTarefa,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: tarefas.isEmpty
                  ? const Center(child: Text('Nenhum protocolo ativo no momento.', style: TextStyle(color: Colors.white24, fontSize: 13)))
                  : ListView.builder(
                      itemCount: tarefas.length,
                      itemBuilder: (context, index) {
                        final tarefa = tarefas[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121218),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF22222E)),
                          ),
                          child: ListTile(
                            leading: GestureDetector(
                              onTap: () => _alternarConclusao(index),
                              child: Icon(
                                tarefa['concluido'] ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                                color: tarefa['concluido'] ? const Color(0xFF00E5FF) : Colors.white38,
                              ),
                            ),
                            title: Text(
                              tarefa['titulo'],
                              style: TextStyle(
                                color: tarefa['concluido'] ? Colors.white38 : Colors.white,
                                decoration: tarefa['concluido'] ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
                              onPressed: () => _removerTarefa(index),
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
class TelaRadarMaps extends StatefulWidget {
  const TelaRadarMaps({super.key});

  @override
  State<TelaRadarMaps> createState() => _TelaRadarMapsState();
}

class _TelaRadarMapsState extends State<TelaRadarMaps> {
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-23.550520, -46.633308),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            mapType: MapType.hybrid,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            top: 40,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF09090B).withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4)),
              ),
              child: const Text(
                'RADAR TÁTICO - GOOGLE MAPS',
                style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class OrbeHolograficaPainter extends CustomPainter {
  final double progress;
  final bool isSpeaking;

  OrbeHolograficaPainter(this.progress, this.isSpeaking);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    int dotCount = 420;
    double baseRadius = isSpeaking ? 120.0 : 115.0;

    double angleY = progress * 2 * math.pi;
    double angleX = progress * math.pi;

    for (int i = 0; i < dotCount; i++) {
      double phi = math.acos(1 - 2 * (i + 0.5) / dotCount);
      double theta = math.sqrt(dotCount * math.pi) * phi;

      double randomSeed = math.sin(i * 43.13) * 100.0;
      double frequenciaIndividual = 4.0 + (i % 7) * 1.5;
      
      double amplitudeAtual = isSpeaking ? (8.0 + (i % 5) * 3.5) : 1.5;
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

      paint.color = const Color(0xFF00E5FF).withOpacity(alpha * 0.85);
      canvas.drawCircle(Offset(screenX, screenY), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant OrbeHolograficaPainter oldDelegate) => true;
}
