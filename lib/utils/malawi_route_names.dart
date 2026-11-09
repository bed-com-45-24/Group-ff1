String knownMalawiRouteName(String origin, String destination) {
  String normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

  final corridor = {normalize(origin), normalize(destination)};

  if (corridor.length == 2 &&
      corridor.contains(normalize('Lilongwe')) &&
      corridor.contains(normalize('Mchinji'))) {
    return 'M12';
  }

  const corridorNumbers = <String, String>{
    'blantyre-karonga': 'M1',
    'blantyrelilongwe': 'M1',
    'kasungulilongwe': 'M1',
    'kasungumzuzu': 'M1',
    'lilongwemzuzu': 'M1',
    'blantyremzuzu': 'M1',
    'lilongwemangochi': 'M5',
    'lilongwesalima': 'M5',
    'mangochisalima': 'M5',
    'mzuzuzomba': 'M5',
  };

  final orderedNames = corridor.toList()..sort();
  final corridorKey = orderedNames.length == 2 ? orderedNames.join() : '';
  final mappedNumber = corridorNumbers[corridorKey];
  if (mappedNumber != null) return mappedNumber;
  final normalizedBlantyre = normalize(destination) == normalize('Brantyre')
      ? normalize('Blantyre')
      : normalize(destination);
  final normalizedOrigin = normalize(origin);
  final normalizedPlaces = normalizedOrigin == normalize('Brantyre')
      ? normalize('Blantyre')
      : normalizedOrigin;

  if (corridor.length == 2 &&
      corridor.contains(normalize('Lilongwe')) &&
      corridor.contains(normalize('Blantyre'))) {
    return 'M1';
  }
  if ({normalizedPlaces, normalizedBlantyre}.length == 2 &&
      {normalizedPlaces, normalizedBlantyre}.contains(normalize('Lilongwe')) &&
      {normalizedPlaces, normalizedBlantyre}.contains(normalize('Blantyre'))) {
    return 'M1';
  }
  return '';
}
