import 'package:flutter/foundation.dart';

enum FootballFormat { fiveAside, sevenAside, elevenAside, futsal }

enum SurfaceType { artificial, natural, indoor }

enum VenueSource { native, external }

enum SlotState { available, pending, confirmed, external, soldOut }

enum ChallengeAction { pending, accepted, declined, countered }

@immutable
class UpcomingFixture {
  const UpcomingFixture({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.kickoff,
    required this.venue,
    required this.format,
  });

  final String id;
  final String homeTeam;
  final String awayTeam;
  final DateTime kickoff;
  final String venue;
  final FootballFormat format;
}

@immutable
class OpenGame {
  const OpenGame({
    required this.id,
    required this.title,
    required this.venue,
    required this.kickoff,
    required this.format,
    required this.approvedPlayers,
    required this.playerCapacity,
  });

  final String id;
  final String title;
  final String venue;
  final DateTime kickoff;
  final FootballFormat format;
  final int approvedPlayers;
  final int playerCapacity;

  OpenGame copyWith({int? approvedPlayers}) => OpenGame(
    id: id,
    title: title,
    venue: venue,
    kickoff: kickoff,
    format: format,
    approvedPlayers: approvedPlayers ?? this.approvedPlayers,
    playerCapacity: playerCapacity,
  );
}

@immutable
class OfferRevision {
  const OfferRevision({
    required this.id,
    required this.createdAt,
    required this.author,
    required this.kickoff,
    required this.venue,
    required this.costPerTeam,
    required this.message,
    required this.changedTerms,
  });

  final String id;
  final DateTime createdAt;
  final String author;
  final DateTime kickoff;
  final String venue;
  final int costPerTeam;
  final String message;
  final List<String> changedTerms;
}

@immutable
class TeamChallenge {
  const TeamChallenge({
    required this.id,
    required this.opponent,
    required this.homeTeam,
    required this.status,
    required this.revisions,
  });

  final String id;
  final String opponent;
  final String homeTeam;
  final ChallengeAction status;
  final List<OfferRevision> revisions;

  OfferRevision get latestOffer => revisions.last;

  TeamChallenge copyWith({
    ChallengeAction? status,
    List<OfferRevision>? revisions,
  }) => TeamChallenge(
    id: id,
    opponent: opponent,
    homeTeam: homeTeam,
    status: status ?? this.status,
    revisions: revisions ?? this.revisions,
  );
}

@immutable
class PitchSlot {
  const PitchSlot({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.price,
    required this.state,
  });

  final String id;
  final DateTime startsAt;
  final DateTime endsAt;
  final int price;
  final SlotState state;

  PitchSlot copyWith({SlotState? state}) => PitchSlot(
    id: id,
    startsAt: startsAt,
    endsAt: endsAt,
    price: price,
    state: state ?? this.state,
  );
}

@immutable
class PitchVenue {
  const PitchVenue({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.format,
    required this.surface,
    required this.source,
    required this.slots,
    required this.imageAsset,
  });

  final String id;
  final String name;
  final String address;
  final double distanceKm;
  final FootballFormat format;
  final SurfaceType surface;
  final VenueSource source;
  final List<PitchSlot> slots;
  final String imageAsset;

  bool get isSoldOut => slots.every((slot) => slot.state == SlotState.soldOut);

  PitchVenue copyWith({List<PitchSlot>? slots}) => PitchVenue(
    id: id,
    name: name,
    address: address,
    distanceKm: distanceKm,
    format: format,
    surface: surface,
    source: source,
    slots: slots ?? this.slots,
    imageAsset: imageAsset,
  );
}

@immutable
class HomePreviewContext {
  const HomePreviewContext({
    required this.displayName,
    required this.initials,
    required this.avatarAsset,
    required this.activeTeam,
    required this.preferredFormat,
    required this.locationLabel,
    required this.eligibilityLabel,
    required this.unreadNotifications,
  });

  final String displayName;
  final String initials;
  final String? avatarAsset;
  final String activeTeam;
  final FootballFormat preferredFormat;
  final String locationLabel;
  final String eligibilityLabel;
  final int unreadNotifications;
}

@immutable
class LocalSnapshotMetadata {
  const LocalSnapshotMetadata({
    required this.label,
    required this.capturedAt,
    required this.isOffline,
  });

  final String label;
  final DateTime capturedAt;
  final bool isOffline;
}

@immutable
class LocalPresentationData {
  const LocalPresentationData({
    required this.homeContext,
    required this.snapshot,
    required this.fixture,
    required this.challenges,
    required this.openGames,
    required this.venues,
    required this.lastSyncedAt,
  });

  final HomePreviewContext homeContext;
  final LocalSnapshotMetadata snapshot;
  final UpcomingFixture fixture;
  final List<TeamChallenge> challenges;
  final List<OpenGame> openGames;
  final List<PitchVenue> venues;
  final DateTime lastSyncedAt;
}

String formatName(FootballFormat value) => switch (value) {
  FootballFormat.fiveAside => '5v5',
  FootballFormat.sevenAside => '7v7',
  FootballFormat.elevenAside => '11v11',
  FootballFormat.futsal => 'Futsal',
};

String surfaceName(SurfaceType value) => switch (value) {
  SurfaceType.artificial => 'Artificial',
  SurfaceType.natural => 'Natural grass',
  SurfaceType.indoor => 'Indoor',
};
