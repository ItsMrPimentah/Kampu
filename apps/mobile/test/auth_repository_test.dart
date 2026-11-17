import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:showtime_mobile/core/auth/auth_repository.dart';

import 'mocks/auth_mocks.dart';

void main() {
  late MockDio dio;
  late MockSecureStorage storage;
  late AuthRepository repository;

  setUp(() {
    dio = MockDio();
    storage = MockSecureStorage();
    repository = AuthRepository(dio: dio, storage: storage);
  });
  tearDown(() {
    reset(dio);
    reset(storage);
  });

  test('persists a valid login response before returning success', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        data: {'token': 'token', 'verified': false, 'phone': 'test'},
      ),
    );
    when(() => storage.write(key: 'showtime_session', value: 'token'))
        .thenAnswer((_) async {});

    final result = await repository.login('name', 'password');

    expect(
      result.when(val: (data) => data['token'], err: (_) => null),
      'token',
    );
    verify(() => storage.write(key: 'showtime_session', value: 'token'))
        .called(1);
  });

  test('rejects malformed login responses without storing the token', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        data: {'token': 'token', 'verified': 'yes'},
      ),
    );

    final result = await repository.login('name', 'password');

    expect(
      result.when(val: (_) => null, err: (error) => error),
      AuthFailure.invalidResponse,
    );
    verifyNever(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    );
  });

  test('converts an unauthorized HTTP response to a failure', () async {
    final request = RequestOptions(path: '/auth/login');
    when(
      () => dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: any(named: 'data'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: 401),
      ),
    );

    final result = await repository.login('name', 'password');

    expect(
      result.when(val: (_) => null, err: (error) => error),
      AuthFailure.unauthorized,
    );
  });

  test('converts secure storage errors into failures', () async {
    when(() => storage.read(key: 'showtime_session'))
        .thenThrow(PlatformException(code: 'unavailable'));

    final result = await repository.readToken();

    expect(
      result.when(val: (_) => null, err: (error) => error),
      AuthFailure.unavailable,
    );
  });
}
