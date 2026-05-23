import 'dart:html' as html;

Future<void> speakWithBrowser(String text) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return;

  html.window.speechSynthesis?.cancel();
  final utterance = html.SpeechSynthesisUtterance(trimmed)
    ..lang = 'en-US'
    ..rate = 1
    ..pitch = 1;
  html.window.speechSynthesis?.speak(utterance);
}
