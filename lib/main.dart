import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JarvisApp());
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JARVIS - Redundância Tripla',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Leitura das três variáveis de ambiente injetadas via Codemagic
  static const String _geminiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _openAiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String _claudeKey = String.fromEnvironment('CLAUDE_API_KEY');

  static const String _jarvisPrompt = 
      "Você é o J.A.R.V.I.S., uma inteligência artificial sofisticada, leal, polida e com tom de ironia elegante. "
      "Trate o usuário sempre por 'Senhor'. Responda de forma direta, técnica e impecável em português.";

  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  // Chamada à API 1: Google Gemini
  Future<String?> _callGemini(String prompt) async {
    if (_geminiKey.isEmpty) return null;
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=$_geminiKey',
      );
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        "system_instruction": {
          "parts": [
            {"text": _jarvisPrompt}
          ]
        },
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }));

      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        return data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      }
    } catch (_) {}
    return null;
  }

  // Chamada à API 2: OpenAI (ChatGPT)
  Future<String?> _callOpenAI(String prompt) async {
    if (_openAiKey.isEmpty) return null;
    try {
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;
      request.headers.set('Authorization', 'Bearer $_openAiKey');
      request.write(jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {"role": "system", "content": _jarvisPrompt},
          {"role": "user", "content": prompt}
        ]
      }));

      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        return data['choices']?[0]?['message']?['content'];
      }
    } catch (_) {}
    return null;
  }

  // Chamada à API 3: Anthropic (Claude)
  Future<String?> _callClaude(String prompt) async {
    if (_claudeKey.isEmpty) return null;
    try {
      final url = Uri.parse('https://api.anthropic.com/v1/messages');
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;
      request.headers.set('x-api-key', _claudeKey);
      request.headers.set('anthropic-version', '2023-06-01');
      request.write(jsonEncode({
        "model": "claude-3-5-haiku-20241022",
        "max_tokens": 1024,
        "system": _jarvisPrompt,
        "messages": [
          {"role": "user", "content": prompt}
        ]
      }));

      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        return data['content']?[0]?['text'];
      }
    } catch (_) {}
    return null;
  }

  // Execução Sequencial do Failover (Gemini -> OpenAI -> Claude)
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"sender": "Você", "text": text});
      _loading = true;
    });
    _controller.clear();

    String? reply;
    String providerName = "";

    // Tentativa 1: Gemini
    reply = await _callGemini(text);
    if (reply != null) {
      providerName = "JARVIS (Gemini)";
    } else {
      // Tentativa 2: OpenAI
      reply = await _callOpenAI(text);
      if (reply != null) {
        providerName = "JARVIS (OpenAI)";
      } else {
        // Tentativa 3: Claude
        reply = await _callClaude(text);
        if (reply != null) {
          providerName = "JARVIS (Claude)";
        }
      }
    }

    setState(() {
      if (reply != null) {
        _messages.add({"sender": providerName, "text": reply});
      } else {
        _messages.add({
          "sender": "ERRO DE CONTINGÊNCIA",
          "text": "Todos os provedores (Gemini, OpenAI e Claude) falharam ou estão incomunicáveis. "
              "Verifique o status das chaves de API e da sua conexão."
        });
      }
      _loading = false;
    });
  }

  Widget _buildKeyStatusChip(String name, bool isPresent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPresent ? Colors.green.shade900 : Colors.red.shade900,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "$name: ${isPresent ? 'OK' : 'Ausente'}",
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JARVIS - Failover Triplo'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildKeyStatusChip("Gemini", _geminiKey.isNotEmpty),
                _buildKeyStatusChip("OpenAI", _openAiKey.isNotEmpty),
                _buildKeyStatusChip("Claude", _claudeKey.isNotEmpty),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["sender"] == "Você";
                final isError = msg["sender"]!.contains("ERRO");

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isError
                          ? Colors.red.withOpacity(0.3)
                          : (isUser ? Colors.blue.withOpacity(0.3) : Colors.grey.shade800),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isError ? Colors.red : (isUser ? Colors.blue : Colors.cyan),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg["sender"]!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: isUser ? Colors.lightBlue : Colors.cyanAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(msg["text"]!),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Envie uma mensagem ao JARVIS...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
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
