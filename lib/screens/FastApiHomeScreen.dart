import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FastApiDataScreen(),
    );
  }
}

class FastApiDataScreen extends StatefulWidget {
  @override
  _FastApiDataScreenState createState() => _FastApiDataScreenState();
}

class _FastApiDataScreenState extends State<FastApiDataScreen> {
  List<dynamic> _data = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchData(); // Fetch data on screen load
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) => _fetchData()); // Auto-refresh every 2 seconds
  }

  Future<void> _fetchData() async {
    const String url = 'https://your-fastapi-endpoint.com/data'; // Replace with your API endpoint

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _data = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching data: $error");
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer to avoid memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FastAPI Data'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _data.isEmpty
          ? Center(child: Text('No data available'))
          : ListView.builder(
        itemCount: _data.length,
        itemBuilder: (context, index) {
          final item = _data[index];
          return ListTile(
            title: Text(item['name'] ?? 'No Name'), // Customize based on your API response
            subtitle: Text('ID: ${item['id']}'), // Customize as needed
          );
        },
      ),
    );
  }
}
