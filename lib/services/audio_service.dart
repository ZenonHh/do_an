import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/poi_model.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  POI? _lastPlayedPOI;

  AudioService() {
    _initTts();
  }

  void _initTts() async {
    await _tts.setLanguage("vi-VN");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);

    _tts.setCompletionHandler(() => _isPlaying = false);
    _tts.setStartHandler(() => _isPlaying = true);
  }

  Future<void> playPOI(POI poi) async {
    if (_isPlaying && _lastPlayedPOI?.id == poi.id) return;
    if (_isPlaying) await stop();

    _lastPlayedPOI = poi;

    // Ưu tiên phát Audio File nếu có, nếu không dùng TTS
    if (poi.narrationType == NarrationType.audio) {
      debugPrint("Đang phát file ghi âm: ${poi.content}");
      await _audioPlayer.play(AssetSource(poi.content));
      _isPlaying = true;
    } else {
      debugPrint("Đang phát giọng đọc TTS: ${poi.content}");
      await _tts.speak(poi.content);
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    await _audioPlayer.stop();
    _isPlaying = false;
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
