// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class WebPlayerManager {
  static final instance = WebPlayerManager();

  final html.AudioElement _audioPlayer = html.AudioElement()..autoplay = true;

  // ignore: type_annotate_public_apis
  Future<void> setSrcObject(src) async =>
      _audioPlayer.srcObject = src?.jsStream;
}
