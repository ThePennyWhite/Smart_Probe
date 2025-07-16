class WaveformType {
  final String name;
  const WaveformType._(this.name);

  static const sine = WaveformType._('sine');
  static const square = WaveformType._('square');
  static const triangle = WaveformType._('triangle');
  static const noise = WaveformType._('noise');
  static const fake = WaveformType._('fake');

  static const values = [sine, square, triangle, noise, fake];

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) => other is WaveformType && other.name == name;

  @override
  int get hashCode => name.hashCode;
}
