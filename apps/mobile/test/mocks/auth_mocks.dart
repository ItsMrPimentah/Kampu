import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:showtime_mobile/app/auth/auth_repository.dart';

/// Mock authentication boundary shared by session-state tests.
class MockAuthRepository extends Mock implements AuthRepository {}

/// Mock HTTP boundary for authentication repository tests.
class MockDio extends Mock implements Dio {}

/// Mock secure storage boundary for authentication repository tests.
class MockSecureStorage extends Mock implements FlutterSecureStorage {}
