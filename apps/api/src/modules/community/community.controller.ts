import { BadRequestException, Body, Controller, Get, Headers, Param, Patch, Post } from '@nestjs/common';
import { CommunityService } from './community.service';

@Controller('community')
export class CommunityController {
  constructor(private readonly service: CommunityService) {}
  private actor(header?: string) { return this.service.actor(header); }
  @Get('notifications') async notifications(@Headers('authorization') h: string) { return this.service.notifications(await this.actor(h)); }

  @Get('teams') async teams(@Headers('authorization') h?: string) { return this.service.teams(await this.actor(h)); }
  @Post('teams') async createTeam(@Headers('authorization') h: string, @Body() b: Record<string, unknown>) { return this.service.createTeam(await this.actor(h), b ?? {}); }
  @Get('teams/:id') async roster(@Headers('authorization') h: string, @Param('id') id: string) { return this.service.roster(await this.actor(h),id); }
  @Patch('teams/:id/formats') async formats(@Headers('authorization') h: string, @Param('id') id: string, @Body() b: Record<string,unknown>) { return this.service.updateTeamFormats(await this.actor(h),id,b??{}); }
  @Post('teams/:id/requests') async join(@Headers('authorization') h: string, @Param('id') id: string) { return this.service.requestJoin(await this.actor(h),id); }
  @Get('teams/:id/requests') async requests(@Headers('authorization') h: string, @Param('id') id: string) { return this.service.teamRequests(await this.actor(h),id); }
  @Post('teams/:id/requests/:request/:decision') async decide(@Headers('authorization') h: string, @Param('id') id: string, @Param('request') request: string, @Param('decision') decision: string) {
    if (!['approve','reject'].includes(decision)) throw new BadRequestException('Invalid decision');
    return this.service.decideJoin(await this.actor(h),id,request,decision==='approve');
  }
  @Post('teams/:id/invites') async invite(@Headers('authorization') h: string, @Param('id') id: string) { return this.service.invite(await this.actor(h),id); }
  @Post('teams/:id/leave') async leave(@Headers('authorization') h: string, @Param('id') id: string) { return this.service.leaveTeam(await this.actor(h),id); }
  @Post('invites/:token/accept') async accept(@Headers('authorization') h: string, @Param('token') token: string) { return this.service.acceptInvite(await this.actor(h),token); }
  @Patch('teams/:id/members/:member') async member(@Headers('authorization') h: string, @Param('id') id: string, @Param('member') member: string, @Body() b: Record<string,unknown>) { return this.service.member(await this.actor(h),id,member,b??{}); }

  @Get('challenges') async challenges(@Headers('authorization') h: string) { return this.service.challenges(await this.actor(h)); }
  @Post('challenges') async createChallenge(@Headers('authorization') h: string, @Body() b: Record<string,unknown>) { return this.service.createChallenge(await this.actor(h),b??{}); }
  @Get('challenges/:id') async challenge(@Headers('authorization') h: string, @Param('id') id: string) { return this.service.challenge(await this.actor(h),id); }
  @Post('challenges/:id/:action') async action(@Headers('authorization') h: string, @Param('id') id: string, @Param('action') action: string, @Body() b: Record<string,unknown>) { return this.service.challengeAction(await this.actor(h),id,action,b??{}); }

  @Get('games') async games(@Headers('authorization') h: string) { return this.service.games(await this.actor(h)); }
  @Get('games/:id') async game(@Headers('authorization') h: string, @Param('id') id: string) { return this.service.game(await this.actor(h),id); }
  @Post('games') async createGame(@Headers('authorization') h: string, @Body() b: Record<string,unknown>) { return this.service.createGame(await this.actor(h),b??{}); }
  @Post('game-invites/:token/accept') async acceptGameInvite(@Headers('authorization') h: string, @Param('token') token: string) { return this.service.applyGameInvite(await this.actor(h),token); }
  @Post('games/:id/invites') async inviteGame(@Headers('authorization') h: string, @Param('id') id: string) { return this.service.gameInvite(await this.actor(h),id); }
  @Post('games/:id/lifecycle/:action') async finishGame(@Headers('authorization') h: string, @Param('id') id: string, @Param('action') action: string) { return this.service.finishGame(await this.actor(h),id,action); }
  @Post('games/:id/apply') async apply(@Headers('authorization') h: string, @Param('id') id: string) { return this.service.applyGame(await this.actor(h),id); }
  @Post('games/:id/withdraw') async withdraw(@Headers('authorization') h: string, @Param('id') id: string) { return this.service.withdrawGame(await this.actor(h),id); }
  @Post('games/:id/applications/:application/remove') async remove(@Headers('authorization') h: string, @Param('id') id: string, @Param('application') application: string) { return this.service.removeGamePlayer(await this.actor(h),id,application); }
  @Get('games/:id/applications') async applications(@Headers('authorization') h: string, @Param('id') id: string) { return this.service.applications(await this.actor(h),id); }
  @Post('games/:id/applications/:application/:decision') async decideGame(@Headers('authorization') h: string, @Param('id') id: string, @Param('application') application: string, @Param('decision') decision: string) {
    if (!['approve','reject'].includes(decision)) throw new BadRequestException('Invalid decision');
    return this.service.decideGame(await this.actor(h),id,application,decision==='approve');
  }
}
