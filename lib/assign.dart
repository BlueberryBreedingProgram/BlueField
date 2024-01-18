import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AssignPage extends StatefulWidget {
  @override
  _AssignPageState createState() => _AssignPageState();
}

class _AssignPageState extends State<AssignPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>(); // Add this line
  List<String> _blockOptions = ["Other"];
  String? _stage, _site, _block, _bush = "1", _box = "1";
  bool _isSiteOther = false, _isBlockOther = false;
  String? _project = "BP"; // Default value for Project
  List<String> _projectOptions = ["BP"];
  final TextEditingController _dummyCodeController = TextEditingController();
  final TextEditingController _genotypeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _siteOtherController = TextEditingController();
  final TextEditingController _blockOtherController = TextEditingController();

  // Define formKey to validate form inputs
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadBlockOptions();
    _loadProjectOptions();
  }

  Future<void> _loadProjectOptions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String projectOptions = prefs.getString('projectOptions') ?? '';
    setState(() {
      _projectOptions = projectOptions.split(',').map((s) => s.trim()).toList();
      _projectOptions.insert(0, "BP"); // Add default value "BP" as the first option
    });
  }

  Future<void> _loadBlockOptions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String blockOptions = prefs.getString('blockOptions') ?? '';
    setState(() {
      _blockOptions = blockOptions.split(',').map((s) => s.trim()).toList();
      _blockOptions.add("Other");
    });
  }

  Future<bool> _dummyCodeExists(String dummyCode) async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = '${dir.path}/entries.json';
    File file = File(path);
    if (await file.exists()) {
      String contents = await file.readAsString();
      List<dynamic> data = jsonDecode(contents);
      for (Map<String, dynamic> item in data) {
        if (item['dummyCode'] == dummyCode) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _saveForm() async {
    String dummyCode = _dummyCodeController.text;
    String genotype = _genotypeController.text;

    // Check if form inputs are valid
    if (_formKey.currentState!.validate()) {
      if (await _dummyCodeExists(dummyCode)) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Duplicate Dummy Code'),
              content: Text('The code entered has already been recorded on this device, delete the existing entry if this is a mistake.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        return;
      } else {
        if (dummyCode == "" || genotype == "") {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Enter a Code or Geno')));
        }
        else {
          DateTime now = DateTime.now();
          String week = _getWeekOfYear(now).toString();
          String dateAndTime = now.toIso8601String();

          Map<String, dynamic> formData = {
            'dummyCode': dummyCode,
            'genotype': genotype,
            'notes': _notesController.text,
            'stage': _stage,
            'site': _isSiteOther ? _siteOtherController.text : _site,
            'block': _isBlockOther ? _blockOtherController.text : _block,
            'bush': _bush,
            'box': _box,
            'mass': "",
            'xBerryMass': "",
            'numOfBerries': "",
            'pH': "",
            'Brix': "",
            'Juice Mass': "",
            'TTA': "",
            'ml Added': "",
            'week': week,  // Add week
            'dateAndTime': dateAndTime,
            'project': _project,// Add dateAndTime
          };

          Directory dir = await getApplicationDocumentsDirectory();
          String path1 = '${dir.path}/entries.json';
          String path2 = '${dir.path}/backup.json';

          // Read existing data
          List<dynamic> data = [];
          File file1 = File(path1);
          File file2 = File(path2);
          if (await file1.exists() && await file2.exists()) {
            String contents1 = await file1.readAsString();
            String contents2 = await file2.readAsString();
            data = jsonDecode(contents1);
            if (data.length != jsonDecode(contents2).length) {
              // Backup is not in sync, use backup data
              data = jsonDecode(contents2);
            }
          }

          // Append new data
          data.add(formData);

          // Save data
          await file1.writeAsString(jsonEncode(data));
          await file2.writeAsString(jsonEncode(data));

          // Show a SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Code Assigned')));

          // Reset fields
          _dummyCodeController.clear();
          _genotypeController.clear();
          _notesController.clear();
          setState(() {
            _stage = null;
            _site = null;
            _block = null;
            _bush = "1";
            _box = "1";
            _isSiteOther = false;
            _isBlockOther = false;
            _project = "BP";
          });
        }
      }
    }
  }

  int _getWeekOfYear(DateTime date) {
    int dayOfYear = int.parse(DateFormat('D').format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Assign Barcode"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
    child: Form(  // Wrap ListView with Form widget
    key: _formKey,
        child: ListView(
          children: <Widget>[
            TextField(
              controller: _dummyCodeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Dummy Code"),
            ),
            TextField(
              controller: _genotypeController,
              decoration: InputDecoration(labelText: "Genotype"),
            ),
            DropdownButtonFormField<String>(
              value: _stage,
              items: ["Early", "Middle", "Late", "N/A"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _stage = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a Stage';
                }
                return null;
              },
              decoration: InputDecoration(labelText: "Stage"),
            ),
            DropdownButtonFormField<String>(
              value: _site,
              items: ["Waldo", "Citra", "Windsor", "Other"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _site = newValue;
                  _isSiteOther = newValue == "Other";
                });
              },
              decoration: InputDecoration(labelText: "Site"),
            ),
            if (_isSiteOther)
              TextField(
                controller: _siteOtherController,
                decoration: InputDecoration(labelText: "Other Site"),
              ),
            DropdownButtonFormField<String>(
              value: _block,
              items: _blockOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _block = newValue;
                  _isBlockOther = newValue == "Other";
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a Block';
                }
                return null;
              },
              decoration: InputDecoration(labelText: "Block"),
            ),
            if (_isBlockOther)
              TextField(
                controller: _blockOtherController,
                decoration: InputDecoration(labelText: "Other Block"),
              ),
            DropdownButtonFormField<String>(
              value: _project,
              items: _projectOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _project = newValue;
                });
              },
              decoration: InputDecoration(labelText: "Project"),
            ),
            DropdownButtonFormField<String>(
              value: _box,
              items: ["1", "2", "3", "4"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _box = newValue;
                });
              },
              decoration: InputDecoration(labelText: "Box Number"),
            ),
            DropdownButtonFormField<String>(
              value: _bush,
              items: ["1", "2", "3", "4"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _bush = newValue;
                });
              },
              decoration: InputDecoration(labelText: "Bush"),
            ),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(labelText: "Notes"),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              child: Text('Save'),
              onPressed: _saveForm,
            ),
          ],
        ),
    ),
      ),
    );
  }

  @override
  void dispose() {
    _dummyCodeController.dispose();
    _genotypeController.dispose();
    _notesController.dispose();
    _siteOtherController.dispose();
    _blockOtherController.dispose();
    super.dispose();
  }
}

