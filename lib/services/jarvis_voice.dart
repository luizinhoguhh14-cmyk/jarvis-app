class JarvisVoiceService {
  final String voiceId = "69a0b1c2f7e2433dabac4413ba0a56d7";

  void speak(String text, Function(bool isSpeaking) onStateChanged) async {
    onStateChanged(true);
    await Future.delayed(const Duration(seconds: 3));
    onStateChanged(false);
  }
}
