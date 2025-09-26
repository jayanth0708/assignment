// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queued_chunk.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QueuedAudioChunkAdapterGenerated extends TypeAdapter<QueuedAudioChunk> {
  @override
  final int typeId = 0;

  @override
  QueuedAudioChunk read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QueuedAudioChunk(
      sessionId: fields[0] as String,
      chunkData: fields[1] as Uint8List,
      uniqueId: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, QueuedAudioChunk obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.sessionId)
      ..writeByte(1)
      ..write(obj.chunkData)
      ..writeByte(2)
      ..write(obj.uniqueId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueuedAudioChunkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
