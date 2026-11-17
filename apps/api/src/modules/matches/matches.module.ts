import { Module } from '@nestjs/common';
import { ChallengeService } from './challenge.service';
import { NegotiationService } from './negotiation.service';
import { DiscoveryService } from './discovery.service';
import { OpenGameService } from './open-game.service';
import { FusionService } from './fusion.service';
import { AttendanceService } from './attendance.service';@Module({
  providers: [ChallengeService, NegotiationService, DiscoveryService, OpenGameService, FusionService, AttendanceService],
  exports: [ChallengeService, NegotiationService, DiscoveryService, OpenGameService, FusionService, AttendanceService],
})
export class MatchesModule {}
