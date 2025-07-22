import 'package:flutter/material.dart';
import 'package:smart_probe_scope/widget/desktop_monitor_view.dart';
import 'package:smart_probe_scope/widget/smart_probe_view.dart';

void main() => runApp(const SmartProbePage());

class SmartProbePage extends StatelessWidget {
  const SmartProbePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Probe View',
      home: const SmartProbeView(), // 這裡使用主畫面 Page
      routes: {'/monitor': (context) => const DesktopMonitorView()},
    );
  }
}
