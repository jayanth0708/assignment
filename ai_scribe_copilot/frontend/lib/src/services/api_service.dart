import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/patient.dart';

class ApiService {
  final String baseUrl = "http://127.0.0.1:5000/v1"; // For local testing with backend
  // final String baseUrl = "http://10.0.2.2:5000/v1"; // For Android emulator

  Future<List<Patient>> getPatients() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/patients?userId=user-123'));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<Patient> patients = body.map((dynamic item) => Patient.fromJson(item)).toList();
        return patients;
      } else {
        throw Exception('Failed to load patients');
      }
    } catch (e) {
      // Return mock data if backend is not running
      print("Could not connect to backend, returning mock data. Error: $e");
      return [
        Patient(id: 'patient-1', name: 'John Doe (Mock)'),
        Patient(id: 'patient-2', name: 'Jane Smith (Mock)'),
      ];
    }
  }

  Future<String?> startUploadSession(String patientId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/upload-session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'patientId': patientId}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['sessionId'];
      }
    } catch (e) {
      print("Failed to start session: $e");
    }
    return null;
  }

  Future<Map<String, String>?> getPresignedUrl(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get-presigned-url'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sessionId': sessionId}),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return {
          'url': body['url'],
          'chunkId': body['chunkId'],
        };
      }
    } catch (e) {
      print("Failed to get presigned URL: $e");
    }
    return null;
  }

  Future<bool> uploadAudioChunk(String url, Uint8List data) async {
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'audio/aac'},
        body: data,
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Failed to upload chunk: $e");
      return false;
    }
  }

  Future<void> notifyChunkUploaded(String sessionId, String chunkId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/notify-chunk-uploaded'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sessionId': sessionId, 'chunkId': chunkId}),
      );
    } catch (e) {
      print("Failed to notify chunk upload: $e");
    }
  }
}