import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class MassPage extends StatefulWidget {
  @override
  _MassPageState createState() => _MassPageState();
}

class _MassPageState extends State<MassPage> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _massController = TextEditingController();
  final TextEditingController _berryMassController = TextEditingController();
  final TextEditingController _numOfBerriesController = TextEditingController();

  bool hasValidBarcode = false;
  Future<Map<String, dynamic>>? futureData;

  @override
  void initState() {
    super.initState();
    _barcodeController.addListener(_onBarcodeChange);
    futureData = _loadData();
  }

  @override
  void dispose() {
    _barcodeController.removeListener(_onBarcodeChange);
    _barcodeController.dispose();
    _massController.dispose();
    _berryMassController.dispose();
    _numOfBerriesController.dispose();
    super.dispose();
  }

  void _onBarcodeChange() {
    setState(() {
      futureData = _loadData();
    });
  }

  Future<void> _saveData() async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = '${dir.path}/entries.json';
    File file = File(path);
    if (await file.exists()) {
      String contents = await file.readAsString();
      List<dynamic> data = jsonDecode(contents);
      for (dynamic item in data) {
        Map<String, dynamic> itemMap = item as Map<String, dynamic>; // Add this line to cast the item to a map
        if (itemMap['dummyCode'] == _barcodeController.text) {
          itemMap['mass'] = _massController.text;
          itemMap['xBerryMass'] = _berryMassController.text;
          itemMap['numOfBerries'] = _numOfBerriesController.text;
          break;
        }
      }
      // Save the updated data back to the file
      await file.writeAsString(jsonEncode(data));
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mass Updated')));
    } else {
      throw Exception('File not found');
    }
  }

  Future<void> _saveBackupData() async {
    // Update the corresponding entry in your JSON file here

    Directory dir = await getApplicationDocumentsDirectory();
    String path = '${dir.path}/backup.json'; // <-- Change to backup.json
    File file = File(path);
    if (await file.exists()) {
      String contents = await file.readAsString();
      List<dynamic> data = jsonDecode(contents);
      for (dynamic item in data) {
        Map<String, dynamic> itemMap = item as Map<String, dynamic>;
        if (itemMap['dummyCode'] == _barcodeController.text) {
          itemMap['mass'] = _massController.text;
          itemMap['xBerryMass'] = _berryMassController.text;
          itemMap['numOfBerries'] = _numOfBerriesController.text;
          break;
        }
      }

      // Save the updated data back to the file
      await file.writeAsString(jsonEncode(data));
    } else {
      throw Exception('Backup file not found');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Enter Mass"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(   // Changed from Column to ListView
          children: <Widget>[
            TextField(
              controller: _barcodeController,
              decoration: InputDecoration(labelText: "Barcode"),
            ),
            SizedBox(height: 20),
            FutureBuilder<Map<String, dynamic>>(
              future: futureData,
              //future: _loadData(),
              builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
                if (_barcodeController.text.isEmpty) {
                  return Text('Please enter a barcode', style: TextStyle(fontSize: 18));
                } else if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}', style: TextStyle(fontSize: 18));
                } else if (snapshot.hasData) {
                  // Display the data on a Card
                  return Container(
                    width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${snapshot.data!['genotype']}',
                              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                            ),
                            Text('Site: ${snapshot.data!['site']}', style: TextStyle(fontSize: 22)),
                            Text('Block: ${snapshot.data!['block']}', style: TextStyle(fontSize: 22)),
                            Text('Stage: ${snapshot.data!['stage']}', style: TextStyle(fontSize: 22)),
                            Text('Box Num: ${snapshot.data!['box']}', style: TextStyle(fontSize: 22)),
                            Text('Bush Num: ${snapshot.data!['bush']}', style: TextStyle(fontSize: 22)),
                            // Add more fields as needed
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  return Text('No data', style: TextStyle(fontSize: 18)); // Add this line to handle case when no data is present
                }
              },
            ),
            if (hasValidBarcode) Column(
              children: <Widget>[
                TextField(
                  controller: _massController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "Mass"),
                ),
                TextField(
                  controller: _berryMassController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "xBerryMass"),
                ),
                TextField(
                  controller: _numOfBerriesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "NumOfBerries"),
                ),
                ElevatedButton(
                  child: Text("Save"),
                  onPressed: () async {
                    await _saveData();
                    await _saveBackupData();
                    // After the data has been saved, clear the text fields.
                    _barcodeController.clear();
                    _massController.clear();
                    _berryMassController.clear();
                    _numOfBerriesController.clear();
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadData() async {
    if (_barcodeController.text.isEmpty) {
      setState(() { hasValidBarcode = false; });
      return {}; // If no barcode is entered, return an empty map
    }

    String barcode = _barcodeController.text;
    Directory dir = await getApplicationDocumentsDirectory();
    String path = '${dir.path}/entries.json';
    File file = File(path);
    if (await file.exists()) {
      String contents = await file.readAsString();
      List<dynamic> data = jsonDecode(contents);
      for (Map<String, dynamic> item in data) {
        if (item['dummyCode'] == barcode) {
          // Populate text fields with existing values, or use default values.
          _massController.text = item['mass'] ?? '';
          _berryMassController.text = item['xBerryMass'] ?? '';
          _numOfBerriesController.text = item['numOfBerries'] ?? '25'; // Default value is 25

          setState(() { hasValidBarcode = true; });
          return item;
        }
      }
    }
    setState(() { hasValidBarcode = false; });
    throw Exception('Barcode not found');
  }

}
