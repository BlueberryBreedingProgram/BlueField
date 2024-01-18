import 'package:blue_field_barcode/review.dart';

import 'mass.dart';
import 'settings.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'assign.dart'; // make sure this is the correct path to assign.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BlueField Barcode Application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          SizedBox(height: 110), // Add some spacing at the top
          Center(
            child: Column(
              children: [
                Image.asset('assets/mainlogo.png'), // Replace with your image path
                Text('BlueField Barcode Application', style: TextStyle(fontSize: 24)), // Adjust font size here
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              children: [
                IconWithCaption(icon: Icons.qr_code_scanner, caption: "Assign Barcode", onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AssignPage()),
                  );
                }),
                IconWithCaption(icon: Icons.monitor_weight, caption: "Enter Mass", onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MassPage()),
                  );
                },),
                IconWithCaption(icon: Icons.data_usage, caption: "Review Data", onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReviewPage()),
                  );
                },),
                IconWithCaption(icon: Icons.settings, caption: "Settings", onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                },),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class IconWithCaption extends StatelessWidget {
  final IconData icon;
  final String caption;
  final VoidCallback onTap;

  IconWithCaption({required this.icon, required this.caption, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 150), // Adjust size here
          Text(caption, style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
