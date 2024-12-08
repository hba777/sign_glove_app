import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothSensorDataScreen extends StatefulWidget {
  @override
  _BluetoothSensorDataScreenState createState() =>
      _BluetoothSensorDataScreenState();
}

class _BluetoothSensorDataScreenState
    extends State<BluetoothSensorDataScreen> {
  //FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  List<BluetoothService>? services;

  List<double> flexData = [];
  List<double> gyroData = [];
  bool isConnecting = false;

  @override
  void initState() {
    super.initState();
    scanAndConnect();
  }

  void scanAndConnect() async {
    setState(() => isConnecting = true);
    //    flutterBlue.scan(timeout: Duration(seconds: 5)).listen((scanResult) async {
    FlutterBluePlus.scan().listen((scanResult) async {
      print('Found device: ${scanResult.device.name}');
      if (scanResult.device.name == "JDY-31-SPP") {
        // Replace with your device name
        await scanResult.device.connect();
        setState(() {
          connectedDevice = scanResult.device;
          isConnecting = false;
        });
        discoverServices();
      }
    });
  }

  void discoverServices() async {
    if (connectedDevice == null) return;
    services = await connectedDevice!.discoverServices();
    for (var service in services!) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.read ||
            characteristic.properties.notify) {
          characteristic.value.listen((value) {
            String data = String.fromCharCodes(value);
            handleReceivedData(data);
          });
          await characteristic.setNotifyValue(true);
        }
      }
    }
  }

  void handleReceivedData(String jsonData) {
    try {
      var parsedData = jsonDecode(jsonData);
      List<double> flex = List<double>.from(parsedData['flex']);
      List<double> gyro = List<double>.from(parsedData['gyro']);
      setState(() {
        flexData = flex;
        gyroData = gyro;
      });
      print('Flex data: $flex');
      print('Gyro data: $gyro');
    } catch (e) {
      print('Error parsing data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Data via Bluetooth'),
      ),
      body: isConnecting
          ? const Center(child: CircularProgressIndicator())
          : connectedDevice == null
          ? const Center(child: Text("Scanning for JDY-31-SPP..."))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connected to: ${connectedDevice!.name}',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Flex Sensor Data:',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            flexData.isEmpty
                ? const Text("No data received")
                : Column(
              children: flexData
                  .map((value) => Text('Value: $value'))
                  .toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Gyroscope Data:',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            gyroData.isEmpty
                ? const Text("No data received")
                : Column(
              children: gyroData
                  .map((value) => Text('Value: $value'))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
