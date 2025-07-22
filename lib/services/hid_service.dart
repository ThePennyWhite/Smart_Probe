import 'dart:math';
import 'dart:ui';

import 'package:dartusbhid/enumerate.dart';
import 'package:dartusbhid/open_device.dart';
import 'package:dartusbhid/usb_device.dart';
import 'package:smart_probe_scope/enum.dart';

WaveformType currentType = WaveformType.sine;
DataSourceType currentSource = DataSourceType.mouse;

class HidService {
  late USBDeviceInfo device;
  late OpenUSBDevice session;
  bool _initialized = false;
  Offset mousePosition = Offset.zero;

  void updateMouse(Offset position) {
    mousePosition = position;
  }

  Future<bool> init() async {
    if (_initialized) return true;

    final devices = await enumerateDevices(0, 0);
    if (devices.isEmpty) return false;

    device = devices.first;
    session = await device.open();
    _initialized = true;
    return true;
  }

  // ToBeDone: Reads waveform data from the HID device
  Future<List<double>> readWaveform(
    WaveformType currentType, {
    required double amplitude,
    required double frequency,
  }) async {
    final data = await session.readReport(null);
    return data.map((b) => (b - 128) / 128.0).toList(); // 範例：轉換為 ±1 區間
  }

  List<double> readFakeWaveform(
    WaveformType type,
    DataSourceType source, {
    double amplitude = 1.0,
    double frequency = 3.0,
  }) {
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;

    if (source == DataSourceType.hid) {
      return List.generate(64, (i) {
        final x = frequency * (t + i / 10);
        return switch (type) {
          WaveformType.sine => amplitude * sin(x),
          WaveformType.triangle =>
            amplitude * (2 * ((x / pi) % 1.0) - 1.0), // ✅ 加入 triangle 波型
          WaveformType.noise => amplitude * (Random().nextDouble() * 2 - 1),
          _ => 0.0,
        };
      });
    }

    final x = mousePosition.dx;
    final y = mousePosition.dy;
    final offset = (x + y + t * 10) / 20;

    return List.generate(64, (i) {
      final signal = frequency * (offset + i / 10);
      return switch (type) {
        WaveformType.sine => amplitude * sin(signal),
        WaveformType.triangle =>
          amplitude * (2 * ((signal / pi) % 1.0) - 1.0), // ✅ 加入 triangle 波型
        WaveformType.noise => amplitude * (Random().nextDouble() * 2 - 1),
        _ => 0.0,
      };
    });
  }

  Future<void> dispose() async {
    _initialized = false;
    await session.close();
  }

  Future<bool> isInitialized() async => _initialized;
}
