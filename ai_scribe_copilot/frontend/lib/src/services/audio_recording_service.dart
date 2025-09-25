import 'dart:async';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecordingService {
  FlutterSoundRecorder? _recorder;
  bool _isInitialized = false;

  StreamController<Food>? _recordingDataController;
  Stream<Food>? get recordingStream => _recordingDataController?.stream;

  StreamController<double>? _dbLevelController;
  Stream<double>? get dbLevelStream => _dbLevelController?.stream;

  bool get isRecording => _recorder?.isRecording ?? false;
  bool get isPaused => _recorder?.isPaused ?? false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }

    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    _isInitialized = true;

    _recordingDataController = StreamController<Food>.broadcast();
    _dbLevelController = StreamController<double>.broadcast();
  }

  Future<void> startRecording() async {
    if (!_isInitialized) await initialize();

    _recorder!.setSubscriptionDuration(const Duration(milliseconds: 100));
    _recorder!.onProgress!.listen((e) {
      if (e.decibels != null) {
        _dbLevelController!.add(e.decibels!);
      }
    });

    await _recorder!.startRecorder(
      codec: Codec.aacADTS,
      toStream: _recordingDataController!.sink,
    );
  }

  Future<void> pauseRecording() async {
    if (isRecording) {
      await _recorder!.pauseRecorder();
    }
  }

  Future<void> resumeRecording() async {
    if (isPaused) {
      await _recorder!.resumeRecorder();
    }
  }

  Future<void> stopRecording() async {
    if (_recorder != null && (_recorder!.isRecording || _recorder!.isPaused)) {
      await _recorder!.stopRecorder();
    }
  }

  Future<void> dispose() async {
    if (_recorder != null) {
      await stopRecording();
      await _recorder!.closeRecorder();
      _recorder = null;
    }
    _recordingDataController?.close();
    _dbLevelController?.close();
  }
}