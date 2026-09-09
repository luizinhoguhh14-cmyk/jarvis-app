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
      title: 'JARVIS API Test',
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
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"sender": "Você", "text": text});
      _loading = true;
    });
    _controller.clear();

    if (_apiKey.isEmpty) {
      setState(() {
        _messages.add({
          "sender": "ERRO CHAVE API",
          "text": "GEMINI_API_KEY ausente no build do Codemagic."
        });
        _loading = false;
      });
      return;
    }

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
              {"text": "Aja como o assistente JARVIS: $text"}
            ]
          }
        ]
      }));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        final reply = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? "Sem resposta.";
        setState(() {
          _messages.add({"sender": "JARVIS", "text": reply});
        });
      } else {
        setState(() {
          _messages.add({
            "sender": "ERRO HTTP ${response.statusCode}",
            "text": body
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"sender": "FALHA CONEXÃO", "text": e.toString()});
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JARVIS - Teste Codemagic'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Container(
            color: _apiKey.isNotEmpty ? Colors.green.shade900 : Colors.red.shade900,
            padding: const EdgeInsets.all(4),
            child: Center(
              child: Text(
                _apiKey.isNotEmpty ? "Chave API injetada com sucesso!" : "Atenção: Chave API não foi repassada no build!",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
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
                final isError = msg["sender"]!.contains("ERRO") || msg["sender"]!.contains("FALHA");

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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
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
                      hintText: 'Digite para testar a API...',
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
