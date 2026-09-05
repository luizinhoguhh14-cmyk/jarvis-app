import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui'; // Adicionado para o efeito de vidro (Glassmorphism) da Mark 4

void main() {
  runApp(const JarvisApp());
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jarvis AI',
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
    RadarTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Memory'),
          BottomNavigationBarItem(icon: Icon(Icons.radar), label: 'Radar'),
        ],
      ),
    );
  }
}

// --- ABA 1: JARVIS (MARK 4 HUD UPGRADE) ---
class JarvisTab extends StatefulWidget {
  const JarvisTab({super.key});

  @override
  State<JarvisTab> createState() => _JarvisTabState();
}

class _JarvisTabState extends State<JarvisTab> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  
  // Lembre-se de colocar sua chave real da API Gemini aqui!
  final String _apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'SUA_CHAVE_DE_API_DO_GEMINI_AQUI');


  
  late AnimationController _animController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
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
      } else {
        setState(() {
          _messages.add({"sender": "jarvis", "text": "Erro na resposta da API do Gemini."});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"sender": "jarvis", "text": "Erro de conexão: $e"});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Novo componente: Botões holográficos do Topo
  Widget _buildHudButton(IconData icon, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.cyanAccent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.cyanAccent, size: 16),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
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
          // PAINEL HUD ADICIONAL NO TOPO (A novidade da Mark 4!)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHudButton(Icons.memory, "SYS: 98%"),
                _buildHudButton(Icons.shield, "DEFENSE"),
                _buildHudButton(Icons.settings_input_antenna, "UPLINK"),
              ],
            ),
          ),
          
          const SizedBox(height: 10),

          // A ORBE CLÁSSICA DA MARK 3
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Container(
                width: 90 + (_animController.value * 15),
                height: 90 + (_animController.value * 15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.cyanAccent,
                      Colors.blue.shade900,
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.5 * _animController.value),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          const Text(
            'JARVIS SYSTEM',
            style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          
          // CHAT DA MARK 3
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
            
          // CAMPO DE TEXTO E ENVIO
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Digite um comando...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1A2232),
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

// --- ABA 2: TODAY ---
class TodayTab extends StatelessWidget {
  const TodayTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Aba Today (Agenda/Tarefas)', style: TextStyle(color: Colors.white)),
    );
  }
}

// --- ABA 3: MEMORY ---
class MemoryTab extends StatelessWidget {
  const MemoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Aba Memory (Notas/Conhecimento)', style: TextStyle(color: Colors.white)),
    );
  }
}

// --- ABA 4: RADAR (GOOGLE MAPS 3D HOLOGRÁFICO) ---
class RadarTab extends StatefulWidget {
  const RadarTab({super.key});

  @override
  State<RadarTab> createState() => _RadarTabState();
}

class _RadarTabState extends State<RadarTab> {
  // A mágica do 3D acontece no TILT e no ZOOM.
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-23.55052, -46.633308), // Posição atual (Brasil)
    zoom: 17.5,
    tilt: 65.0, // Inclinação severa para dar o visual de escaneamento em 3D
    bearing: 45.0, // Rotaciona a câmera um pouco
  );

  // Estilo customizado escuro para o Google Maps (Dark/Neon)
  final String _mapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#0B0E14"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#0B0E14"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#00FFFF"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#004444"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#001111"}]
    }
  ]
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        myLocationEnabled: true,
        compassEnabled: false,
        mapToolbarEnabled: false,
        onMapCreated: (GoogleMapController controller) {
          // Aplica o tema noturno cibernético assim que o mapa carrega
          controller.setMapStyle(_mapStyle);
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.cyanAccent.withOpacity(0.2),
        onPressed: () {},
        child: const Icon(Icons.radar, color: Colors.cyanAccent),
      ),
    );
  }
}
