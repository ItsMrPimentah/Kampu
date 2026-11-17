import { Module } from '@nestjs/common';
import { AdvertisingPolicyService } from './advertising.service';

@Module({
  providers: [AdvertisingPolicyService],
  exports: [AdvertisingPolicyService],
})
export class AdvertisingModule {}
