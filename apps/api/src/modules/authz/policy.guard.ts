import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { POLICY_ACTION } from './policy.decorator';
import { authorize, type PolicyAction, type PolicyActor } from './policy';

interface RequestWithPolicyContext {
  user?: PolicyActor;
  teamId?: string;
}

@Injectable()
export class PolicyGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const action = this.reflector.getAllAndOverride<PolicyAction>(POLICY_ACTION, [context.getHandler(), context.getClass()]);
    if (!action) return true;
    const request = context.switchToHttp().getRequest<RequestWithPolicyContext>();
    const decision = authorize({ actor: request.user, action, teamId: request.teamId });
    if (!decision.allowed) throw new ForbiddenException({ code: 'FORBIDDEN', reason: decision.reason });
    return true;
  }
}
