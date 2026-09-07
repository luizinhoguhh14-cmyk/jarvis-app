import 'package:http/http.dart' as http;
import 'dart:convert';

class GeminiService {
  final String apiKey = const String.fromEnvironment('GEMINI_API_KEY');

  Future<String> enviarComando(String prompt) async {
    if (apiKey.isEmpty) {
      return "Senhor, a chave GEMINI_API_KEY precisa ser configurada no Codemagic.";
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey'
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Você é o JARVIS, assistente de IA altamente sofisticado e leal ao seu criador. Responda de forma direta, formal, tratando-o sempre por "senhor". Pergunta: $prompt'}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        return "Senhor, erro na API do Gemini (Status ${response.statusCode}).";
      }
    } catch (e) {
      return "Senhor, falha na conexão com o Gemini.";
    }
  }
}
