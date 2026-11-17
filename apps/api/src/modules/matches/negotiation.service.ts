import { randomUUID } from 'node:crypto';
import { validateChallengeFormat, type ChallengeFormat } from './match-formats';

export interface Proposal {
  version: number;
  proposedByTeamId: string;
  terms: Record<string, unknown>;
  decision: 'pending' | 'accepted' | 'rejected';
}

export interface Negotiation {
  id: string;
  hostTeamId: string;
  opponentTeamId?: string;
  format: ChallengeFormat;
  status: 'open' | 'negotiation' | 'agreed';
  version: number;
  proposals: Proposal[];
  approvals: string[];
}

export class NegotiationConflictError extends Error {}

export class NegotiationService {
  private readonly negotiations = new Map<string, Negotiation>();

  create(hostTeamId: string, format: string, terms: Record<string, unknown> = {}): Negotiation {
    const negotiation: Negotiation = {
      id: randomUUID(),
      hostTeamId,
      format: validateChallengeFormat(format),
      status: 'open',
      version: 1,
      proposals: [{ version: 1, proposedByTeamId: hostTeamId, terms, decision: 'pending' }],
      approvals: [],
    };
    this.negotiations.set(negotiation.id, negotiation);
    return negotiation;
  }

  selectOpponent(id: string, opponentTeamId: string, expectedVersion: number): Negotiation {
    const negotiation = this.require(id);
    this.checkVersion(negotiation, expectedVersion);
    if (opponentTeamId === negotiation.hostTeamId) throw new NegotiationConflictError('A team cannot challenge itself');
    if (negotiation.opponentTeamId && negotiation.opponentTeamId !== opponentTeamId) throw new NegotiationConflictError('Only one opposing team may be selected');
    negotiation.opponentTeamId = opponentTeamId;
    negotiation.status = 'negotiation';
    negotiation.version += 1;
    return negotiation;
  }

  counteroffer(id: string, teamId: string, terms: Record<string, unknown>, expectedVersion: number): Proposal {
    const negotiation = this.require(id);
    this.checkVersion(negotiation, expectedVersion);
    if (teamId !== negotiation.hostTeamId && teamId !== negotiation.opponentTeamId) throw new NegotiationConflictError('Team is not a negotiation participant');
    const proposal: Proposal = { version: negotiation.proposals.length + 1, proposedByTeamId: teamId, terms, decision: 'pending' };
    negotiation.proposals.forEach((item) => { if (item.decision === 'pending') item.decision = 'rejected'; });
    negotiation.proposals.push(proposal);
    negotiation.approvals = [];
    negotiation.status = 'negotiation';
    negotiation.version += 1;
    return proposal;
  }

  approve(id: string, teamId: string, proposalVersion: number, expectedVersion: number): Negotiation {
    const negotiation = this.require(id);
    this.checkVersion(negotiation, expectedVersion);
    if (!negotiation.opponentTeamId || ![negotiation.hostTeamId, negotiation.opponentTeamId].includes(teamId)) throw new NegotiationConflictError('Team is not a negotiation participant');
    const proposal = negotiation.proposals.find((item) => item.version === proposalVersion);
    if (!proposal) throw new NegotiationConflictError('Proposal version not found');
    if (!negotiation.approvals.includes(teamId)) negotiation.approvals.push(teamId);
    proposal.decision = 'accepted';
    if (negotiation.approvals.includes(negotiation.hostTeamId) && negotiation.approvals.includes(negotiation.opponentTeamId)) negotiation.status = 'agreed';
    negotiation.version += 1;
    return negotiation;
  }

  get(id: string): Negotiation | undefined { return this.negotiations.get(id); }

  private require(id: string): Negotiation {
    const value = this.negotiations.get(id);
    if (!value) throw new NegotiationConflictError('Negotiation not found');
    return value;
  }

  private checkVersion(value: Negotiation, expectedVersion: number): void {
    if (value.version !== expectedVersion) throw new NegotiationConflictError('Negotiation version conflict');
  }
}
