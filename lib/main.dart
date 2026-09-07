import 'package:flutter/material.dart';
import 'widgets/grade_fundo.dart';
import 'widgets/reator_arc.dart';
import 'widgets/globo_3d.dart';

void main() {
  runApp(const JarvisSystem());
}

class JarvisSystem extends StatelessWidget {
  const JarvisSystem({super.key});

  @override
  Widget build(BuildContext context) {
    const corStark = Color(0xFFFF5500); // Laranja Stark

    return MaterialApp(
      title: 'J.A.R.V.I.S. Mark III',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020100),
        primaryColor: corStark,
        fontFamily: 'Courier',
      ),
      home: const InterfacePrincipal(),
    );
  }
}

class InterfacePrincipal extends StatefulWidget {
  const InterfacePrincipal({super.key});

  @override
  State<InterfacePrincipal> createState() => _InterfacePrincipalState();
}

class _InterfacePrincipalState extends State<InterfacePrincipal> with TickerProviderStateMixin {
  final TextEditingController _controleTexto = TextEditingController();
  late AnimationController _motor3D;
  late AnimationController _animadorGlobo;
  late AnimationController _animadorZoomGlobo;

  int _abaSelecionada = 2; // 0: Today, 1: Memory, 2: Orbi, 3: Maps
  String _statusAlvoMapa = 'GLOBAL SCAN';
  String _coordenadasAlvo = '00.0000° N, 00.0000° W';
  bool _travaAlvoAtiva = false;
  bool _exibirGoogleMapsHUD = false;

  final Color corStark = const Color(0xFFFF5500);

  @override
  void initState() {
    super.initState();
    _motor3D = AnimationController(duration: const Duration(seconds: 8), vsync: this)..repeat();
    _animadorGlobo = AnimationController(duration: const Duration(seconds: 20), vsync: this)..repeat();
    _animadorZoomGlobo = AnimationController(duration: const Duration(milliseconds: 2200), vsync: this);

    _animadorZoomGlobo.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _exibirGoogleMapsHUD = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _motor3D.dispose();
    _animadorGlobo.dispose();
    _animadorZoomGlobo.dispose();
    _controleTexto.dispose();
    super.dispose();
  }

  void _processarComando(String comando) {
    if (comando.isEmpty) return;

    final cmd = comando.toLowerCase();

    if (cmd.contains('estados unidos') || cmd.contains('eua') || cmd.contains('usa')) {
      _ativarZoomCinematicoMapa('ESTADOS UNIDOS', '37.0902° N, 95.7129° W');
    } else if (cmd.contains('brasil') || cmd.contains('brazil')) {
      _ativarZoomCinematicoMapa('BRASIL', '14.2350° S, 51.9253° W');
    } else if (cmd.contains('japao') || cmd.contains('japão') || cmd.contains('tokyo')) {
      _ativarZoomCinematicoMapa('JAPÃO', '36.2048° N, 138.2529° E');
    } else if (cmd.contains('entra') || cmd.contains('mapa') || cmd.contains('vai para') || cmd.contains('localizar')) {
      _ativarZoomCinematicoMapa('DESTINO SOLICITADO', '40.7128° N, 74.0060° W');
    }

    _controleTexto.clear();
  }

  void _ativarZoomCinematicoMapa(String nomeLocal, String coords) {
    setState(() {
      _abaSelecionada = 3; // Força ida para a aba Maps
      _statusAlvoMapa = 'TARGET LOCKED: $nomeLocal';
      _coordenadasAlvo = coords;
      _travaAlvoAtiva = true;
      _exibirGoogleMapsHUD = false;
    });

    _animadorZoomGlobo.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Fundo de Grade Espacial Laranja Stark
            CustomPaint(painter: GradeEspacialPainter(corStark), size: Size.infinite),

            Column(
              children: [
                // Cabecalho de Telemetria J.A.R.V.I.S.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _painelTelemetria('SYSTEM', 'MARK_3', corStark),
                      Text(
                        'J.A.R.V.I.S.',
                        style: TextStyle(
                          color: corStark,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 5.0,
                          shadows: [BoxShadow(color: corStark.withOpacity(0.8), blurRadius: 12)],
                        ),
                      ),
                      _painelTelemetria('MODE', _nomeAbaAtual().toUpperCase(), corStark),
                    ],
                  ),
                ),

                // Barra Superior de Abas (Today, Memory, Orbi, Maps)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: corStark.withOpacity(0.3)),
                    color: corStark.withOpacity(0.03),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _itemAba(0, 'TODAY'),
                      _itemAba(1, 'MEMORY'),
                      _itemAba(2, 'ORBI'),
                      _itemAba(3, 'MAPS'),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Conteudo Dinamico conforme a Aba Selecionada
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _construirConteudoAba(),
                  ),
                ),

                // Campo Inferior de Entrada de Diretrizes // COMMAND
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: corStark, width: 3),
                        bottom: BorderSide(color: corStark.withOpacity(0.5), width: 1),
                      ),
                      color: corStark.withOpacity(0.05),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            'COMMAND//:',
                            style: TextStyle(color: corStark, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controleTexto,
                            style: TextStyle(color: corStark, fontSize: 13),
                            onSubmitted: _processarComando,
                            decoration: const InputDecoration(
                              hintText: 'Ex: "Jarvis, entra nos Estados Unidos"...',
                              hintStyle: TextStyle(color: Colors.white24, fontSize: 11),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send_rounded, color: corStark, size: 20),
                          onPressed: () => _processarComando(_controleTexto.text),
                        ),
                        IconButton(
                          icon: Icon(Icons.mic, color: corStark, size: 20),
                          onPressed: () {
                            _processarComando("Jarvis, entra nos Estados Unidos");
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemAba(int index, String rotulo) {
    final bool ativa = _abaSelecionada == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _abaSelecionada = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: ativa ? corStark.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: ativa ? corStark : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          rotulo,
          style: TextStyle(
            color: ativa ? corStark : corStark.withOpacity(0.4),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  String _nomeAbaAtual() {
    switch (_abaSelecionada) {
      case 0: return 'Today';
      case 1: return 'Memory';
      case 2: return 'Orbi Core';
      case 3: return 'Global Maps';
      default: return 'System';
    }
  }

  Widget _construirConteudoAba() {
    switch (_abaSelecionada) {
      case 0:
        return _abaToday();
      case 1:
        return _abaMemory();
      case 2:
        return _abaOrbiReator();
      case 3:
        return _abaMapsGlobo3D();
      default:
        return _abaOrbiReator();
    }
  }

  // --- ABA TODAY ---
  Widget _abaToday() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardStatus('STATUS OPERACIONAL', 'SISTEMAS MARK III ONLINE', Icons.verified_user),
          const SizedBox(height: 12),
          _cardStatus('DIRETRIZES DO DIA', '• Otimização de energia do reator\n• Análise de telemetria orbital\n• Atualização do mapa de navegação', Icons.list_alt),
          const SizedBox(height: 12),
          _cardStatus('ENERGIA STARK', 'REATOR ARC EM 98.4% - ESTÁVEL', Icons.flash_on),
        ],
      ),
    );
  }

  // --- ABA MEMORY ---
  Widget _abaMemory() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardStatus('BANCO DE DADOS MEMORY', 'USO: 1.2 TB / 10.0 TB HOLOGRÁFICO', Icons.memory),
          const SizedBox(height: 12),
          _cardStatus('LOGS RECENTES', '[13:10:02] Protocolo de calibração rodado.\n[13:12:45] Módulo de mapa terrestre 3D inicializado.\n[13:13:00] Conexão neural Mark III ativa.', Icons.receipt_long),
        ],
      ),
    );
  }

  // --- ABA ORBI (REATOR ARC 3D) ---
  Widget _abaOrbiReator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 310,
            height: 310,
            child: AnimatedBuilder(
              animation: _motor3D,
              builder: (context, child) {
                return CustomPaint(
                  painter: ReatorArc3DPainter(_motor3D.value, corStark),
                  size: const Size(310, 310),
                );
              },
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'ARC REACTOR // STARK CORE',
            style: TextStyle(color: corStark.withOpacity(0.7), fontSize: 11, letterSpacing: 3),
          ),
        ],
      ),
    );
  }

  // --- ABA MAPS (GLOBO TERRESTRE 3D + GOOGLE MAPS HUD) ---
  Widget _abaMapsGlobo3D() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Globo 3D Renderizado
        AnimatedBuilder(
          animation: Listenable.merge([_animadorGlobo, _animadorZoomGlobo]),
          builder: (context, child) {
            double zoomFactor = 1.0 + (_animadorZoomGlobo.value * 2.8);

            return CustomPaint(
              painter: GloboTerrestre3DPainter(
                progressRotacao: _animadorGlobo.value,
                zoomScale: zoomFactor,
                cor: corStark,
                comTravaAlvo: _travaAlvoAtiva,
              ),
              size: const Size(340, 340),
            );
          },
        ),

        // Info HUD de Alvo
        Positioned(
          top: 10,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: corStark.withOpacity(0.08),
              border: Border.all(color: corStark.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_statusAlvoMapa, style: TextStyle(color: corStark, fontWeight: FontWeight.bold, fontSize: 11)),
                    Text('LAT/LONG: $_coordenadasAlvo', style: TextStyle(color: corStark.withOpacity(0.6), fontSize: 9)),
                  ],
                ),
                Icon(Icons.radar, color: corStark, size: 22),
              ],
            ),
          ),
        ),

        // Google Maps Overlay HUD apos o Zoom Cinemático
        if (_exibirGoogleMapsHUD)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 600),
              opacity: _exibirGoogleMapsHUD ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0502),
                  border: Border.all(color: corStark, width: 1.5),
                  boxShadow: [BoxShadow(color: corStark.withOpacity(0.3), blurRadius: 15)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.map, color: corStark, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'GOOGLE MAPS HUD // INTERFACE SATELLITE',
                          style: TextStyle(color: corStark, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Acessando dados orbitais para $_statusAlvoMapa...\nVisualização vetorial ativada.',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _cardStatus(String titulo, String conteudo, IconData icone) {
    return Container(
      width: double.infinite,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: corStark.withOpacity(0.05),
        border: Border.all(color: corStark.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: corStark, size: 16),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(color: corStark, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            conteudo,
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _painelTelemetria(String titulo, String valor, Color cor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: TextStyle(color: cor.withOpacity(0.5), fontSize: 9, letterSpacing: 1.5)),
        Text(valor, style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
