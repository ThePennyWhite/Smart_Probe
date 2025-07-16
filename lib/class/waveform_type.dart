class WaveformType {
  final String name;
  const WaveformType._(this.name);

  static const sine = WaveformType._('sine');
  static const triangle = WaveformType._('triangle');
  static const noise = WaveformType._('noise');

  static const values = [sine, triangle, noise];

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) => other is WaveformType && other.name == name;

  @override
  int get hashCode => name.hashCode;
}
