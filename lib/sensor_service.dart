import 'dart:async';

class SensorService {
  bool isConnected = false;
  Timer? updateTimer;

  void Function()? onConnected;
  void Function()? onDisconnected;
  void Function(List<double>)? onWaveform;

  void init() {
    // 假設初始狀態為未接入
    isConnected = false;

    // 模擬接入：可替換為真實裝置偵測邏輯
    Future.delayed(const Duration(seconds: 1), () {
      isConnected = true;
      onConnected?.call();
      startUpdateTimer();
    });
  }

  void dispose() {
    updateTimer?.cancel();
    updateTimer = null;
    onDisconnected?.call();
  }

  void startUpdateTimer() {
    updateTimer?.cancel();
    updateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final data = List.generate(
        64,
        (i) => (i % 32 - 16).toDouble() / 16,
      ); // 假資料
      onWaveform?.call(data);
    });
  }
}
