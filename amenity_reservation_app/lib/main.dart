import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://hcpnmzzdthfnhjashhgr.supabase.co', // Your Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjcG5tenpkdGhmbmhqYXNoaGdyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjk0NzM4MTYsImV4cCI6MjA0NTA0OTgxNn0.TiVdRYb-qBMND7VtADMdyGIULD3gtChmMzh7N8mJZhs', // Your Supabase Anon Key
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Root of the application
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LYF Funan Kitchen Reservation',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: HomeScreen(),
    );
  }
}
