import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'dart:typed_data';

class JarvisVoiceService {
  final String apiKey = "sk-fish_b2ElwmkHha1wSKJDDxMQN0yBdf9u82rOANBLWeeW";
  final String voiceId = "69a0b1c2f7e2433dabac4413ba0a56d7";
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> speak(String text, Function(bool isSpeaking) onStateChange) async {
    final url = Uri.parse("https://api.fish.audio/v1/tts");
    onStateChange(true);
    
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "text": text,
          "reference_id": voiceId,
          "format": "mp3"
        }),
      );

      if (response.statusCode == 200) {
        Uint8List audioBytes = response.bodyBytes;
        await _audioPlayer.play(BytesSource(audioBytes));
        _audioPlayer.onPlayerComplete.listen((_) {
          onStateChange(false);
        });
      } else {
        onStateChange(false);
      }
    } catch (e) {
      onStateChange(false);
    }
  }
}
