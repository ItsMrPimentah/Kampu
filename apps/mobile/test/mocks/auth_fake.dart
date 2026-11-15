import 'package:mocktail/mocktail.dart';
import 'package:showtime_mobile/app/auth/auth_repository.dart';
import 'package:showtime_mobile/shared/external/utils/result.dart';

/// In-memory authentication boundary for end-to-end session flows.
class FakeAuthRepository extends Mock implements AuthRepository {
  /// Starts with an optional, already verified session.
  FakeAuthRepository({this.verified = false, this.token});

  bool verified;
  String? token;

  @override
  Future<Result<String?, AuthFailure>> readToken() async => Result.val(token);

  @override
  Future<AuthResult> saveToken(String token) async {
    this.token = token;
    return const Result.val(Ok());
  }

  @override
  Future<Result<Map<String, dynamic>, AuthFailure>> login(
    String identifier,
    String password,
  ) async {
    return Result.val({
      'token': 'token',
      'verified': verified,
      'phone': '+351912345678',
    });
  }

  @override
  Future<Result<Map<String, dynamic>, AuthFailure>> session(
    String token,
  ) async => Result.val({
    'verified': verified,
    'phone': '+351912345678',
    'user': {'id': 'user-1', 'name': 'Player', 'dateOfBirth': '2000-01-01'},
  });

  @override
  Future<AuthResult> verify(String token, String code) async {
    if (code != '123456') return const Result.err(AuthFailure.unauthorized);
    verified = true;
    return const Result.val(Ok());
  }

  @override
  Future<AuthResult> logout(String token) async => const Result.val(Ok());

  @override
  Future<AuthResult> clearToken() async {
    token = null;
    verified = false;
    return const Result.val(Ok());
  }
}
