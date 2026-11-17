import { SetMetadata } from '@nestjs/common';
import type { PolicyAction } from './policy';

export const POLICY_ACTION = 'showtime:policy-action';
export const RequirePolicy = (action: PolicyAction) => SetMetadata(POLICY_ACTION, action);
