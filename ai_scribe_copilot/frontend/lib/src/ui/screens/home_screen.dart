import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../services/api_service.dart';
import 'recording_screen.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Patient>> _patientsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _patientsFuture = _apiService.getPatients();
  }

  void _startNewSession(Patient? patient) {
    if (patient == null) {
      // In a real app, you'd show a patient picker dialog.
      // For this demo, we'll show a snackbar.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient first.')),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RecordingScreen(patient: patient),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Scribe Copilot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _patientsFuture = _apiService.getPatients();
              });
            },
          )
        ],
      ),
      body: FutureBuilder<List<Patient>>(
        future: _patientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No patients found.'));
          }

          final patients = snapshot.data!;
          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              return ListTile(
                title: Text(patient.name),
                subtitle: Text('ID: ${patient.id}'),
                leading: const Icon(Icons.person_outline),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.share),
                      tooltip: 'Share Patient Info',
                      onPressed: () {
                        Share.share(
                          'Patient Information:\nName: ${patient.name}\nID: ${patient.id}',
                          subject: 'Patient Info: ${patient.name}',
                        );
                      },
                    ),
                    const Icon(Icons.keyboard_arrow_right),
                  ],
                ),
                onTap: () => _startNewSession(patient),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _startNewSession(null), // This will show the "select patient" message
        tooltip: 'New Recording',
        child: const Icon(Icons.mic),
      ),
    );
  }
}