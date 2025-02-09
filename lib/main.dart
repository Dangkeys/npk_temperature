import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: Color(0xFFFFA07A),
      ),
      home: const SensorScreen(),
    );
  }
}

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String description = '';
  double nitrogen = 0.0;
  double phosphorus = 0.0;
  double potassium = 0.0;
  double temperature = 0.0;
  double humidity = 0.0;
  bool isLoading = true;
  StreamSubscription? _subscription;

  // Recommended ranges for sugarcane
  static const tempRange = {'min': 20.0, 'max': 35.0}; // °C
  static const humidRange = {'min': 70.0, 'max': 85.0}; // %
  static const nitrogenRange = {'min': 40.0, 'max': 80.0}; // mg/kg
  static const phosphorusRange = {'min': 20.0, 'max': 40.0}; // mg/kg
  static const potassiumRange = {'min': 80.0, 'max': 120.0}; // mg/kg

  bool isInRange(double value, Map<String, double> range) {
    return value >= range['min']! && value <= range['max']!;
  }

  String getPlantHealthStatus() {
    int outOfRangeCount = 0;
    
    if (!isInRange(temperature, tempRange)) outOfRangeCount++;
    if (!isInRange(humidity, humidRange)) outOfRangeCount++;
    if (!isInRange(nitrogen, nitrogenRange)) outOfRangeCount++;
    if (!isInRange(phosphorus, phosphorusRange)) outOfRangeCount++;
    if (!isInRange(potassium, potassiumRange)) outOfRangeCount++;
    
    if (outOfRangeCount == 0) return 'Healthy';
    if (outOfRangeCount <= 2) return 'Warning';
    return 'Critical';
  }

  Color getValueColor(double value, Map<String, double> range) {
    return isInRange(value, range) ? Colors.green.shade700 : Colors.red.shade700;
  }

  @override
  void initState() {
    super.initState();
    _setupRealtimeUpdates();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeUpdates() {
    _subscription = _database.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        if (mounted) {
          setState(() {
            description = data['description']?.toString() ?? 'N/A';
            nitrogen = (data['nitrogen']?.toDouble() ?? 0.0);
            phosphorus = (data['phosphorus']?.toDouble() ?? 0.0);
            potassium = (data['potassium']?.toDouble() ?? 0.0);
            temperature = (data['temperature']?.toDouble() ?? 0.0);
            humidity = (data['humidity']?.toDouble() ?? 0.0);
            isLoading = false;
          });
        }
      }
    }, onError: (error) {
      print('Error: $error');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'AgroTech Soil',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Humidity (%)',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '${humidity.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: getValueColor(humidity, humidRange),
                                        ),
                                      ),
                                      Text(
                                        'Recommended: ${humidRange['min']}-${humidRange['max']}%',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Temperature (°C)',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        temperature.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: getValueColor(temperature, tempRange),
                                        ),
                                      ),
                                      Text(
                                        'Recommended: ${tempRange['min']}-${tempRange['max']}°C',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: getPlantHealthStatus() == 'Healthy' 
                                        ? Colors.green.shade100
                                        : getPlantHealthStatus() == 'Critical'
                                            ? Colors.red.shade100
                                            : Colors.orange.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          getPlantHealthStatus(),
                                          style: TextStyle(
                                            color: getPlantHealthStatus() == 'Healthy' 
                                                ? Colors.green.shade700
                                                : getPlantHealthStatus() == 'Critical'
                                                    ? Colors.red.shade700
                                                    : Colors.orange.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Overall',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: getPlantHealthStatus() == 'Healthy' 
                                                ? Colors.green.shade700
                                                : getPlantHealthStatus() == 'Critical'
                                                    ? Colors.red.shade700
                                                    : Colors.orange.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'More Specific',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildNutrientCard(
                      'Nitrogen',
                      nitrogen,
                      nitrogenRange,
                    ),
                    const SizedBox(height: 8),
                    _buildNutrientCard(
                      'Phosphorus',
                      phosphorus,
                      phosphorusRange,
                    ),
                    const SizedBox(height: 8),
                    _buildNutrientCard(
                      'Potassium',
                      potassium,
                      potassiumRange,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNutrientCard(
      String title, double value, Map<String, double> range) {
    final bool isInValidRange = isInRange(value, range);
    
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: title == 'Nitrogen' 
          ? Colors.red.shade200
          : title == 'Phosphorus'
              ? Colors.green.shade200
              : Colors.blue.shade200,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: isInValidRange ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'normal value is between ${range['min']}-${range['max']} mg/kg',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${value.toStringAsFixed(2)} mg/kg',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isInValidRange ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}