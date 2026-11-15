import 'package:flutter/foundation.dart';

/// Build-time configuration supplied through Flutter's dart defines.
class AppEnvironment {
  /// Creates configuration with an explicitly supplied API endpoint.
  const AppEnvironment({
    required this.apiBaseUrl,
    required this.apiBaseUrlDefined,
  });

  /// Loads the configuration compiled into the application.
  const AppEnvironment.fromBuild()
    : apiBaseUrl = const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:3000',
      ),
      apiBaseUrlDefined = const bool.hasEnvironment('API_BASE_URL');

  /// The base URL used for API requests.
  final String apiBaseUrl;

  /// Whether the API endpoint was supplied as a dart define.
  final bool apiBaseUrlDefined;

  /// Reports configuration sources in debug builds without logging values.
  void logConfiguration(void Function(String) log) {
    if (kDebugMode) {
      log(
        '[Environment] API_BASE_URL: '
        '${apiBaseUrlDefined ? 'dart define' : 'default'}',
      );
    }
  }
}
