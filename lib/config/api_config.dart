/// Backend URL for builds that must work on any network (Wi‑Fi, mobile data).
///
/// Set at build time:
/// ```bash
/// flutter run --dart-define=API_BASE_URL=https://your-api.example.com
/// flutter build apk --dart-define=API_BASE_URL=https://your-api.example.com
/// ```
///
/// Leave empty for local development (USB reverse / emulator / same Wi‑Fi).
class ApiConfig {
  static const String productionBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static bool get hasProductionUrl => productionBaseUrl.trim().isNotEmpty;

  /// SharedPreferences key for an optional in-app override (Settings screen).
  static const String customBackendUrlKey = 'custom_backend_url';
}
