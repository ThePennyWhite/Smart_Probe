import 'dart:math';
import 'dart:ui';
import 'class/datasource_type.dart';
import 'class/waveform_type.dart';

class MockHidService {
  Offset mousePosition = Offset.zero;

  void updateMouse(Offset position) {
    mousePosition = position;
  }

  List<double> readWaveform(
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
}
