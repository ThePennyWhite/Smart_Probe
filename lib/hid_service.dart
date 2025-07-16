import 'package:dartusbhid/enumerate.dart';
import 'package:dartusbhid/open_device.dart';
import 'package:dartusbhid/usb_device.dart';
import 'package:smart_probe_scope/class/datasource_type.dart';
import 'package:smart_probe_scope/class/waveform_type.dart';
import 'mock_hid_service.dart';

MockHidService mockHidService = MockHidService();

WaveformType currentType = WaveformType.sine;
DataSourceType currentSource = DataSourceType.mouse;

class HidService {
  late USBDeviceInfo device;
  late OpenUSBDevice session;

  Future<bool> init() async {
    final devices = await enumerateDevices(0, 0);
    if (devices.isEmpty) return false;

    device = devices.first;
    session = await device.open();
    return true;
  }

  Future<List<double>> readWaveform() async {
    final data = await session.readReport(null);
    return data.map((b) => (b - 128) / 128.0).toList(); // 範例：轉換為 ±1 區間
  }

  Future<List<double>> readFakeWaveform() async {
    return mockHidService.readWaveform(currentType, currentSource);
  }

  Future<void> dispose() async {
    await session.close();
  }
}
