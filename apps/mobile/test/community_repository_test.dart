import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showtime_mobile/core/community/community_repository.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.response, {this.status = 200});

  final Object? response;
  final int status;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(response),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('uses the current session token and parses community lists', () async {
    final adapter = _Adapter([
      {'id': 'game-1', 'title': 'Game', 'approved_count': 1, 'capacity': 14},
    ]);
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    var token = 'first';
    final repository = DioCommunityRepository(dio: dio, token: () => token);
    token = 'second';

    final result = await repository.list('games');

    expect(
      result.when(val: (items) => items.first['id'], err: (_) => null),
      'game-1',
    );
    expect(adapter.request?.headers['Authorization'], 'Bearer second');
    expect(adapter.request?.path, '/community/games');
    dio.close();
  });

  test('returns an unauthorized failure without a session', () async {
    final adapter = _Adapter({});
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    final repository = DioCommunityRepository(dio: dio, token: () => null);

    final result = await repository.get('games/game-1');

    expect(
      result.when(val: (_) => null, err: (error) => error),
      CommunityFailure.unauthorized,
    );
    expect(adapter.request, isNull);
    dio.close();
  });

  test('rejects malformed collections and reports HTTP failures', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.httpClientAdapter = _Adapter([42]);
    final repository = DioCommunityRepository(dio: dio, token: () => 'token');
    final malformed = await repository.list('games');
    expect(
      malformed.when(val: (_) => null, err: (error) => error),
      CommunityFailure.invalidResponse,
    );

    dio.httpClientAdapter = _Adapter({
      'title': 'Game',
      'capacity': 0,
      'approved_count': 0,
      'required_positions': [],
    });
    final malformedDetail = await repository.get('games/game-1');
    expect(
      malformedDetail.when(val: (_) => null, err: (error) => error),
      CommunityFailure.invalidResponse,
    );

    dio.httpClientAdapter = _Adapter({}, status: 401);
    final unauthorized = await repository.post('games');
    expect(
      unauthorized.when(val: (_) => null, err: (error) => error),
      CommunityFailure.unauthorized,
    );

    dio.httpClientAdapter = _Adapter({}, status: 500);
    final unavailable = await repository.get('games');
    expect(
      unavailable.when(val: (_) => null, err: (error) => error),
      CommunityFailure.unavailable,
    );
    dio.close();
  });

  test('encodes path segments and rejects traversal', () async {
    final adapter = _Adapter({'ok': true});
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    final repository = DioCommunityRepository(dio: dio, token: () => 'token');

    await repository.post('invites/code?other=true/accept');
    expect(
      adapter.request?.path,
      '/community/invites/code%3Fother%3Dtrue/accept',
    );
    final result = await repository.post('../auth/logout');
    expect(
      result.when(val: (_) => null, err: (error) => error),
      CommunityFailure.invalidResponse,
    );
    dio.close();
  });
}
