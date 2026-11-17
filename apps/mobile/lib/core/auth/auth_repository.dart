import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../shared/external/utils/result.dart';
import '../registration/registration_models.dart';

/// A failure at an authentication service or secure-storage boundary.
enum AuthFailure { unauthorized, unavailable, invalidResponse }

/// Result of an authentication request without a response value.
typedef AuthResult = Result<Ok, AuthFailure>;

/// Handles authentication requests and secure session token storage.
class AuthRepository {
  /// Creates a repository with explicitly injected platform dependencies.
  AuthRepository({required this.dio, required this.storage});

  /// HTTP client used for authentication calls.
  final Dio dio;

  /// Platform-backed session token storage.
  final FlutterSecureStorage storage;
  static const _tokenKey = 'showtime_session';

  /// Reads the stored token, if any.
  Future<Result<String?, AuthFailure>> readToken() async {
    try {
      return Result.val(await storage.read(key: _tokenKey));
    } on PlatformException {
      return const Result.err(AuthFailure.unavailable);
    }
  }

  /// Removes the stored token.
  Future<AuthResult> clearToken() async {
    try {
      await storage.delete(key: _tokenKey);
      return const Result.val(Ok());
    } on PlatformException {
      return const Result.err(AuthFailure.unavailable);
    }
  }

  /// Requests a new session and persists its token.
  Future<Result<Map<String, dynamic>, AuthFailure>> login(
    String identifier,
    String password,
  ) => _authenticate('/auth/login', {
    'identifier': identifier,
    'password': password,
  }, requireSent: false);

  /// Registers a user and persists the resulting session token.
  Future<Result<Map<String, dynamic>, AuthFailure>> register(
    RegistrationSubmission input,
  ) => _authenticate('/auth/register', {
    'name': input.fullName,
    'email': input.email,
    'phone': input.phone.replaceAll(RegExp(r'[\s()-]'), ''),
    'password': input.password,
    'dateOfBirth': input.dateOfBirth,
    'role': input.role.name,
    'acceptedTerms': true,
  }, requireSent: true);

  Future<Result<Map<String, dynamic>, AuthFailure>> _authenticate(
    String path,
    Map<String, dynamic> body, {
    required bool requireSent,
  }) async {
    final response = await _request(
      () => dio.post<Map<String, dynamic>>(path, data: body),
    );
    return response.when(
      val: (data) async {
        final token = data['token'];
        if (token is! String ||
            token.isEmpty ||
            data['verified'] is! bool ||
            (data['phone'] != null && data['phone'] is! String) ||
            (requireSent && data['sent'] is! bool)) {
          return const Result.err(AuthFailure.invalidResponse);
        }
        try {
          await storage.write(key: _tokenKey, value: token);
          return Result.val(data);
        } on PlatformException {
          return const Result.err(AuthFailure.unavailable);
        }
      },
      err: (error) async => Result.err(error),
    );
  }

  /// Retrieves the server's current session for [token].
  Future<Result<Map<String, dynamic>, AuthFailure>> session(String token) =>
      _request(
        () => dio.get<Map<String, dynamic>>(
          '/auth/session',
          options: _headers(token),
        ),
      );

  /// Requests another verification SMS.
  Future<AuthResult> resend(String token) => _post('/auth/phone/resend', token);

  /// Submits a phone verification code.
  Future<AuthResult> verify(String token, String code) =>
      _post('/auth/phone/verify', token, data: {'code': code});

  /// Invalidates the server session.
  Future<AuthResult> logout(String token) => _post('/auth/logout', token);

  Future<AuthResult> _post(
    String path,
    String token, {
    Map<String, dynamic>? data,
  }) async {
    try {
      await dio.post<void>(path, data: data, options: _headers(token));
      return const Result.val(Ok());
    } on DioException catch (error) {
      return Result.err(_failure(error));
    }
  }

  Future<Result<Map<String, dynamic>, AuthFailure>> _request(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final data = (await request()).data;
      return data == null
          ? const Result.err(AuthFailure.invalidResponse)
          : Result.val(data);
    } on DioException catch (error) {
      return Result.err(_failure(error));
    }
  }

  Options _headers(String token) =>
      Options(headers: {'Authorization': 'Bearer $token'});

  AuthFailure _failure(DioException error) => error.response?.statusCode == 401
      ? AuthFailure.unauthorized
      : AuthFailure.unavailable;
}
