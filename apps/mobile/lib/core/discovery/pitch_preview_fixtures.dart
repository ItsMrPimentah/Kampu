import 'local_fixtures.dart';
import 'local_models.dart';

/// Illustrative details for the pitch preview, not verified venue information.
class PitchPreviewDetails {
  const PitchPreviewDetails({
    required this.pitch,
    required this.amenities,
    this.sampleImageAsset,
  });

  final String pitch;
  final List<String> amenities;

  /// Illustrative local image, not a photograph of the named venue.
  final String? sampleImageAsset;
}

/// Sample-only metadata, isolated from the shared venue model.
const pitchPreviewDetails = <String, PitchPreviewDetails>{
  'venue-001': PitchPreviewDetails(
    pitch: 'Pitch 4',
    amenities: ['Floodlights', 'Changing rooms', 'Parking', 'Turf boots'],
    sampleImageAsset: 'assets/images/sample_pitch_floodlit_turf.png',
  ),
  'venue-002': PitchPreviewDetails(
    pitch: 'Field A',
    amenities: ['Showers and lockers', 'Grass pitch'],
    sampleImageAsset: 'assets/images/sample_pitch_stadium_grass.png',
  ),
  'venue-003': PitchPreviewDetails(
    pitch: 'Court B',
    amenities: ['Indoor court', 'Non-marking shoes'],
    sampleImageAsset: 'assets/images/sample_pitch_indoor_court.png',
  ),
  'pitch-venue-004': PitchPreviewDetails(
    pitch: 'Pitch 1',
    amenities: ['Grass pitch', 'Changing rooms'],
    sampleImageAsset: 'assets/images/sample_pitch_stadium_grass.png',
  ),
};

/// Pitch-only sample data; other preview screens retain their original fixtures.
List<PitchVenue> pitchPreviewFixtures() {
  final venues = LocalFixtures.load().venues;
  PitchSlot slot(String id, DateTime start, int price, SlotState state) =>
      PitchSlot(
        id: id,
        startsAt: start,
        endsAt: start.add(const Duration(hours: 1)),
        price: price,
        state: state,
      );

  return [
    venues[0].copyWith(
      slots: [
        ...venues[0].slots,
        slot(
          'pitch-005',
          DateTime(2026, 11, 7, 21, 30),
          65,
          SlotState.available,
        ),
        slot(
          'pitch-006',
          DateTime(2026, 12, 7, 18, 30),
          70,
          SlotState.available,
        ),
        slot(
          'pitch-007',
          DateTime(2027, 11, 7, 18, 30),
          80,
          SlotState.available,
        ),
      ],
    ),
    venues[1],
    venues[2],
    PitchVenue(
      id: 'pitch-venue-004',
      name: 'Parque Municipal',
      address: 'Avenida Central',
      distanceKm: 9,
      format: FootballFormat.elevenAside,
      surface: SurfaceType.natural,
      source: VenueSource.native,
      imageAsset: 'assets/images/placeholder.png',
      slots: [
        slot('pitch-008', DateTime(2026, 11, 8, 17), 90, SlotState.available),
      ],
    ),
  ];
}
