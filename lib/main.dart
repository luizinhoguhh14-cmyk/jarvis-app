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
      title: 'JARVIS - Failover Triplo',
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
  static const String _geminiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _openAiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String _claudeKey = String.fromEnvironment('CLAUDE_API_KEY');

  static const String _jarvisPrompt = 
      "Você é o J.A.R.V.I.S., uma inteligência artificial sofisticada, leal e polida. "
      "Trate o usuário por 'Senhor'. Responda de forma direta e técnica em português.";

  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  Future<Map<String, dynamic>> _callGemini(String prompt) async {
    if (_geminiKey.isEmpty) return {"success": false, "error": "Chave Gemini não configurada"};
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_geminiKey',
      );
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        "system_instruction": {"parts": [{"text": _jarvisPrompt}]},
        "contents": [{"parts": [{"text": prompt}]}]
      }));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null) return {"success": true, "text": text};
      }
      return {"success": false, "error": "Gemini HTTP ${response.statusCode}: $body"};
    } catch (e) {
      return {"success": false, "error": "Gemini Exceção: $e"};
    }
  }

  Future<Map<String, dynamic>> _callOpenAI(String prompt) async {
    if (_openAiKey.isEmpty) return {"success": false, "error": "Chave OpenAI não configurada"};
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
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        final text = data['choices']?[0]?['message']?['content'];
        if (text != null) return {"success": true, "text": text};
      }
      return {"success": false, "error": "OpenAI HTTP ${response.statusCode}: $body"};
    } catch (e) {
      return {"success": false, "error": "OpenAI Exceção: $e"};
    }
  }

  Future<Map<String, dynamic>> _callClaude(String prompt) async {
    if (_claudeKey.isEmpty) return {"success": false, "error": "Chave Claude não configurada"};
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
        "messages": [{"role": "user", "content": prompt}]
      }));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        final text = data['content']?[0]?['text'];
        if (text != null) return {"success": true, "text": text};
      }
      return {"success": false, "error": "Claude HTTP ${response.statusCode}: $body"};
    } catch (e) {
      return {"success": false, "error": "Claude Exceção: $e"};
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"sender": "Você", "text": text});
      _loading = true;
    });
    _controller.clear();

    List<String> logs = [];

    // 1. Gemini
    final resGemini = await _callGemini(text);
    if (resGemini["success"] == true) {
      _addReply("JARVIS (Gemini)", resGemini["text"]);
      return;
    }
    logs.add(resGemini["error"]);

    // 2. OpenAI
    final resOpenAI = await _callOpenAI(text);
    if (resOpenAI["success"] == true) {
      _addReply("JARVIS (OpenAI)", resOpenAI["text"]);
      return;
    }
    logs.add(resOpenAI["error"]);

    // 3. Claude
    final resClaude = await _callClaude(text);
    if (resClaude["success"] == true) {
      _addReply("JARVIS (Claude)", resClaude["text"]);
      return;
    }
    logs.add(resClaude["error"]);

    // Se todos falharem, exibe os relatórios de diagnóstico
    setState(() {
      _messages.add({
        "sender": "DIAGNOSTICO DE FALHA",
        "text": "Todos os provedores falharam:\n\n" + logs.join("\n\n")
      });
      _loading = false;
    });
  }

  void _addReply(String sender, String text) {
    setState(() {
      _messages.add({"sender": sender, "text": text});
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
                final isError = msg["sender"]!.contains("DIAGNOSTICO");

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
