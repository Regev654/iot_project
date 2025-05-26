import 'package:flutter/material.dart';
import 'screens/event_list_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Validate environment variables
    Config.validateConfig();
    
    // Initialize Firebase with options
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    
    // Initialize Firebase with environment variables
    FirebaseDatabase.instance.databaseURL = Config.databaseUrl;
    
    // Sign in with admin credentials
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: Config.adminEmail,
      password: Config.adminPassword,
    );
    
    runApp(EventManagerApp());
  } catch (e) {
    print('Initialization error: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Error initializing app: $e\nPlease check your environment variables.',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
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
