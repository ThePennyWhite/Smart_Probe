import 'package:dartusbhid/enumerate.dart';
import 'package:dartusbhid/usb_device.dart';
import 'package:flutter/material.dart';
import 'package:smart_probe_scope/services/hid_detector.dart';
import 'package:smart_probe_scope/widget/smart_probe_view.dart';

class DesktopMonitorView extends StatefulWidget {
  const DesktopMonitorView({super.key});

  @override
  State<DesktopMonitorView> createState() => _DesktopMonitorAppState();
}

class _DesktopMonitorAppState extends State<DesktopMonitorView> {
  late UsbHidDetector _detector;
  bool _mouseConnected = false;
  final List<String> _log = [];

  /// 完整 HID Usage Page 名稱對應
  static const Map<int, String> _usagePageNames = {
    0x00: 'Undefined',
    0x01: 'Generic Desktop Controls',
    0x02: 'Simulation Controls',
    0x03: 'VR Controls',
    0x04: 'Sport Controls',
    0x05: 'Game Controls',
    0x06: 'Generic Device Controls',
    0x07: 'Keyboard/Keypad',
    0x08: 'LEDs',
    0x09: 'Button',
    0x0A: 'Ordinal',
    0x0B: 'Telephony',
    0x0C: 'Consumer',
    0x0D: 'Digitizer',
    // … 必要時可繼續擴充其他 Usage Page
  };

  /// 各 Usage Page 底下常見 Usage 名稱對應
  static const Map<int, Map<int, String>> _usageNames = {
    0x01: {
      0x00: 'Undefined',
      0x01: 'Pointer',
      0x02: 'Mouse',
      0x04: 'Joystick',
      0x05: 'Game Pad',
      0x06: 'Keyboard',
      0x07: 'Keypad',
      0x08: 'Multi-axis Controller',
      0x30: 'X',
      0x31: 'Y',
      0x32: 'Z',
      0x33: 'Rx',
      0x34: 'Ry',
      0x35: 'Rz',
      0x36: 'Slider',
      0x37: 'Dial',
      0x38: 'Wheel',
      0x39: 'Hat switch',
      0x3A: 'Counted Buffer',
      0x3B: 'Byte Count',
      0x3C: 'Motion Wakeup',
      0x3D: 'Start',
      0x3E: 'Select',
      // … 其他可依 USB HID Usage Tables 補充
    },
    0x02: {
      0x01: 'Flight Simulation Device',
      0x02: 'Automobile Simulation Device',
      0x03: 'Tank Simulation Device',
      0x04: 'Spaceship Simulation Device',
      // … 更多 Simulation Controls
    },
    0x07: {
      // 鍵盤／按鍵 Page，範例只列出少部分
      0x04: 'Keyboard a and A',
      0x05: 'Keyboard b and B',
      // … 0x06 ~ 0x65 Key values
    },
    0x08: {
      0x01: 'Num Lock',
      0x02: 'Caps Lock',
      0x03: 'Scroll Lock',
      // … 更多 LED
    },
    0x09: {
      // Button
      0x01: 'Button 1',
      0x02: 'Button 2',
      // … 依序至 Button 32、Button 64 …
    },
    0x0C: {
      0x01: 'Consumer Control',
      0x02: 'Numeric Key Pad',
      0x10: 'Power',
      0x20: 'Volume',
      0x21: 'Balance',
      // … 更多 Consumer Controls
    },
    // … 如有需要，再增加其它 Usage Page 的 mapping …
  };

  /// 根據 d.usagePage / d.usage 回傳對應名稱
  String _deviceType(USBDeviceInfo d) {
    final page = d.usagePage;
    final usage = d.usage;

    final pageName =
        _usagePageNames[page] ?? 'UsagePage(0x${page.toRadixString(16)})';
    final usageName =
        _usageNames[page]?[usage] ?? 'Usage(0x${usage.toRadixString(16)})';

    return '$pageName - $usageName';
  }

  void _onDeviceConnect(USBDeviceInfo d) {
    final vid = d.vendorId;
    final pid = d.productId;
    final up = d.usagePage;
    final u = d.usage;
    final sn = d.serialNumber;
    final mf = d.manufacturerString;
    final pn = d.productString;
    final type = _deviceType(d);

    final details =
        '''
【裝置接入】 $type
  VID             : $vid
  PID             : $pid
  UsagePage:Usage : $up  : $u
  serialNumber    : $sn
  manufacturer    : $mf
  productName     : $pn
''';

    setState(() {
      _log.insert(0, details);
      if (type == 'Mouse') _mouseConnected = true;
    });
  }

  void _onDeviceDisconnect(USBDeviceInfo d) {
    final vid = d.vendorId;
    final pid = d.productId;
    final up = d.usagePage;
    final u = d.usage;
    final sn = d.serialNumber;
    final mf = d.manufacturerString;
    final pn = d.productString;
    final type = _deviceType(d);

    final details =
        '''
【裝置拔除】 $type
  VID             : $vid
  PID             : $pid
  UsagePage:Usage : $up  : $u
  serialNumber    : $sn
  manufacturer    : $mf
  productName     : $pn
''';

    setState(() {
      _log.insert(0, details);
      if (type == 'Mouse') _mouseConnected = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _detector = UsbHidDetector(
      onConnect: _onDeviceConnect,
      onDisconnect: _onDeviceDisconnect,
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
          title: const Text('HID插拔監控'),
          actions: [
            Icon(
              _mouseConnected ? Icons.mouse : Icons.mouse_outlined,
              color: Colors.white,
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.graphic_eq),
              tooltip: 'Smart Probe View',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SmartProbeView()),
                );
              },
            ),
          ],
        ),
        body: _log.isEmpty
            ? const Center(child: Text('尚未偵測到事件'))
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
