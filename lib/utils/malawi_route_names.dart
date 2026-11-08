String knownMalawiRouteName(String origin, String destination) {
  String normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

  String normalizePlace(String value) {
    final normalized = normalize(value);
    const aliases = {'brantyre': 'blantyre', 'blantyrecity': 'blantyre'};
    return aliases[normalized] ?? normalized;
  }

  final corridor = {normalizePlace(origin), normalizePlace(destination)};

  if (corridor.length == 2 &&
      corridor.contains(normalizePlace('Lilongwe')) &&
      corridor.contains(normalizePlace('Mchinji'))) {
    return 'M12';
  }

  if (corridor.length == 2 &&
      corridor.contains(normalizePlace('Lilongwe')) &&
      corridor.contains(normalizePlace('Blantyre'))) {
    return 'M1';
  }

  if (corridor.length == 2 &&
      corridor.contains(normalizePlace('Lilongwe')) &&
      (corridor.contains(normalizePlace('Mzuzu')) ||
          corridor.contains(normalizePlace('Mzimba/Mzuzu')))) {
    return 'M1';
  }
  return '';
}
