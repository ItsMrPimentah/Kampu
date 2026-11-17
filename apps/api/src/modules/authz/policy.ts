import type { EligibilityCategory } from '../identity/eligibility';

export type GlobalRole = 'moderator' | 'support' | 'operator';
export type TeamRole = 'captain' | 'manager' | 'member';
export type PolicyAction = 'community.access' | 'team.manage' | 'team.invite' | 'match.organize' | 'match.participate' | 'moderation.review' | 'support.resolve' | 'booking.manage';

export interface PolicyActor {
  id: string;
  eligibility?: EligibilityCategory;
  globalRoles?: GlobalRole[];
  blocked?: boolean;
  teamMemberships?: Array<{ teamId: string; role: TeamRole; permissions?: string[] }>;
}

export interface PolicyInput {
  actor?: PolicyActor;
  action: PolicyAction;
  teamId?: string;
  targetUserId?: string;
  targetEligibility?: EligibilityCategory;
}

export interface PolicyDecision {
  allowed: boolean;
  reason: string;
}

export function authorize(input: PolicyInput): PolicyDecision {
  const actor = input.actor;
  if (!actor) return { allowed: false, reason: 'authentication_required' };
  if (actor.blocked) return { allowed: false, reason: 'actor_blocked' };
  if (!actor.eligibility) return { allowed: false, reason: 'eligibility_required' };
  if (input.targetUserId === actor.id && input.action === 'match.participate') {
    return { allowed: true, reason: 'self_access' };
  }

  if (input.action === 'community.access' || input.action === 'match.participate') {
    return { allowed: true, reason: 'eligible_user' };
  }
  if (input.action === 'moderation.review') {
    return { allowed: actor.globalRoles?.includes('moderator') === true, reason: 'moderator_role_required' };
  }
  if (input.action === 'support.resolve') {
    return { allowed: actor.globalRoles?.includes('support') === true, reason: 'support_role_required' };
  }
  if (input.action === 'team.manage' || input.action === 'team.invite' || input.action === 'match.organize' || input.action === 'booking.manage') {
    if (!input.teamId) return { allowed: false, reason: 'team_context_required' };
    const membership = actor.teamMemberships?.find((item) => item.teamId === input.teamId);
    if (!membership) return { allowed: false, reason: 'team_membership_required' };
    const allowed = membership.role === 'captain'
      || membership.role === 'manager'
      || membership.permissions?.includes(input.action) === true;
    return { allowed, reason: allowed ? 'team_permission_granted' : 'team_permission_required' };
  }
  return { allowed: false, reason: 'unsupported_policy_action' };
}
