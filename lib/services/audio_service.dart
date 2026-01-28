import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  final FlutterTts _tts = FlutterTts();
  String? _lastPoiId; // Dùng để tránh việc App nói đi nói lại một chỗ (Anti-spam)

  AudioService() {
    _initTts();
  }

  void _initTts() async {
    await _tts.setLanguage("vi-VN"); // Đặt ngôn ngữ tiếng Việt
    await _tts.setPitch(1.0);        // Độ cao giọng nói
    await _tts.setSpeechRate(0.5);   // Tốc độ nói (0.5 là vừa nghe)
  }

  // Hàm phát giọng nói
  Future<void> speak(String text, String poiId) async {
    // Nếu vẫn là điểm cũ thì không nói lại (Requirement 2: Cooldown/Anti-spam)
    if (_lastPoiId == poiId) return;

    await _tts.speak(text);
    _lastPoiId = poiId; 
  }

  // Hàm dừng (khi người dùng đi ra khỏi vùng)
  Future<void> stop() async {
    await _tts.stop();
    _lastPoiId = null; 
  }
}