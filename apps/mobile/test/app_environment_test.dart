import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtime_mobile/shared/config/app_environment.dart';
import 'package:showtime_mobile/shared/external/http/api_client.dart';

void main() {
  test('loads the API URL and source from build-time defines', () {
    const environment = AppEnvironment.fromBuild();

    expect(
      environment.apiBaseUrl,
      const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:3000',
      ),
    );
    expect(
      environment.apiBaseUrlDefined,
      const bool.hasEnvironment('API_BASE_URL'),
    );
    final client = createApiClient();
    expect(client.options.baseUrl, environment.apiBaseUrl);
    client.close();
  });

  test('uses the injected environment for the HTTP client', () {
    const environment = AppEnvironment(
      apiBaseUrl: 'https://api.example.test',
      apiBaseUrlDefined: true,
    );
    final client = createApiClient(environment: environment);

    expect(client.options.baseUrl, 'https://api.example.test');
    client.close();
  });

  for (final defined in [false, true]) {
    test('logs only the configuration source when defined is $defined', () {
      const value = 'https://user:secret@example.test?token=private';
      final environment = AppEnvironment(
        apiBaseUrl: value,
        apiBaseUrlDefined: defined,
      );
      final messages = <String>[];

      environment.logConfiguration(messages.add);

      if (kDebugMode) {
        expect(messages, [
          '[Environment] API_BASE_URL: ${defined ? 'dart define' : 'default'}',
        ]);
        expect(messages.join(), isNot(contains('secret')));
        expect(messages.join(), isNot(contains('private')));
      } else {
        expect(messages, isEmpty);
      }
    });
  }
}
