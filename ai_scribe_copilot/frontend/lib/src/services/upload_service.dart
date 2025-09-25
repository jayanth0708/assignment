import 'dart:async';
import 'package:ai_scribe_copilot/src/services/api_service.dart';
import 'package:ai_scribe_copilot/src/services/persistence_service.dart';
import '../models/queued_chunk.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class UploadService {
  final ApiService _apiService;
  final PersistenceService _persistenceService;
  StreamSubscription? _connectivitySubscription;
  bool _isProcessing = false;

  UploadService(this._apiService, this._persistenceService) {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((status) {
      if (status != ConnectivityResult.none) {
        print("Network connection restored. Retrying uploads...");
        retryQueuedUploads();
      }
    });
  }

  Future<void> uploadChunk(String sessionId, dynamic data) async {
    try {
      final urlData = await _apiService.getPresignedUrl(sessionId);
      if (urlData == null) {
        throw Exception("Could not get presigned URL");
      }

      final url = urlData['url']!;
      final chunkId = urlData['chunkId']!;

      final success = await _apiService.uploadAudioChunk(url, data);

      if (success) {
        await _apiService.notifyChunkUploaded(sessionId, chunkId);
        print("Successfully uploaded chunk $chunkId");
      } else {
        throw Exception("Upload failed, queuing chunk.");
      }
    } catch (e) {
      print("Error during upload: $e");
      await _persistenceService.saveChunkForRetry(sessionId, data);
    }
  }

  Future<void> retryQueuedUploads() async {
    if (_isProcessing) return;
    _isProcessing = true;

    final queuedChunks = _persistenceService.getQueuedChunks();
    if (queuedChunks.isEmpty) {
      _isProcessing = false;
      return;
    }

    print("Found ${queuedChunks.length} chunks to retry.");

    for (final chunk in List<QueuedAudioChunk>.from(queuedChunks)) {
       try {
        await uploadChunk(chunk.sessionId, chunk.chunkData);
        // If uploadChunk succeeds, it won't throw an exception.
        // We can then safely delete it from the queue.
        await _persistenceService.deleteQueuedChunk(chunk.key);
        print("Successfully uploaded and removed queued chunk.");
      } catch (e) {
        print("Failed to retry upload for chunk. It will remain in the queue.");
        // Stop retrying if one fails to avoid spamming a broken backend
        break;
      }
    }

    _isProcessing = false;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}