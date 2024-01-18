import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';


class ReviewPage extends StatefulWidget {
  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class NoDataException implements Exception {
  final String message;

  NoDataException(this.message);
}

class _ReviewPageState extends State<ReviewPage> {
  late Future<List<Map<String, dynamic>>> futureData;
  late int totalCodes;
  late int fqLabSamples;
  final DatabaseReference databaseReference = FirebaseDatabase.instance.reference();

  @override
  void initState() {
    super.initState();
    futureData = _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Review Data"),
        actions: <Widget>[
          StreamBuilder<ConnectivityResult>(
            stream: Connectivity().onConnectivityChanged,
            builder: (BuildContext context, AsyncSnapshot<ConnectivityResult> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(); // or some loading indicator
              }
              bool connected = snapshot.data != ConnectivityResult.none;
              return ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(connected ? Colors.green : Colors.red),
                ),
                child: Text('Upload', style: TextStyle(color: Colors.white)),
                onPressed: connected ? _uploadData : _showNoInternetWarning,
              );
            },
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: futureData,
        builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            if (snapshot.error is NoDataException) {
              return Center(
                child: Text(
                  (snapshot.error as NoDataException).message,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              );
            } else {
              return Text('Error: ${snapshot.error}', style: TextStyle(fontSize: 18));
            }
          } else if (snapshot.hasData) {
            return Column(
              children: <Widget>[
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCountItem('Total Codes Assigned', totalCodes, Colors.black),
                    _buildCountItem('Samples for FQ Lab', fqLabSamples, Colors.red),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> item = snapshot.data![index];
                      return Card(
                        child: ListTile(
                          title: Text(item['genotype'] ?? ''),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${item['dummyCode']}'),
                              Text('${item['site']} ${item['block']} ${item['stage']} Bx: ${item['box']} Bsh: ${item['bush']} ${item['project']}'),
                              Text('Mass: ${item['mass']} xBerryMass: ${item['xBerryMass']} x#Berries: ${item['numOfBerries']}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteData(index);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          } else {
            return Text('No data', style: TextStyle(fontSize: 18));
          }
        },
      ),
    );
  }

  void _uploadData() async {
    if (!await hasInternet()) {
      _showNoInternetWarning();
      return;
    }
    try {
      // Load the data from the file
      List<Map<String, dynamic>> data = await _loadData();

      // Get the current year
      String currentYear = DateTime.now().year.toString();

      // Use the current year in the database reference
      DatabaseReference fruitQualityRef = databaseReference.child('fruit_quality_$currentYear');

      // Loop over the data and push to Firebase
      for (var item in data) {
        String key = item['dummyCode'].toString();
        await fruitQualityRef.child(key).set(item);
      }

      // Delete the local data file after successful upload
      Directory dir = await getApplicationDocumentsDirectory();
      String path = '${dir.path}/entries.json';
      File file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      setState(() {
        futureData = _loadData();
      });
    } catch (e) {
      // Display the error message
      print('Failed to upload: $e');
    }
  }

  void _showNoInternetWarning() {
    // Show a dialog telling the user to connect to the internet
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('No Internet Connection'),
        content: Text('Please connect to the internet to upload data.'),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }


  Future<List<Map<String, dynamic>>> _loadData() async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = '${dir.path}/entries.json';
    File file = File(path);
    if (await file.exists()) {
      String contents = await file.readAsString();
      List<dynamic> data = jsonDecode(contents);
      totalCodes = data.length;
      fqLabSamples = data.where((item) => ['Early', 'Middle', 'Late'].contains(item['stage'])).length;
      return List<Map<String, dynamic>>.from(data).reversed.toList();
    }
    throw NoDataException('No Data Yet!');
  }

  void _deleteData(int index) async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = '${dir.path}/entries.json';
    File file = File(path);
    if (await file.exists()) {
      String contents = await file.readAsString();
      List<dynamic> data = jsonDecode(contents);
      data = data.reversed.toList();  // Reverse to original order for correct deletion
      data.removeAt(index);
      await file.writeAsString(jsonEncode(data));
      setState(() {
        futureData = _loadData();
      });
    }
  }

  Future<bool> hasInternet() async {
    try {
      final response = await InternetAddress.lookup('facebook.com');
      if (response.isNotEmpty && response[0].rawAddress.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } on SocketException catch (_) {
      return false;
    }
  }

  Widget _buildCountItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

