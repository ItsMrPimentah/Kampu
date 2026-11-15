import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/community/community_repository.dart';
import '../shared/external/http/api_client.dart';
import 'auth/auth_repository.dart';
import 'auth/session_controller.dart';

/// Owns the authentication service and its HTTP client.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = createApiClient();
  ref.onDispose(dio.close);
  return AuthRepository(dio: dio, storage: const FlutterSecureStorage());
});

/// Owns the app-wide session and its authentication actions.
final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionState>(
      (ref) => SessionController(ref.watch(authRepositoryProvider)),
    );

/// Owns the community API client while reading the current session on each call.
final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final session = ref.watch(sessionControllerProvider.notifier);
  final dio = createApiClient();
  ref.onDispose(dio.close);
  return DioCommunityRepository(dio: dio, token: () => session.sessionToken);
});
