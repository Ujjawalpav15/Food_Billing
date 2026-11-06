import 'package:flutter/material.dart';
import 'data/hive_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  runApp(const MessBillingApp());
}

class MessBillingApp extends StatelessWidget {
  const MessBillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mess Billing Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant, size: 64, color: Color(0xFF1565C0)),
              SizedBox(height: 16),
              Text(
                'Mess Billing Manager',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Module 1: Foundation Complete ✓',
                style: TextStyle(color: Colors.green, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                'Module 2: UI Shell — coming next',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
