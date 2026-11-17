import { Module } from '@nestjs/common';
import { VenueService } from './venue.service';
import { BookingStateService } from './booking-state.service';
import { FakeBookingConnector } from './fake-connector';
import { ExternalBookingService } from './external-booking.service';
import { PlayArenaConnector } from './playarena-connector';
import { BookingService } from './booking.service';
@Module({
  providers: [VenueService, BookingStateService, FakeBookingConnector, ExternalBookingService, PlayArenaConnector, BookingService],
  exports: [VenueService, BookingStateService, FakeBookingConnector, ExternalBookingService, PlayArenaConnector, BookingService],
})
export class VenuesModule {}
