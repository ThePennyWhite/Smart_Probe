import 'dart:async';
import 'package:dartusbhid/enumerate.dart';
import 'package:dartusbhid/usb_device.dart';

typedef OnHidConnect = void Function(USBDeviceInfo d);
typedef OnHidDisconnect = void Function(USBDeviceInfo d);

class UsbHidDetector {
  final OnHidConnect onConnect;
  final OnHidDisconnect onDisconnect;
  final Duration interval;

  Timer? _timer;
  List<USBDeviceInfo> _prev = [];

  UsbHidDetector({
    required this.onConnect,
    required this.onDisconnect,
    this.interval = const Duration(seconds: 1),
  });

  Future<void> start() async {
    _prev = await enumerateDevices(0, 0);
    for (var d in _prev) {
      onConnect(d);
    }
    _timer = Timer.periodic(interval, (_) => _check());
  }

  void stop() {
    _timer?.cancel();
    _prev.clear();
  }

  Future<void> _check() async {
    final current = await enumerateDevices(0, 0);

    // 新增裝置
    for (var d in current.where(
      (c) => !_prev.any(
        (p) =>
            p.vendorId == c.vendorId &&
            p.productId == c.productId &&
            p.serialNumber == c.serialNumber,
      ),
    )) {
      onConnect(d);
    }

    // 拔除裝置
    for (var d in _prev.where(
      (p) => !current.any(
        (c) =>
            c.vendorId == p.vendorId &&
            c.productId == p.productId &&
            c.serialNumber == p.serialNumber,
      ),
    )) {
      onDisconnect(d);
    }

    _prev = current;
  }
}
