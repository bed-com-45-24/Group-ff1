String knownMalawiRouteName(String origin, String destination) {
  String normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

  final corridor = {normalize(origin), normalize(destination)};

  if (corridor.length == 2 &&
      corridor.contains(normalize('Lilongwe')) &&
      corridor.contains(normalize('Mchinji'))) {
    return 'M12';
  }
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
