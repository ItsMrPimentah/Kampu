import { BadRequestException, Body, Controller, Post } from '@nestjs/common';
import { EligibilityError, evaluateEligibility } from './eligibility';

interface EligibilityBody {
  dateOfBirth?: string;
}

@Controller('identity')
export class IdentityController {
  @Post('eligibility')
  establishEligibility(@Body() body: EligibilityBody) {
    try {
      return evaluateEligibility(body.dateOfBirth ?? '');
    } catch (error) {
      if (error instanceof EligibilityError) {
        throw new BadRequestException({ code: error.reason, message: error.message });
      }
      throw error;
    }
  }
}
