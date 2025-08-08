import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Validate configuration
  Config.validateConfig();
  
  // Initialize Firebase with options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase with environment variables
  FirebaseDatabase.instance.databaseURL = Config.databaseUrl;
  
  runApp(EventManagerApp());
}

class EventManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: LoginScreen(),
    );
  }
}
