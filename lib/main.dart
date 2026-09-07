import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const JarvisAppClone());
}

class JarvisAppClone extends StatelessWidget {
  const JarvisAppClone({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JARVIS Mark IV',
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
    const TelaMapsGlobe(),
    const TelaToday(),
    const Center(child: Text('Memory Matrix [Standby - Mark IV]', style: TextStyle(color: Colors.white54, letterSpacing: 1.5))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: telas[indiceAtual],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF09090B),
        type: BottomNavigationBarType.fixed,
        currentIndex: indiceAtual,
        selectedItemColor: const Color(0xFF00E5FF),
        unselectedItemColor: Colors.white38,
        selectedFontSize: 11,
        unselectedFontSize: 11,
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
            icon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.public)),
            label: 'Maps',
          ),
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.view_list_rounded)),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4.0), child: Icon(Icons.memory)),
            label: 'Memory',
          ),
        ],
      ),
    );
  }
}

// --- TELA PRINCIPAL DE VOZ, ORBE E ENTRADA DE TEXTO/ÁUDIO ---
class TelaJarvisVoice extends StatefulWidget {
  const TelaJarvisVoice({super.key});

  @override
  State<TelaJarvisVoice> createState() => _TelaJarvisVoiceState();
}

class _TelaJarvisVoiceState extends State<TelaJarvisVoice> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  bool jarvisOuvindo = false;
  bool mostrarCampoTexto = false;
  final TextEditingController _textController = TextEditingController();

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

  void alternarOuvir() {
    setState(() {
      jarvisOuvindo = !jarvisOuvindo;
    });
  }

  void alternarTeclado() {
    setState(() {
      mostrarCampoTexto = !mostrarCampoTexto;
    });
  }

  void _enviarComandoTexto(String valor) {
    if (valor.trim().isEmpty) return;
    setState(() {
      _textController.clear();
      mostrarCampoTexto = false;
    });
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
                  'JARVIS MK IV', 
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 18, 
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
                  painter: OrbeHolograficaPainter(controller.value, jarvisOuvindo),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          Text(
            jarvisOuvindo ? '•••• Ouvindo comando de voz... ••••' : 'JARVIS Mark IV [Pronto]',
            style: TextStyle(
              color: jarvisOuvindo ? const Color(0xFF00E5FF) : Colors.white60, 
              fontSize: 14,
              fontWeight: jarvisOuvindo ? FontWeight.w500 : FontWeight.normal,
            ),
          ),

          const Spacer(),

          // Barra de digitação dinâmica ativada pelo botão do teclado
          if (mostrarCampoTexto)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Digite o comando para o JARVIS...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF121218),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF22222E)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                        ),
                      ),
                      onSubmitted: _enviarComandoTexto,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF00E5FF)),
                    onPressed: () => _enviarComandoTexto(_textController.text),
                  ),
                ],
              ),
            ),

          IconButton(
            icon: Icon(
              mostrarCampoTexto ? Icons.keyboard_hide_outlined : Icons.keyboard_outlined, 
              color: mostrarCampoTexto ? const Color(0xFF00E5FF) : Colors.white60,
            ), 
            onPressed: alternarTeclado,
          ),
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.fromLTRB(30.0, 0, 30.0, 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48), // Espaço equilibrado (X removido)
                
                GestureDetector(
                  onTap: alternarOuvir,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: jarvisOuvindo ? 76 : 72,
                    height: jarvisOuvindo ? 76 : 72,
                    decoration: BoxDecoration(
                      color: jarvisOuvindo ? const Color(0xFF00E5FF) : const Color(0xFF163d42), 
                      shape: BoxShape.circle,
                      boxShadow: jarvisOuvindo ? [
                        BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.5), blurRadius: 15, spreadRadius: 2)
                      ] : [],
                    ),
                    child: Icon(
                      jarvisOuvindo ? Icons.mic : Icons.mic_none_outlined, 
                      color: jarvisOuvindo ? Colors.black87 : const Color(0xFF00E5FF), 
                      size: 36,
                    ),
                  ),
                ),
                
                Container(
                  decoration: const BoxDecoration(color: Color(0xFF1a1a20), shape: BoxShape.circle),
                  child: IconButton(icon: const Icon(Icons.add, color: Colors.white70), onPressed: () {}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- ABA MAPS: GLOBO 3D REAL COM CONTINENTES E RELEVOS ---
class TelaMapsGlobe extends StatefulWidget {
  const TelaMapsGlobe({super.key});

  @override
  State<TelaMapsGlobe> createState() => _TelaMapsGlobeState();
}

class _TelaMapsGlobeState extends State<TelaMapsGlobe> with SingleTickerProviderStateMixin {
  late AnimationController _globeController;

  @override
  void initState() {
    super.initState();
    _globeController = AnimationController(duration: const Duration(seconds: 25), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _globeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'GLOBAL HOLOGRAPHIC MAP',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                Text(
                  'MK IV.04',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _globeController,
              builder: (context, child) {
                return CustomPaint(
                  painter: GlobeHologramPainter(_globeController.value),
                  child: Container(),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Status: Mapeamento topográfico e satelital ativo',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF22222E)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF22222E)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF00E5FF)),
                      ),
                    ),
                    onSubmitted: (_) => _adicionarTarefa(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                  ? const Center(
                      child: Text(
                        'Nenhum protocolo ativo no momento.',
                        style: TextStyle(color: Colors.white24, fontSize: 13),
                      ),
                    )
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tarefa['horario'],
                                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
                                  onPressed: () => _removerTarefa(index),
                                ),
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

class OrbeHolograficaPainter extends CustomPainter {
  final double progress;
  final bool isListening;

  OrbeHolograficaPainter(this.progress, this.isListening);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    int dotCount = 450;
    double baseRadius = isListening ? 125.0 : 115.0;

    double angleY = progress * 2 * math.pi;
    double angleX = progress * math.pi;

    for (int i = 0; i < dotCount; i++) {
      double phi = math.acos(1 - 2 * (i + 0.5) / dotCount);
      double theta = math.sqrt(dotCount * math.pi) * phi;

      double randomSeed = math.sin(i * 43.13) * 100.0;
      double frequenciaIndividual = 4.0 + (i % 7) * 1.5;
      
      double amplitudeAtual = isListening ? (9.0 + (i % 5) * 3.5) : 1.5;
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

// --- RENDERIZADOR DO GLOBO 3D DETALHADO COM CONTORNOS E CONTINENTES ---
class GlobeHologramPainter extends CustomPainter {
  final double progress;

  GlobeHologramPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    double radius = math.min(size.width, size.height) * 0.38;
    double rotY = progress * 2 * math.pi;

    for (int lat = -75; lat <= 75; lat += 25) {
      double latRad = lat * math.pi / 180;
      double ringRadius = radius * math.cos(latRad);
      double ringY = center.dy + radius * math.sin(latRad);

      paint.color = const Color(0xFF00E5FF).withOpacity(0.2);
      canvas.drawCircle(Offset(center.dx, ringY), ringRadius, paint);
    }

    final landPaint = Paint()..style = PaintingStyle.fill;
    int continentNodes = 600;

    for (int i = 0; i < continentNodes; i++) {
      double phi = math.acos(1 - 2 * (i + 0.5) / continentNodes);
      double theta = math.sqrt(continentNodes * math.pi) * phi + rotY;

      bool isLand = (math.sin(phi * 3) * math.cos(theta * 2)).abs() > 0.35 ||
                    (math.cos(phi * 2) * math.sin(theta * 3)).abs() > 0.4;

      if (isLand) {
        double x = radius * math.sin(phi) * math.cos(theta);
        double y = radius * math.sin(phi) * math.sin(theta);
        double z = radius * math.cos(phi);

        double perspective = 320.0;
        double scale = perspective / (perspective + z);

        if (z > -radius * 0.7) {
          double screenX = center.dx + x * scale;
          double screenY = center.dy + y * scale;

          double alpha = ((z + radius) / (radius * 2)).clamp(0.15, 0.95);
          landPaint.color = const Color(0xFF00E5FF).withOpacity(alpha);
          canvas.drawCircle(Offset(screenX, screenY), 1.6 * scale, landPaint);

          if (i % 5 == 0) {
            paint.color = const Color(0xFF00E5FF).withOpacity(alpha * 0.35);
            canvas.drawLine(
              Offset(center.dx, center.dy),
              Offset(screenX, screenY),
              paint,
            );
          }
        }
      }
    }

    paint.color = const Color(0xFF00E5FF).withOpacity(0.5);
    paint.strokeWidth = 1.2;
    canvas.drawCircle(center, radius * 1.25, paint);

    TextPainter textPainter = TextPainter(
      text: const TextSpan(
        text: 'ORBITAL_SAT // 3D_GRID_ACTIVE',
        style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, letterSpacing: 1.5),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy + radius * 1.4));
  }

  @override
  bool shouldRepaint(covariant GlobeHologramPainter oldDelegate) => true;
}
