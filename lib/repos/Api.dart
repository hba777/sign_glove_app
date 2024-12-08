import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

class MyBluetoothService {

  // Scan for devices
  Future<List<BluetoothDevice>> scanDevices() async {
    List<BluetoothDevice> devices = [];
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        print('Found device: ${result.device.name}');
        devices.add(result.device);
      }
    });

    // Start scanning (you can modify conditions to stop scanning)
    FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
    return devices;
  }

  // Connect to a device
  Future<BluetoothDevice> connectToDevice(BluetoothDevice device) async {
    await device.connect();
    print("Connected to ${device.name}");
    return device;
  }

  // Read data from Arduino (via JDY-31 Bluetooth)
  // Read data from Arduino (via JDY-31 Bluetooth)
  Future<Map<String, double>> readDataFromArduino(BluetoothDevice? device) async {
    // Discover services
    List<BluetoothService> services = await device!.discoverServices();

    // Log all the services and their characteristics
    for (var service in services) {
      print("Service UUID: ${service.uuid}");
      for (var characteristic in service.characteristics) {
        print("Characteristic UUID: ${characteristic.uuid}");
      }
    }

    // Now, look for characteristics that support reading under the custom service
    BluetoothCharacteristic? characteristic;
    for (var service in services) {
      if (service.uuid.toString() == "1800") { // Check for the custom service UUID
        for (var char in service.characteristics) {
          if (char.uuid.toString() == "2a04" && char.properties.read) { // Readable characteristic UUID
            characteristic = char;
            break;
          }
        }
      }
    }

    if (characteristic != null) {
      var value = await characteristic.read(); // Read data from Arduino
      String dataString = String.fromCharCodes(value);
      log("Data received from Arduino: $value");

      // Parse the data into sensor values
      Map<String, double> sensorData = parseSensorData(dataString);
      return sensorData;
    } else {
      log("No readable characteristic found for sensor data");
      return {};
    }
  }

  // Parse the received data (comma-separated string) into a Map
  Map<String, double> parseSensorData(String data) {
    Map<String, double> sensorData = {};
    List<String> dataList = data.split(',');

    if (dataList.length >= 8) {
      sensorData['flex_1'] = double.tryParse(dataList[0]) ?? 0.0;
      sensorData['flex_2'] = double.tryParse(dataList[1]) ?? 0.0;
      sensorData['flex_3'] = double.tryParse(dataList[2]) ?? 0.0;
      sensorData['flex_4'] = double.tryParse(dataList[3]) ?? 0.0;
      sensorData['flex_5'] = double.tryParse(dataList[4]) ?? 0.0;
      sensorData['GYRx'] = double.tryParse(dataList[5]) ?? 0.0;
      sensorData['GYRy'] = double.tryParse(dataList[6]) ?? 0.0;
      sensorData['GYRz'] = double.tryParse(dataList[7]) ?? 0.0;
    }

    return sensorData;
  }
}

class PredictionService {
  static Future<String> fetchPrediction(Map<String, double> sensorData) async {
    final url = Uri.parse("http://192.168.0.124/predict/"); // Use localhost equivalent for emulator

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'flex_1': sensorData['flex_1'],
        'flex_2': sensorData['flex_2'],
        'flex_3': sensorData['flex_3'],
        'flex_4': sensorData['flex_4'],
        'flex_5': sensorData['flex_5'],
        'GYRx': sensorData['GYRx'],
        'GYRy': sensorData['GYRy'],
        'GYRz': sensorData['GYRz'],
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['predicted_label'].toString();
    } else {
      throw Exception("Failed to fetch prediction: ${response.reasonPhrase}");
    }
  }
}
