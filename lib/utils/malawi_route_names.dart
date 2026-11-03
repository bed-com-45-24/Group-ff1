String knownMalawiRouteName(String origin, String destination) {
  String normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

  final corridor = {normalize(origin), normalize(destination)};

  if (corridor.length == 2 &&
      corridor.contains(normalize('Lilongwe')) &&
      corridor.contains(normalize('Mchinji'))) {
    return 'M12';
  }
  if (corridor.length == 2 &&
      corridor.contains(normalize('Lilongwe')) &&
      corridor.contains(normalize('Blantyre'))) {
    return 'M1';
  }
  return '';
}
