import 'dart:async';
import 'dart:typed_data';
import 'package:dartusbhid/enumerate.dart';
import 'package:dartusbhid/open_device.dart';
import 'package:dartusbhid/usb_device.dart';
import 'package:flutter_usb_event/flutter_usb_event.dart';

typedef OnHidConnect = void Function(USBDeviceInfo device);
typedef OnHidDisconnect = void Function(USBDeviceInfo device);

class UsbHidDetector {
  static const int timeoutMillis = 10000;
  final OnHidConnect onConnect;
  final OnHidDisconnect onDisconnect;

  final _openDevices = <String, OpenUSBDevice>{};
  List<USBDeviceInfo> _prevDevices = [];

  UsbHidDetector({required this.onConnect, required this.onDisconnect});

  Future<void> start() async {
    // 初始快照：列舉 → 過濾 → 去重
    final all = await enumerateDevices(0, 0);
    _prevDevices = _uniqByPhysical(_filterHidInterfaces(all));

    FlutterUsbEvent.startListening(
      onDeviceConnected: (_) => _processChanged(),
      onDeviceDisconnected: (_) => _processChanged(),
    );
  }

  void stop() async {
    FlutterUsbEvent.stopListening();
    _prevDevices.clear();
    for (var d in _openDevices.values) {
      await d.close();
    }
    _openDevices.clear();
  }

  Future<void> _processChanged() async {
    // 等候 OS 把 HID interface 掛載完成
    await Future.delayed(Duration(milliseconds: 200));

    final all = await enumerateDevices(0, 0);
    final filtered = _filterHidInterfaces(all);
    final current = _uniqByPhysical(filtered);

    // 處理新插入
    for (var d in current.where((c) => !_existsIn(_prevDevices, c))) {
      onConnect(d);
      try {
        final dev = await d.open();
        print('Opened device: $d)');
        _openDevices[_deviceKey(d)] = dev;
        // Timer.periodic(Duration(milliseconds: timeoutMillis), (_) async {
        //   try {
        //     final report = await dev.readReport(null);
        //     _handleReport(report);
        //   } catch (e) {
        //     print('Read report error: $e');
        //   }
        // });
      } catch (e) {
        print('Open failed: $e');
      }
    }

    // 處理拔除
    for (var d in _prevDevices.where((p) => !_existsIn(current, p))) {
      onDisconnect(d);
      final key = _deviceKey(d);
      final dev = _openDevices.remove(key);
      if (dev != null) {
        try {
          await dev.close();
        } catch (e) {
          print('關閉裝置失敗：$e');
        }
      }
      print('Closed device: $d');
    }
    _prevDevices = current;
  }

  bool _existsIn(List<USBDeviceInfo> list, USBDeviceInfo d) =>
      list.any((p) => _deviceKey(p) == _deviceKey(d));

  List<USBDeviceInfo> _filterHidInterfaces(List<USBDeviceInfo> list) =>
      list.where((d) {
        final isGeneric = d.usagePage == 0 && d.usage == 0;
        final isGenericHid = d.usagePage == 1 && d.usage == 0;
        return !(isGeneric || isGenericHid);
      }).toList();

  List<USBDeviceInfo> _uniqByPhysical(List<USBDeviceInfo> list) {
    final map = <String, USBDeviceInfo>{};
    for (var d in list) {
      map.putIfAbsent(_deviceKey(d), () => d);
    }
    return map.values.toList();
  }

  void _handleReport(Uint8List report) {
    print('HID report: $report');
  }

  String _deviceKey(USBDeviceInfo d) => [
    d.vendorId.toRadixString(16).padLeft(4, '0'),
    d.productId.toRadixString(16).padLeft(4, '0'),
    d.serialNumber,
    d.interfaceNumber.toString(),
    d.usagePage.toRadixString(16).padLeft(2, '0'),
    d.usage.toRadixString(16).padLeft(2, '0'),
  ].join(':');
}
