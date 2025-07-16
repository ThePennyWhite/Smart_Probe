import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'waveform_chart.dart';
import 'waveform_type.dart';

void main() => runApp(SmartScopeApp());

class SmartScopeApp extends StatefulWidget {
  const SmartScopeApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SmartScopeAppState createState() => _SmartScopeAppState();
}

class _SmartScopeAppState extends State<SmartScopeApp> {
  WaveformType currentType = WaveformType.sine;
  List<FlSpot> waveform = [];

  @override
  void initState() {
    super.initState();
    setupWaveformTimer();
  }

  void setupWaveformTimer() {
    Timer.periodic(Duration(milliseconds: 100), (_) {
      final data = generateWaveform(currentType);
      setState(() {
        waveform = List.generate(
          data.length,
          (i) => FlSpot(i.toDouble(), data[i]),
        );
      });
    });
  }

  List<double> generateWaveform(WaveformType type) {
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    return List.generate(64, (i) {
      final x = t + i / 10;
      switch (type) {
        case WaveformType.sine:
          return sin(3 * x);
        case WaveformType.square:
          return sin(3 * x) > 0 ? 1.0 : -1.0;
        case WaveformType.triangle:
          return 2 * (x % 1.0) - 1.0;
        case WaveformType.noise:
          return Random().nextDouble() * 2 - 1;
        case WaveformType.fake:
          return (0.6 * (i % 16) / 16.0 + 0.4 * (i % 4) / 4.0) *
              (0.8 * sin(t + i / 10) + 0.2 * cos(t + i / 7));
        default:
          return 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Smart Probe Scope')),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: waveform.isNotEmpty
                    ? WaveformChart(points: waveform)
                    : Center(
                        child: Text(
                          '等待模擬資料...',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: DropdownButton<WaveformType>(
                value: currentType,
                items: WaveformType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (type) {
                  if (type != null) {
                    setState(() => currentType = type);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
