import 'package:hive_flutter/hive_flutter.dart';
import '../models/queued_chunk.dart';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';

class PersistenceService {
  static const _chunkBoxName = 'audio_chunks_queue';
  var _uuid = Uuid();

  Future<void> initialize() async {
    await Hive.initFlutter();
    // Register the adapter manually since we can't run build_runner
    if (!Hive.isAdapterRegistered(QueuedAudioChunkAdapter().typeId)) {
      Hive.registerAdapter(QueuedAudioChunkAdapter());
    }
    await Hive.openBox<QueuedAudioChunk>(_chunkBoxName);
  }

  Box<QueuedAudioChunk> get _chunkBox => Hive.box<QueuedAudioChunk>(_chunkBoxName);

  Future<void> saveChunkForRetry(String sessionId, Uint8List chunkData) async {
    final chunk = QueuedAudioChunk(
      sessionId: sessionId,
      chunkData: chunkData,
      uniqueId: _uuid.v4(),
    );
    await _chunkBox.add(chunk);
    print("Chunk saved locally for later retry.");
  }

  List<QueuedAudioChunk> getQueuedChunks() {
    return _chunkBox.values.toList();
  }

  Future<void> deleteQueuedChunk(dynamic key) async {
    await _chunkBox.delete(key);
  }

  Future<void> clearAllQueuedChunks() async {
    await _chunkBox.clear();
  }
}