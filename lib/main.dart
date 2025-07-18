import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_probe_scope/services/usb_hid_detector.dart';
import 'waveform_chart.dart';
import 'class/waveform_type.dart';
import 'class/datasource_type.dart';
import 'services/hid_service.dart';
import 'services/mock_hid_service.dart';

final HidService hid = HidService();
final MockHidService mockHidService = MockHidService();
void main() => runApp(const MouseMonitorApp());

class SmartProbeApp extends StatefulWidget {
  const SmartProbeApp({super.key});
  @override
  // ignore: library_private_types_in_public_api
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

  void stopHidWaveformTimer() {
    hidTimer?.cancel();
    hidTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final isMouseMode = currentSource == DataSourceType.mouse;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Smart Probe')),
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
                  const SizedBox(width: 15),
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
                  const SizedBox(width: 15),
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
                                      stopHidWaveformTimer();
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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

class MouseMonitorApp extends StatefulWidget {
  const MouseMonitorApp({super.key});

  @override
  State<MouseMonitorApp> createState() => _MouseMonitorAppState();
}

class _MouseMonitorAppState extends State<MouseMonitorApp> {
  late final UsbHidDetector _detector;
  bool _mouseConnected = false;
  final List<String> _log = [];

  @override
  void initState() {
    super.initState();
    _detector = UsbHidDetector(
      onConnect: (d) {
        // 判斷是否為 Boot Mouse (usagePage=1, usage=2)
        final isMouse = d.usagePage == 0x01 && d.usage == 0x02;
        if (isMouse) {
          setState(() {
            _mouseConnected = true;
            _log.insert(0, '滑鼠接入：VID=${d.vendorId}, PID=${d.productId}');
          });
        }
      },
      onDisconnect: (d) {
        final isMouse = d.usagePage == 0x01 && d.usage == 0x02;
        if (isMouse) {
          setState(() {
            _mouseConnected = false;
            _log.insert(0, '滑鼠拔除：VID=${d.vendorId}, PID=${d.productId}');
          });
        }
      },
      interval: const Duration(seconds: 1),
    );
    _detector.start();
  }

  @override
  void dispose() {
    _detector.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mouse Monitor',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('滑鼠插拔監控'),
          actions: [
            Icon(
              _mouseConnected ? Icons.mouse : Icons.mouse_outlined,
              color: Colors.white,
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: _log.isEmpty
            ? const Center(child: Text('尚未偵測到滑鼠事件'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _log.length,
                itemBuilder: (context, index) {
                  return Text(_log[index]);
                },
              ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
