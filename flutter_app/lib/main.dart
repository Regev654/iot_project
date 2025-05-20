import 'package:flutter/material.dart';
import 'screens/event_list_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Error: .env file not found. Please create a .env file with the required configuration.');
    return;
  }
  
  // Initialize Firebase with options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase with environment variables
  final databaseUrl = dotenv.env['FIREBASE_DATABASE_URL'];
  if (databaseUrl == null) {
    print('Error: FIREBASE_DATABASE_URL not found in .env file');
    return;
  }
  FirebaseDatabase.instance.databaseURL = databaseUrl;
  
  try {
    final email = dotenv.env['ADMIN_EMAIL'];
    final password = dotenv.env['ADMIN_PASSWORD'];
    
    if (email == null || password == null) {
      print('Error: ADMIN_EMAIL or ADMIN_PASSWORD not found in .env file');
      return;
    }
    
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  } catch (e) {
    print('Error signing in: $e');
    return;
  }
  
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
      home: EventListScreen(),
    );
  }
}
