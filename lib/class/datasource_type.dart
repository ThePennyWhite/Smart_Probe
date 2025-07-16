class DataSourceType {
  static const hid = DataSourceType._('hid');
  static const mouse = DataSourceType._('mouse');

  final String name;

  const DataSourceType._(this.name);

  static List<DataSourceType> get values => [hid, mouse];
}
