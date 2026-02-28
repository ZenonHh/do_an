import 'package:flutter_tts/flutter_tts.dart';
import '../models/poi_model.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  final FlutterTts _tts = FlutterTts();

  bool _isPlaying = false;
  POI? _lastPlayedPOI;

  AudioService() {
    _initAudioHandlers();
  }

  void _initAudioHandlers() async {
    // 1. Kiểm tra và thiết lập TTS
    try {
      // Đảm bảo máy có bộ máy ngôn ngữ tiếng Việt
      var isAvailable = await _tts.isLanguageAvailable("vi-VN");
      if (isAvailable) {
        await _tts.setLanguage("vi-VN");
      } else {
        await _tts.setLanguage("en-US"); // Dự phòng nếu máy không hỗ trợ tiếng Việt
      }
      
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5); // Tốc độ vừa phải
    } catch (e) {
      debugPrint("TTS Setup Error: $e");
    }

    // 2. Event Handlers cho TTS
    _tts.setStartHandler(() {
      _isPlaying = true;
      debugPrint("Bắt đầu nói...");
    });
    
    _tts.setCompletionHandler(() {
      _isPlaying = false;
      debugPrint("Nói xong!");
    });

    _tts.setErrorHandler((msg) {
      _isPlaying = false;
      debugPrint("Lỗi TTS: $msg");
    });
  }

  Future<void> playPOI(POI poi) async {
    // 1. Chống phát trùng lặp cùng một điểm
    if (_isPlaying && _lastPlayedPOI?.id == poi.id) return;

    // 2. Luôn dừng trước khi nói câu mới
    await stop();
    _lastPlayedPOI = poi;

    try {
      // CHỈ DÙNG TTS CHO TẤT CẢ CÁC QUÁN
      debugPrint("Đang đọc thuyết minh cho: ${poi.name}");
      // Đọc nội dung từ trường description trong poi_model
      await _tts.speak(poi.description); 
    } catch (e) {
      debugPrint("Lỗi TTS: $e");
      _isPlaying = false;
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    _isPlaying = false;
  }

  void dispose() {
    _tts.stop();
  }
}