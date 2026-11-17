import { randomUUID } from 'node:crypto';
import type { EligibilityCategory } from '../identity/eligibility';

export interface SafetyActor { id: string; eligibility: EligibilityCategory; moderator?: boolean; }
export interface SafetyReport { id: string; reporterId: string; targetId: string; reason: string; status: 'open' | 'reviewed'; }

export class SafetyError extends Error {}

export class SafetyService {
  private readonly blocked = new Set<string>();
  private readonly reports = new Map<string, SafetyReport>();
  canDiscover(actor: SafetyActor, target: SafetyActor, authorizedRelationship: boolean): boolean {
    return !(actor.eligibility === 'adult' && target.eligibility === 'youth' && !authorizedRelationship) && !this.blocked.has(`${actor.id}:${target.id}`);
  }
  canMessage(actor: SafetyActor, target: SafetyActor, authorizedContext: boolean): boolean {
    if (this.blocked.has(`${actor.id}:${target.id}`)) return false;
    return !(actor.eligibility === 'adult' && target.eligibility === 'youth' && !authorizedContext);
  }
  block(actorId: string, targetId: string): void { this.blocked.add(`${actorId}:${targetId}`); }
  report(actorId: string, targetId: string, reason: string): SafetyReport { const report = { id: randomUUID(), reporterId: actorId, targetId, reason, status: 'open' as const }; this.reports.set(report.id, report); return report; }
  review(actor: SafetyActor, reportId: string): SafetyReport { if (!actor.moderator) throw new SafetyError('Moderator role is required'); const report = this.reports.get(reportId); if (!report) throw new SafetyError('Report not found'); report.status = 'reviewed'; return report; }
}
