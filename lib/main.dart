import 'package:flutter/material.dart';
import 'services/jarvis_voice.dart';
import 'services/gemini_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JARVIS Mark 4',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const TelaJarvisVoice(),
    );
  }
}

class TelaJarvisVoice extends StatefulWidget {
  const TelaJarvisVoice({super.key});

  @override
  State<TelaJarvisVoice> createState() => _TelaJarvisVoiceState();
}

class _TelaJarvisVoiceState extends State<TelaJarvisVoice> {
  final TextEditingController _textController = TextEditingController();
  final JarvisVoiceService _voiceService = JarvisVoiceService();
  final GeminiService _geminiService = GeminiService();

  bool _isSpeaking = false;
  bool _isLoading = false;
  String _respostaTexto = "Sistemas prontos, senhor. Como posso ajudar?";

  void _enviarParaGemini(String texto) async {
    if (texto.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _respostaTexto = "Processando comando, senhor...";
    });

    final resposta = await _geminiService.enviarComando(texto);

    setState(() {
      _isLoading = false;
      _respostaTexto = resposta;
    });

    _voiceService.speak(resposta, (isSpeaking) {
      setState(() {
        _isSpeaking = isSpeaking;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isSpeaking ? 160 : 120,
                height: _isSpeaking ? 160 : 120,
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(_isSpeaking ? 0.9 : 0.4),
                      blurRadius: _isSpeaking ? 40 : 15,
                      spreadRadius: _isSpeaking ? 15 : 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _isSpeaking ? Icons.graphic_eq : Icons.mic,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _respostaTexto,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Comando para o JARVIS...",
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF121218),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (val) {
                        _enviarParaGemini(val);
                        _textController.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.orangeAccent)
                        : const Icon(Icons.send, color: Colors.orangeAccent),
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
      ),
    );
  }
}
