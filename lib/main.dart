import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'waveform_chart.dart';
import 'class/waveform_type.dart';
import 'class/datasource_type.dart';
import 'hid_service.dart';
import 'mock_hid_service.dart';

final HidService hid = HidService();
final MockHidService mockHidService = MockHidService();

void main() => runApp(const SmartProbeApp());

class SmartProbeApp extends StatefulWidget {
  const SmartProbeApp({super.key});
  @override
  _SmartProbeAppState createState() => _SmartProbeAppState();
}

class _SmartProbeAppState extends State<SmartProbeApp> {
  WaveformType currentType = WaveformType.sine;
  DataSourceType currentSource = DataSourceType.mouse;
  List<FlSpot> waveform = [];

  Timer? hidTimer;
  double amplitude = 1.0;
  double frequency = 3.0;

  @override
  void initState() {
    super.initState();
    hid.init();
  }

  @override
  void dispose() {
    hidTimer?.cancel();
    hid.dispose();
    super.dispose();
  }

  void startHidWaveformTimer() {
    hidTimer?.cancel();
    hidTimer = Timer.periodic(Duration(milliseconds: 100), (_) async {
      final data = mockHidService.readWaveform(
        currentType,
        currentSource,
        amplitude: amplitude,
        frequency: frequency,
      );
      setState(() {
        waveform = List.generate(
          data.length,
          (i) => FlSpot(i.toDouble(), data[i]),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMouseMode = currentSource == DataSourceType.mouse;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Smart Probe Scope')),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: isMouseMode
                    ? MouseRegion(
                        onHover: (event) {
                          mockHidService.updateMouse(event.localPosition);
                          final data = mockHidService.readWaveform(
                            currentType,
                            currentSource,
                            amplitude: amplitude,
                            frequency: frequency,
                          );
                          setState(() {
                            waveform = List.generate(
                              data.length,
                              (i) => FlSpot(i.toDouble(), data[i]),
                            );
                          });
                        },
                        child: WaveformChart(points: waveform),
                      )
                    : waveform.isNotEmpty
                    ? WaveformChart(points: waveform)
                    : const Center(
                        child: Text(
                          '等待 Smart Probe 資料...',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 4.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('波型：', style: TextStyle(fontSize: 16)),
                        DropdownButton<WaveformType>(
                          value: currentType,
                          isExpanded: true,
                          items: WaveformType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.name.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (type) =>
                              setState(() => currentType = type!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('資料來源：', style: TextStyle(fontSize: 16)),
                        Row(
                          children: DataSourceType.values.map((src) {
                            final label = src == DataSourceType.mouse
                                ? '滑鼠模擬'
                                : 'Smart Probe (HID)';
                            return Expanded(
                              child: RadioListTile<DataSourceType>(
                                title: Text(
                                  label,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                value: src,
                                groupValue: currentSource,
                                onChanged: (newSrc) async {
                                  if (newSrc != null) {
                                    setState(() {
                                      currentSource = newSrc;
                                      waveform = [];
                                    });

                                    if (newSrc == DataSourceType.hid) {
                                      final ok = await hid.init();
                                      if (!ok) return;
                                      startHidWaveformTimer();
                                    } else {
                                      hidTimer?.cancel();
                                    }
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (currentSource == DataSourceType.hid) ...[
              Column(
                children: [
                  const Text('振幅強度：', style: TextStyle(fontSize: 14)),
                  Slider(
                    value: amplitude,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    label: amplitude.toStringAsFixed(2),
                    onChanged: (value) {
                      setState(() => amplitude = value);
                      startHidWaveformTimer();
                    },
                  ),
                  const Text('跳動頻率：', style: TextStyle(fontSize: 14)),
                  Slider(
                    value: frequency,
                    min: 1.0,
                    max: 5.0,
                    divisions: 10,
                    label: frequency.toStringAsFixed(2),
                    onChanged: (value) {
                      setState(() => frequency = value);
                      startHidWaveformTimer();
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
