import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_probe_scope/enum.dart';
import 'package:smart_probe_scope/services/hid_service.dart';
import 'package:flutter/material.dart';
import 'package:smart_probe_scope/waveform_chart.dart';
import 'package:smart_probe_scope/widget/desktop_monitor_view.dart';

class SmartProbeView extends StatefulWidget {
  const SmartProbeView({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _SmartProbeViewState createState() => _SmartProbeViewState();
}

class _SmartProbeViewState extends State<SmartProbeView> {
  final HidService hid = HidService();
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
      final data = hid.readFakeWaveform(
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
        appBar: AppBar(
          title: const Text('Smart Probe View'),
          actions: [
            IconButton(
              icon: const Icon(Icons.desktop_windows),
              tooltip: '進入桌面監控',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DesktopMonitorView()),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: isMouseMode
                    ? MouseRegion(
                        onHover: (event) {
                          hid.updateMouse(event.localPosition);
                          final data = hid.readFakeWaveform(
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
