import { Module } from '@nestjs/common';
import { OperatorControlService } from './operator-control.service';

@Module({
  providers: [OperatorControlService],
  exports: [OperatorControlService],
})
export class OperatorModule {}
