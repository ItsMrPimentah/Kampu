import 'local_models.dart';

/// Deterministic demo data. This module intentionally has no repository or HTTP dependency.
class LocalFixtures {
  const LocalFixtures._();

  static LocalPresentationData load() {
    final kickoff = DateTime(2026, 11, 7, 19, 30);
    final offerOne = OfferRevision(
      id: 'offer-001',
      createdAt: DateTime(2026, 11, 2, 10),
      author: 'Riverside FC',
      kickoff: kickoff,
      venue: 'Campo do Oriente',
      costPerTeam: 42,
      message: 'We can make Saturday work. Does the east pitch suit you?',
      changedTerms: const [],
    );
    final offerTwo = OfferRevision(
      id: 'offer-002',
      createdAt: DateTime(2026, 11, 2, 14),
      author: 'Alfama United',
      kickoff: kickoff.add(const Duration(minutes: 30)),
      venue: 'Campo do Oriente',
      costPerTeam: 45,
      message: 'Counter offer: a 20:00 kickoff gives both teams more time.',
      changedTerms: const ['Kickoff · 20:00', 'Cost · €45 per team'],
    );

    return LocalPresentationData(
      homeContext: const HomePreviewContext(
        displayName: 'Alex Morgan',
        initials: 'AM',
        avatarAsset: 'assets/images/placeholder.png',
        activeTeam: 'Showtime FC',
        preferredFormat: FootballFormat.fiveAside,
        locationLabel: 'Lisbon · Area 01',
        eligibilityLabel: 'Adult account · verified',
        unreadNotifications: 3,
      ),
      snapshot: LocalSnapshotMetadata(
        label: 'LOCAL PREVIEW · CACHED',
        capturedAt: DateTime(2026, 11, 2, 9),
        isOffline: true,
      ),
      fixture: UpcomingFixture(
        id: 'fixture-001',
        homeTeam: 'Showtime FC',
        awayTeam: 'Riverside FC',
        kickoff: kickoff,
        venue: 'Campo do Oriente',
        format: FootballFormat.fiveAside,
      ),
      challenges: [
        TeamChallenge(
          id: 'challenge-001',
          opponent: 'Alfama United',
          homeTeam: 'Showtime FC',
          status: ChallengeAction.countered,
          revisions: [offerOne, offerTwo],
        ),
        TeamChallenge(
          id: 'challenge-002',
          opponent: 'Northside Athletic',
          homeTeam: 'Showtime FC',
          status: ChallengeAction.pending,
          revisions: [offerOne],
        ),
      ],
      openGames: [
        OpenGame(
          id: 'open-game-001',
          title: 'Friday night kickabout',
          venue: 'Parque das Nações',
          kickoff: DateTime(2026, 11, 6, 20),
          format: FootballFormat.fiveAside,
          approvedPlayers: 3,
          playerCapacity: 5,
        ),
        OpenGame(
          id: 'open-game-002',
          title: 'Sunday futsal run',
          venue: 'Pavilhão Azul',
          kickoff: DateTime(2026, 11, 8, 11),
          format: FootballFormat.futsal,
          approvedPlayers: 8,
          playerCapacity: 10,
        ),
        OpenGame(
          id: 'open-game-003',
          title: 'Wednesday league warm-up',
          venue: 'Estádio Municipal',
          kickoff: DateTime(2026, 11, 11, 21),
          format: FootballFormat.sevenAside,
          approvedPlayers: 7,
          playerCapacity: 7,
        ),
      ],
      venues: [
        PitchVenue(
          id: 'venue-001',
          name: 'Campo do Oriente',
          address: 'Avenida do Índico',
          distanceKm: 1.8,
          format: FootballFormat.fiveAside,
          surface: SurfaceType.artificial,
          source: VenueSource.native,
          imageAsset: 'assets/images/placeholder.png',
          slots: [
            PitchSlot(
              id: 'slot-001',
              startsAt: DateTime(2026, 11, 7, 18),
              endsAt: DateTime(2026, 11, 7, 19),
              price: 40,
              state: SlotState.available,
            ),
            PitchSlot(
              id: 'slot-002',
              startsAt: DateTime(2026, 11, 7, 20),
              endsAt: DateTime(2026, 11, 7, 21),
              price: 45,
              state: SlotState.pending,
            ),
          ],
        ),
        PitchVenue(
          id: 'venue-002',
          name: 'Riverside Sports',
          address: 'Rua da Junqueira',
          distanceKm: 4.2,
          format: FootballFormat.sevenAside,
          surface: SurfaceType.natural,
          source: VenueSource.external,
          imageAsset: 'assets/images/placeholder.png',
          slots: [
            PitchSlot(
              id: 'slot-003',
              startsAt: DateTime(2026, 11, 7, 19),
              endsAt: DateTime(2026, 11, 7, 20),
              price: 60,
              state: SlotState.external,
            ),
          ],
        ),
        PitchVenue(
          id: 'venue-003',
          name: 'Alvalade Indoor',
          address: 'Rua do Campo Grande',
          distanceKm: 7.5,
          format: FootballFormat.futsal,
          surface: SurfaceType.indoor,
          source: VenueSource.native,
          imageAsset: 'assets/images/placeholder.png',
          slots: [
            PitchSlot(
              id: 'slot-004',
              startsAt: DateTime(2026, 11, 8, 11),
              endsAt: DateTime(2026, 11, 8, 12),
              price: 55,
              state: SlotState.soldOut,
            ),
          ],
        ),
      ],
      lastSyncedAt: DateTime(2026, 11, 2, 9),
    );
  }
}

/// A tiny adapter makes fixture ownership explicit and keeps screens backend-free.
class LocalPresentationRepository {
  LocalPresentationRepository() : _data = LocalFixtures.load();

  final LocalPresentationData _data;

  LocalPresentationData get snapshot => _data;
}
