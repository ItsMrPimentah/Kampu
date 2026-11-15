import 'package:dio/dio.dart';

import '../../config/app_environment.dart';

/// Creates the configured HTTP client used by the mobile application.
Dio createApiClient({
  AppEnvironment environment = const AppEnvironment.fromBuild(),
}) => Dio(
  BaseOptions(
    baseUrl: environment.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ),
);
