import 'package:dio/dio.dart';

import '../../shared/external/utils/result.dart';

/// A JSON object returned by the community API.
typedef CommunityJson = Map<String, dynamic>;

/// An expected community API failure.
enum CommunityFailure { unauthorized, unavailable, invalidResponse }

/// Result of a community API operation.
typedef CommunityResult<T> = Result<T, CommunityFailure>;

/// Operations required by community screens.
abstract interface class CommunityRepository {
  /// Retrieves a collection of community objects.
  Future<CommunityResult<List<CommunityJson>>> list(String path);

  /// Retrieves a community object.
  Future<CommunityResult<CommunityJson>> get(String path);

  /// Submits an action and returns its response object.
  Future<CommunityResult<CommunityJson>> post(
    String path, [
    CommunityJson body = const {},
  ]);

  /// Updates a community object.
  Future<CommunityResult<CommunityJson>> patch(String path, CommunityJson body);
}

/// Community transport using a session token supplied at request time.
class DioCommunityRepository implements CommunityRepository {
  /// Creates a repository using injected HTTP and session dependencies.
  DioCommunityRepository({required this.dio, required this.token});

  /// HTTP client used for community requests.
  final Dio dio;

  /// Reads the current session token for each request.
  final String? Function() token;

  @override
  Future<CommunityResult<List<CommunityJson>>> list(String path) async {
    final response = await _request('GET', path);
    return response.when(
      val: (value) {
        if (value is! List ||
            value.any((item) => item is! Map<String, dynamic>)) {
          return const Result.err(CommunityFailure.invalidResponse);
        }
        if (value.cast<CommunityJson>().any(
          (item) => !_isValidListItem(path, item),
        )) {
          return const Result.err(CommunityFailure.invalidResponse);
        }
        return Result.val(value.cast<CommunityJson>());
      },
      err: Result.err,
    );
  }

  bool _isValidListItem(String path, CommunityJson item) {
    if (path == 'teams') {
      final formats = item['supported_formats'];
      return item['id'] is String &&
          item['name'] is String &&
          formats is List &&
          formats.every((format) => format is String);
    }
    if (path == 'games') {
      return item['id'] is String &&
          item['title'] is String &&
          item['approved_count'] is num &&
          item['capacity'] is num &&
          (item['capacity'] as num) > 0;
    }
    if (path == 'challenges') return item['id'] is String;
    if (path.endsWith('/requests') || path.endsWith('/applications')) {
      return item['id'] is String &&
          item['display_name'] is String &&
          item['status'] is String;
    }
    return true;
  }

  @override
  Future<CommunityResult<CommunityJson>> get(String path) =>
      _object('GET', path);

  @override
  Future<CommunityResult<CommunityJson>> post(
    String path, [
    CommunityJson body = const {},
  ]) => _object('POST', path, body);

  @override
  Future<CommunityResult<CommunityJson>> patch(
    String path,
    CommunityJson body,
  ) => _object('PATCH', path, body);

  Future<CommunityResult<CommunityJson>> _object(
    String method,
    String path, [
    CommunityJson? body,
  ]) async {
    final response = await _request(method, path, body);
    return response.when(
      val: (value) {
        if (value is! CommunityJson || !_isValidDetail(method, path, value)) {
          return const Result.err(CommunityFailure.invalidResponse);
        }
        return Result.val(value);
      },
      err: Result.err,
    );
  }

  bool _isValidDetail(String method, String path, CommunityJson value) {
    if (method != 'GET') return true;
    final parts = path.split('/');
    if (parts.length != 2) return true;
    if (parts[0] == 'teams') {
      final team = value['team'];
      final members = value['members'];
      return team is CommunityJson &&
          members is List &&
          members.every(
            (member) =>
                member is CommunityJson && member['display_name'] is String,
          ) &&
          team['supported_formats'] is List &&
          (team['supported_formats'] as List).every(
            (format) => format is String,
          ) &&
          team['name'] is String;
    }
    if (parts[0] == 'challenges') {
      final proposals = value['proposals'];
      final votes = value['votes'];
      return value['match'] is CommunityJson &&
          proposals is List &&
          votes is List &&
          proposals.every(
            (proposal) =>
                proposal is CommunityJson && proposal['terms'] is CommunityJson,
          ) &&
          votes.every((vote) => vote is CommunityJson);
    }
    if (parts[0] == 'games') {
      return value['title'] is String &&
          value['required_positions'] is List &&
          (value['required_positions'] as List).every(
            (position) => position is String,
          ) &&
          value['approved_count'] is num &&
          value['capacity'] is num &&
          (value['capacity'] as num) > 0;
    }
    return true;
  }

  Future<CommunityResult<Object?>> _request(
    String method,
    String path, [
    CommunityJson? body,
  ]) async {
    final sessionToken = token();
    if (sessionToken == null) {
      return const Result.err(CommunityFailure.unauthorized);
    }
    final segments = path.split('/');
    if (segments.any(
      (segment) => segment.isEmpty || segment == '.' || segment == '..',
    )) {
      return const Result.err(CommunityFailure.invalidResponse);
    }
    final safePath = segments.map(Uri.encodeComponent).join('/');
    try {
      final response = await dio.request<Object?>(
        '/community/$safePath',
        data: body,
        options: Options(
          method: method,
          headers: {'Authorization': 'Bearer $sessionToken'},
        ),
      );
      return Result.val(response.data);
    } on DioException catch (error) {
      return Result.err(
        error.response?.statusCode == 401
            ? CommunityFailure.unauthorized
            : CommunityFailure.unavailable,
      );
    }
  }
}
