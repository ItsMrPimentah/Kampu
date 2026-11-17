import { Module } from '@nestjs/common';
import { AnalyticsModule } from './analytics.module';
import { OperatorMetricsService } from './operator-metrics.service';

@Module({
  imports: [AnalyticsModule],
  providers: [OperatorMetricsService],
  exports: [OperatorMetricsService],
})
export class OperatorMetricsModule {}
