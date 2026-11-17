import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { HealthController } from './health.controller';
import { loadConfig } from './config/env';
import { IdentityController } from './modules/identity/identity.controller';
import { AuthController } from './modules/identity/auth.controller';
import { AuthService } from './modules/identity/auth.service';
import { CommunityController } from './modules/community/community.controller';
import { CommunityService } from './modules/community/community.service';
import { PolicyGuard } from './modules/authz/policy.guard';
import { AuditModule } from './modules/audit/audit.module';
import { PlayersModule } from './modules/players/players.module';
import { TeamsModule } from './modules/teams/teams.module';
import { MatchesModule } from './modules/matches/matches.module';
import { VenuesModule } from './modules/venues/venues.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { AdvertisingModule } from './modules/advertising/advertising.module';
import { AnalyticsModule } from './modules/analytics/analytics.module';
import { OperatorMetricsModule } from './modules/analytics/operator-metrics.module';
import { OperatorModule } from './modules/operator/operator.module';

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true, cache: true, validate: loadConfig }), AuditModule, PlayersModule, TeamsModule, MatchesModule, VenuesModule, PaymentsModule, NotificationsModule, AdvertisingModule, AnalyticsModule, OperatorMetricsModule, OperatorModule],
  controllers: [HealthController, IdentityController, AuthController, CommunityController],
  providers: [PolicyGuard, AuthService, CommunityService],
})
export class AppModule {}
