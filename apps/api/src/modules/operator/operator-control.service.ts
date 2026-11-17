import { randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import type { GlobalRole } from '../authz/policy';
import type { FeatureFlag } from '../../shared/feature-flags';

export interface OperatorActor {
  id: string;
  globalRoles?: readonly GlobalRole[];
}

export interface PilotVenueConfiguration {
  id: string;
  partner: string;
  region: 'Lisbon' | 'Setúbal';
  enabled: boolean;
  updatedBy: string;
  updatedAt: string;
}

export type ConnectorHealth = 'healthy' | 'degraded' | 'offline';
export interface ConnectorHealthRecord { partner: string; status: ConnectorHealth; checkedAt: string; updatedBy: string; }
export interface BookingException { id: string; bookingId: string; reason: string; status: 'open' | 'resolved'; updatedBy: string; updatedAt: string; }
export interface ModerationAction { id: string; caseId: string; decision: 'restricted' | 'removed' | 'restored'; updatedBy: string; updatedAt: string; }
export interface DisputeReview { id: string; disputeId: string; resolution: 'resolved_paid' | 'resolved_unpaid' | 'escalated'; updatedBy: string; updatedAt: string; }
export interface OperatorAuditEntry { id: string; action: string; actorId: string; targetId?: string; occurredAt: string; }

export class OperatorAuthorizationError extends Error {}

@Injectable()
export class OperatorControlService {
  private readonly venues = new Map<string, PilotVenueConfiguration>();
  private readonly flags = new Map<FeatureFlag, boolean>();
  private readonly health = new Map<string, ConnectorHealthRecord>();
  private readonly bookingExceptions = new Map<string, BookingException>();
  private readonly moderation = new Map<string, ModerationAction>();
  private readonly disputes = new Map<string, DisputeReview>();
  private readonly audit: OperatorAuditEntry[] = [];

  configureVenue(actor: OperatorActor, input: { partner: string; region: 'Lisbon' | 'Setúbal'; enabled: boolean }): PilotVenueConfiguration {
    this.requireRole(actor, 'operator', 'venue.configure');
    if (!input.partner.trim()) throw new Error('Venue partner is required');
    const venue: PilotVenueConfiguration = { id: randomUUID(), ...input, partner: input.partner.trim(), updatedBy: actor.id, updatedAt: new Date().toISOString() };
    this.venues.set(`${input.partner}:${input.region}`, venue);
    this.record('venue.configure', actor, venue.id);
    return venue;
  }

  setFeatureFlag(actor: OperatorActor, flag: FeatureFlag, enabled: boolean): void {
    this.requireRole(actor, 'operator', 'feature-flag.update');
    this.flags.set(flag, enabled);
    this.record('feature-flag.update', actor, flag);
  }

  featureFlag(flag: FeatureFlag): boolean | undefined { return this.flags.get(flag); }

  setConnectorHealth(actor: OperatorActor, partner: string, status: ConnectorHealth): ConnectorHealthRecord {
    this.requireRole(actor, 'operator', 'connector.health');
    const record = { partner, status, checkedAt: new Date().toISOString(), updatedBy: actor.id };
    this.health.set(partner, record);
    this.record('connector.health', actor, partner);
    return record;
  }

  connectorHealth(partner: string): ConnectorHealthRecord | undefined { return this.health.get(partner); }

  recordBookingException(actor: OperatorActor, bookingId: string, reason: string): BookingException {
    this.requireRole(actor, 'operator', 'booking.exception');
    if (!bookingId || !reason.trim()) throw new Error('Booking and exception reason are required');
    const exception = { id: randomUUID(), bookingId, reason: reason.trim(), status: 'open' as const, updatedBy: actor.id, updatedAt: new Date().toISOString() };
    this.bookingExceptions.set(exception.id, exception);
    this.record('booking.exception', actor, exception.id);
    return exception;
  }

  resolveBookingException(actor: OperatorActor, exceptionId: string): BookingException {
    this.requireRole(actor, 'operator', 'booking.exception.resolve');
    const exception = this.bookingExceptions.get(exceptionId);
    if (!exception) throw new Error('Booking exception not found');
    exception.status = 'resolved';
    exception.updatedBy = actor.id;
    exception.updatedAt = new Date().toISOString();
    this.record('booking.exception.resolve', actor, exceptionId);
    return exception;
  }

  reviewModeration(actor: OperatorActor, caseId: string, decision: ModerationAction['decision']): ModerationAction {
    this.requireRole(actor, 'moderator', 'moderation.review');
    const action = { id: randomUUID(), caseId, decision, updatedBy: actor.id, updatedAt: new Date().toISOString() };
    this.moderation.set(caseId, action);
    this.record('moderation.review', actor, caseId);
    return action;
  }

  reviewDispute(actor: OperatorActor, disputeId: string, resolution: DisputeReview['resolution']): DisputeReview {
    this.requireRole(actor, 'support', 'dispute.review');
    const review = { id: randomUUID(), disputeId, resolution, updatedBy: actor.id, updatedAt: new Date().toISOString() };
    this.disputes.set(disputeId, review);
    this.record('dispute.review', actor, disputeId);
    return review;
  }

  auditEntries(actor: OperatorActor): OperatorAuditEntry[] {
    this.requireRole(actor, 'operator', 'audit.review');
    return [...this.audit];
  }

  venue(partner: string, region: 'Lisbon' | 'Setúbal'): PilotVenueConfiguration | undefined {
    return this.venues.get(`${partner}:${region}`);
  }

  private requireRole(actor: OperatorActor, required: GlobalRole, action: string): void {
    if (!actor.id || !(actor.globalRoles?.includes(required) || actor.globalRoles?.includes('operator'))) {
      throw new OperatorAuthorizationError(`${action} requires the ${required} role`);
    }
  }

  private record(action: string, actor: OperatorActor, targetId?: string): void {
    this.audit.push({ id: randomUUID(), action, actorId: actor.id, targetId, occurredAt: new Date().toISOString() });
  }
}
