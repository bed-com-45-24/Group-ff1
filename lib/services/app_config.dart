class AppConfig {
  static const backendEnabled = bool.fromEnvironment(
    'MOVA_USE_BACKEND',
    defaultValue: true,
  );
}
