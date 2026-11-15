import 'package:showtime_mobile/core/community/community_repository.dart';
import 'package:showtime_mobile/shared/external/utils/result.dart';

/// Stateful community fake for widget tests.
class CommunityFake implements CommunityRepository {
  final List<String> calls = [];
  String status = 'pending';
  bool failList = false;
  bool failPost = false;
  @override
  Future<CommunityResult<List<CommunityJson>>> list(String path) async {
    calls.add('GET $path');
    if (failList) return const Result.err(CommunityFailure.unavailable);
    if (path == 'games') return Result.val([game]);
    if (path == 'teams') {
      return const Result.val([
        {
          'id': 'opponent',
          'my_role': 'captain',
          'supported_formats': ['7v7'],
          'name': 'Visitors',
        },
      ]);
    }
    if (path == 'games/game-1/applications') {
      return Result.val([
        {'id': 'a1', 'display_name': 'First', 'status': 'waitlisted'},
        {'id': 'a2', 'display_name': 'Second', 'status': status},
      ]);
    }
    return const Result.val([]);
  }

  Map<String, dynamic> get game => {
    'id': 'game-1',
    'title': 'Friday Football',
    'format': '7v7',
    'region': 'Lisbon',
    'location': 'Pitch',
    'scheduled_at': '2030-01-01T18:00:00Z',
    'approved_count': 0,
    'capacity': 14,
    'approval_required': true,
    'my_status': null,
    'is_organizer': true,
    'required_positions': [],
    'status': 'open',
  };
  @override
  Future<CommunityResult<CommunityJson>> get(String path) async {
    if (path.startsWith('challenges/')) {
      return const Result.val({
        'match': {
          'id': 'challenge-1',
          'host_team_id': 'host',
          'opponent_team_id': null,
          'host_name': 'Home',
          'format': '7v7',
          'region': 'Lisbon',
          'status': 'open',
          'field_status': 'in_confirmation',
        },
        'proposals': [
          {
            'proposed_by_team_id': 'host',
            'version': 1,
            'terms': <String, dynamic>{},
          },
        ],
        'votes': <CommunityJson>[],
      });
    }
    return Result.val(game);
  }

  @override
  Future<CommunityResult<CommunityJson>> post(
    String path, [
    Map<String, dynamic> body = const {},
  ]) async {
    calls.add('POST $path');
    if (failPost) return const Result.err(CommunityFailure.unavailable);
    if (path.endsWith('/a2/approve')) status = 'approved';
    return const Result.val({});
  }

  @override
  Future<CommunityResult<CommunityJson>> patch(
    String path,
    CommunityJson body,
  ) async => const Result.val({});
}
