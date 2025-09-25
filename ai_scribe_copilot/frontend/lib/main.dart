import 'package:flutter/material.dart';
import 'package:ai_scribe_copilot/src/ui/screens/home_screen.dart';
import 'package:ai_scribe_copilot/src/services/persistence_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PersistenceService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Scribe Copilot',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}