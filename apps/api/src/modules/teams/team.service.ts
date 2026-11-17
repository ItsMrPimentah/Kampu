import { randomUUID } from 'node:crypto';
import type { EligibilityCategory } from '../identity/eligibility';
import type { TeamRole } from '../authz/policy';
import { calculateReadiness, type FootballFormat, type RosterReadiness } from './formats';
export interface TeamActor {
  userId: string;
  eligibility?: EligibilityCategory;
}

export interface Team {
  id: string;
  name: string;
  region: string;
  supportedFormats: string[];
}

export interface TeamMembership {
  teamId: string;
  userId: string;
  role: TeamRole;
  permissions: string[];
  active: boolean;
}

export interface TeamInvitation {
  id: string;
  teamId: string;
  invitedUserId: string;
  invitedByUserId: string;
  status: 'pending' | 'accepted' | 'declined' | 'cancelled';
}

export interface AuthorizationAuditEntry {
  action: string;
  actorId: string;
  teamId: string;
  allowed: false;
  reason: 'team_membership_required' | 'team_permission_required' | 'self_removal_forbidden';
  occurredAt: string;
}

export class TeamService {
  private readonly teams = new Map<string, Team>();
  private readonly memberships = new Map<string, TeamMembership>();
  private readonly invitations = new Map<string, TeamInvitation>();
  private readonly deniedActions: AuthorizationAuditEntry[] = [];

  authorizationFailures(): AuthorizationAuditEntry[] {
    return [...this.deniedActions];
  }

  create(actor: TeamActor, input: { name: string; region: string }): Team {
    if (!actor.eligibility) throw new Error('Eligibility is required to create a team');
    const team: Team = { id: randomUUID(), name: input.name.trim(), region: input.region.trim(), supportedFormats: [] };
    if (!team.name || !team.region) throw new Error('Team name and region are required');
    this.teams.set(team.id, team);
    this.memberships.set(this.key(team.id, actor.userId), { teamId: team.id, userId: actor.userId, role: 'captain', permissions: [], active: true });
    return team;
  }

  invite(actor: TeamActor, teamId: string, invitedUserId: string): TeamInvitation {
    this.requireManage(actor.userId, teamId, 'team.invite');
    if (!invitedUserId) throw new Error('Invited user is required');
    const invitation: TeamInvitation = { id: randomUUID(), teamId, invitedUserId, invitedByUserId: actor.userId, status: 'pending' };
    this.invitations.set(invitation.id, invitation);
    return invitation;
  }

  acceptInvitation(actor: TeamActor, invitationId: string): TeamMembership {
    if (!actor.eligibility) throw new Error('Eligibility is required to join a team');
    const invitation = this.invitations.get(invitationId);
    if (!invitation || invitation.status !== 'pending' || invitation.invitedUserId !== actor.userId) throw new Error('Invitation is not available');
    invitation.status = 'accepted';
    const membership: TeamMembership = { teamId: invitation.teamId, userId: actor.userId, role: 'member', permissions: [], active: true };
    this.memberships.set(this.key(invitation.teamId, actor.userId), membership);
    return membership;
  }

  removeMember(actor: TeamActor, teamId: string, memberId: string): void {
    this.requireManage(actor.userId, teamId, 'team.remove_member');
    if (actor.userId === memberId) {
      this.deniedActions.push({ action: 'team.remove_member', actorId: actor.userId, teamId, allowed: false, reason: 'self_removal_forbidden', occurredAt: new Date().toISOString() });
      throw new Error('Captain cannot remove itself');
    }
    const membership = this.memberships.get(this.key(teamId, memberId));
    if (!membership) throw new Error('Team membership not found');
    membership.active = false;
  }

  leave(actor: TeamActor, teamId: string): void {
    const membership = this.memberships.get(this.key(teamId, actor.userId));
    if (!membership || !membership.active) throw new Error('Team membership not found');
    if (membership.role === 'captain') throw new Error('Captain must transfer captaincy before leaving');
    membership.active = false;
  }

  membership(teamId: string, userId: string): TeamMembership | undefined {
    return this.memberships.get(this.key(teamId, userId));
  }

  membershipsFor(userId: string): TeamMembership[] {
    return [...this.memberships.values()].filter((membership) => membership.userId === userId && membership.active);
  }

  get(teamId: string): Team | undefined {
    return this.teams.get(teamId);
  }

  readiness(teamId: string, format: FootballFormat, eligibleStartingPlayers: number): RosterReadiness {
    const team = this.teams.get(teamId);
    if (!team) throw new Error('Team not found');
    return calculateReadiness(format, team.supportedFormats, eligibleStartingPlayers);
  }

  setSupportedFormats(actor: TeamActor, teamId: string, formats: string[]): Team {
    this.requireManage(actor.userId, teamId, 'team.update_settings');
    const team = this.teams.get(teamId);
    if (!team) throw new Error('Team not found');
    team.supportedFormats = [...new Set(formats)];
    return team;
  }

  private requireManage(userId: string, teamId: string, action: string): TeamMembership {
    const membership = this.memberships.get(this.key(teamId, userId));
    if (!membership?.active) {
      this.deniedActions.push({ action, actorId: userId, teamId, allowed: false, reason: 'team_membership_required', occurredAt: new Date().toISOString() });
      throw new Error('Team membership is required');
    }
    if (membership.role !== 'captain' && membership.role !== 'manager' && !membership.permissions.includes('team.manage')) {
      this.deniedActions.push({ action, actorId: userId, teamId, allowed: false, reason: 'team_permission_required', occurredAt: new Date().toISOString() });
      throw new Error('Team management permission is required');
    }
    return membership;
  }

  private key(teamId: string, userId: string): string {
    return `${teamId}:${userId}`;
  }
}
