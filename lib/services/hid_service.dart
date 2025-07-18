import 'package:dartusbhid/enumerate.dart';
import 'package:dartusbhid/open_device.dart';
import 'package:dartusbhid/usb_device.dart';
import 'package:smart_probe_scope/class/datasource_type.dart';
import 'package:smart_probe_scope/class/waveform_type.dart';
import 'package:smart_probe_scope/services/mock_hid_service.dart';

MockHidService mockHidService = MockHidService();

WaveformType currentType = WaveformType.sine;
DataSourceType currentSource = DataSourceType.mouse;

class HidService {
  late USBDeviceInfo device;
  late OpenUSBDevice session;
  bool _initialized = false;

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

  // Fake Data
  Future<List<double>> readFakeWaveform() async {
    return mockHidService.readWaveform(currentType, currentSource);
  }

  Future<void> dispose() async {
    _initialized = false;
    await session.close();
  }

  Future<bool> isInitialized() async => _initialized;
}
