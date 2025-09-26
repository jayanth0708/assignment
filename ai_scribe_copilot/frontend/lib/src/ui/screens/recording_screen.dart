import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import '../../models/patient.dart';
import '../../services/api_service.dart';
import '../../services/audio_recording_service.dart';
import '../../services/persistence_service.dart';
import '../../services/upload_service.dart';
import '../../services/notification_service.dart';

class RecordingScreen extends StatefulWidget {
  final Patient patient;
  const RecordingScreen({Key? key, required this.patient}) : super(key: key);

  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> with WidgetsBindingObserver {
  // Services
  final ApiService _apiService = ApiService();
  final AudioRecordingService _audioService = AudioRecordingService();
  final PersistenceService _persistenceService = PersistenceService();
  final NotificationService _notificationService = NotificationService();
  late final UploadService _uploadService;

  // State
  String? _sessionId;
  bool _isRecording = false;
  int _durationInSeconds = 0;
  Timer? _timer;
  double _dbLevel = 0.0;
  StreamSubscription? _recordingSubscription;
  StreamSubscription? _dbLevelSubscription;
  String _statusMessage = "Initializing...";

  // Getters for cleaner state checks
  bool get isPaused => _audioService.isPaused;
  bool get isActuallyRecording => _audioService.isRecording;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _uploadService = UploadService(_apiService, _persistenceService);
    _notificationService.initialize();
    _startSessionAndRecording();
    _uploadService.retryQueuedUploads();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!isActuallyRecording) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (!isPaused) _pauseRecording();
    }
  }

  Future<void> _startSessionAndRecording() async {
    HapticFeedback.lightImpact();
    try {
      setState(() { _statusMessage = "Requesting new session..."; });
      _sessionId = await _apiService.startUploadSession(widget.patient.id);
      if (_sessionId == null) throw Exception("Failed to create session");

      await _audioService.initialize();

      _dbLevelSubscription = _audioService.dbLevelStream?.listen((db) {
        setState(() {
          // Normalize dB level for the UI.
          // flutter_sound gives dB in a range like -120 to 0.
          // We'll map it to a 0.0 to 1.0 scale.
          _dbLevel = (db + 120) / 120;
        });
      });

      _recordingSubscription = _audioService.recordingStream?.listen(_handleAudioChunk);

      await _audioService.startRecording();

      setState(() {
        _isRecording = true;
        _statusMessage = "Recording...";
      });
      _notificationService.showRecordingNotification(
          title: "Recording in progress",
          body: "Session for ${widget.patient.name}");

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!isPaused) {
          setState(() { _durationInSeconds++; });
        }
      });
    } catch (e) {
      print("Error starting recording: $e");
      setState(() { _statusMessage = "Error: ${e.toString()}"; });
    }
  }

  void _handleAudioChunk(dynamic event) {
    if (isPaused) return;
    if (event is FoodData && event.data != null) {
      _uploadService.uploadChunk(_sessionId!, event.data!);
    }
  }

  void _togglePauseResume() {
    HapticFeedback.lightImpact();
    if (isPaused) {
      _resumeRecording();
    } else {
      _pauseRecording();
    }
  }

  void _pauseRecording() async {
    await _audioService.pauseRecording();
    setState(() { _statusMessage = "Paused"; });
  }

  void _resumeRecording() async {
    await _audioService.resumeRecording();
    setState(() { _statusMessage = "Recording..."; });
  }

  void _stopRecording() async {
    HapticFeedback.heavyImpact();
    setState(() { _statusMessage = "Stopping..."; });
    _timer?.cancel();
    _dbLevelSubscription?.cancel();
    _recordingSubscription?.cancel();
    await _audioService.stopRecording();
    _notificationService.cancelRecordingNotification();

    setState(() { _isRecording = false; });

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.of(context).pop();
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor().toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _dbLevelSubscription?.cancel();
    _recordingSubscription?.cancel();
    _audioService.dispose();
    _uploadService.dispose();
    _notificationService.cancelRecordingNotification();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Session for ${widget.patient.name}'),
        backgroundColor: isActuallyRecording && !isPaused ? Colors.red : Theme.of(context).primaryColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (!_isRecording && _statusMessage.startsWith("Error")) ...[
                Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                Text(_statusMessage, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center,),
              ]
              else if (!_isRecording) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(_statusMessage, style: Theme.of(context).textTheme.titleLarge),
              ] else ...[
                Text(
                  _formatDuration(_durationInSeconds),
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 10),
                Text(_statusMessage, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 40),
                LinearProgressIndicator(value: _dbLevel, backgroundColor: Colors.grey[300],),
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      heroTag: 'pause-resume',
                      onPressed: _togglePauseResume,
                      child: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                    ),
                    const SizedBox(width: 40),
                    FloatingActionButton(
                      heroTag: 'stop',
                      backgroundColor: Colors.red,
                      onPressed: _stopRecording,
                      child: const Icon(Icons.stop),
                    ),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}