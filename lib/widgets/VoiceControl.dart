import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceControl {
  late stt.SpeechToText _speech;
  bool _isListening = false;

  VoiceControl() {
    _speech = stt.SpeechToText();
  }

  Future<void> initialize() async {
    await _speech.initialize(
      onStatus: (status) {
        print('Status: $status');
      },
      onError: (error) {
        print('Error: $error');
      },
    );
  }

  Future<void> startListening(Function(String) onResult) async {
    if (!_isListening) {
      bool available = await _speech.initialize();

      if (available) {
        _isListening = true;

        _speech.listen(
          onResult: (result) {
            onResult(result.recognizedWords);
          },
        );
      }
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      _isListening = false;
      await _speech.stop();
    }
  }
}
