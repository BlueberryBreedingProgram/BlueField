import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share/share.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _blockOptionsController = TextEditingController();
  final TextEditingController _projectOptionsController = TextEditingController(); // Step 1

  @override
  void initState() {
    super.initState();
    _loadBlockOptions();
    _loadProjectOptions(); // Load project options
  }

  Future<void> _loadBlockOptions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String blockOptions = prefs.getString('blockOptions') ?? '';
    _blockOptionsController.text = blockOptions;
  }

  Future<void> _loadProjectOptions() async { // Step 2 - Load project options
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String projectOptions = prefs.getString('projectOptions') ?? '';
    _projectOptionsController.text = projectOptions;
  }

  Future<void> _saveBlockOptions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('blockOptions', _blockOptionsController.text);
  }

  Future<void> _saveProjectOptions() async { // Step 2 - Save project options
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('projectOptions', _projectOptionsController.text);
  }

  void _downloadCache() async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = '${dir.path}/backup.json';
    File file = File(path);

    if (await file.exists()) {
      Share.shareFiles([path], text: 'Backup file');
    }
  }

  void _clearCache() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm'),
          content: Text('Are you sure you want to clear the cache?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () async {
                Navigator.of(context).pop();

                Directory dir = await getApplicationDocumentsDirectory();
                String path = '${dir.path}/backup.json';
                File file = File(path);

                if (await file.exists()) {
                  await file.delete();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _blockOptionsController,
              decoration: InputDecoration(labelText: "Define Block Form Options: ex: 2016, 21B, W1A, South"),
            ),
            ElevatedButton(
              child: Text('Save'),
              onPressed: _saveBlockOptions,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _projectOptionsController, // Step 3 - Add new text field
              decoration: InputDecoration(labelText: "Define Project Options (excluding BP): ex: Special1, NIR"),
            ),
            ElevatedButton(
              child: Text('Save'),
              onPressed: _saveProjectOptions, // Step 3 - Add save button for the new field
            ),
            SizedBox(height: 20),// You can adjust this size as needed
            Text('Backup Cache', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10), // You can adjust this size as needed
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  child: Text('Download'),
                  onPressed: _downloadCache,
                ),
                ElevatedButton(
                  child: Text('Clear Cache'),
                  onPressed: _clearCache,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _blockOptionsController.dispose();
    _projectOptionsController.dispose();
    super.dispose();
  }
}
