import { randomUUID } from 'node:crypto';
import { validateChallengeFormat, type ChallengeFormat } from './match-formats';

export type ChallengeStatus = 'draft' | 'open' | 'negotiation' | 'agreed' | 'scheduling' | 'confirmed' | 'completed' | 'cancelled' | 'expired';

export interface Challenge {
  id: string;
  hostTeamId: string;
  opponentTeamId?: string;
  format: ChallengeFormat;
  status: ChallengeStatus;
  skillLevel?: string;
  region?: string;
  scheduledAt?: string;
  paymentConditions: Record<string, unknown>;
  version: number;
  completedAt?: string;
}

const transitions: Record<ChallengeStatus, ChallengeStatus[]> = {
  draft: ['open', 'cancelled'],
  open: ['negotiation', 'agreed', 'cancelled', 'expired'],
  negotiation: ['agreed', 'cancelled', 'expired'],
  agreed: ['scheduling', 'negotiation', 'cancelled', 'expired'],
  scheduling: ['confirmed', 'negotiation', 'cancelled', 'expired'],
  confirmed: ['completed', 'cancelled'],
  completed: [],
  cancelled: [],
  expired: [],
};

export class ChallengeStateError extends Error {}

export class ChallengeService {
  private readonly challenges = new Map<string, Challenge>();

  create(input: { hostTeamId: string; format: string; skillLevel?: string; region?: string; paymentConditions?: Record<string, unknown> }): Challenge {
    if (!input.hostTeamId) throw new ChallengeStateError('Host team is required');
    const challenge: Challenge = {
      id: randomUUID(),
      hostTeamId: input.hostTeamId,
      format: validateChallengeFormat(input.format),
      status: 'draft',
      skillLevel: input.skillLevel,
      region: input.region,
      paymentConditions: input.paymentConditions ?? {},
      version: 1,
    };
    this.challenges.set(challenge.id, challenge);
    return challenge;
  }

  get(id: string): Challenge | undefined {
    return this.challenges.get(id);
  }

  transition(id: string, next: ChallengeStatus, expectedVersion: number): Challenge {
    const challenge = this.require(id);
    if (challenge.version !== expectedVersion) throw new ChallengeStateError('Challenge version conflict');
    if (!transitions[challenge.status].includes(next)) throw new ChallengeStateError(`Cannot transition challenge from ${challenge.status} to ${next}`);
    challenge.status = next;
    challenge.version += 1;
    if (next === 'completed') challenge.completedAt = new Date().toISOString();
    return challenge;
  }

  setSchedule(id: string, scheduledAt: string, expectedVersion: number): Challenge {
    const challenge = this.require(id);
    if (!Number.isFinite(Date.parse(scheduledAt))) throw new ChallengeStateError('Scheduled time is invalid');
    if (challenge.version !== expectedVersion) throw new ChallengeStateError('Challenge version conflict');
    if (!['agreed', 'scheduling'].includes(challenge.status)) throw new ChallengeStateError('Challenge must be agreed or scheduling before setting a schedule');
    challenge.scheduledAt = scheduledAt;
    challenge.status = 'scheduling';
    challenge.version += 1;
    return challenge;
  }

  private require(id: string): Challenge {
    const challenge = this.challenges.get(id);
    if (!challenge) throw new ChallengeStateError('Challenge not found');
    return challenge;
  }
}
