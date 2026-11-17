import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_client.dart';

/// Owns the current authentication client and disposes it with the app scope.
final authClientProvider = Provider<AuthClient>((ref) {
  final client = AuthClient();
  ref.onDispose(client.dispose);
  return client;
});
