import { randomUUID } from 'node:crypto';

export interface FusionGame {
  id: string;
  matchId: string;
  teams: Array<{ teamId: string; captainId: string; details: Record<string, unknown>; contributions: Record<string, number> }>;
}

export class FusionError extends Error {}

export class FusionService {
  private readonly games = new Map<string, FusionGame>();

  create(matchId: string, teams: Array<{ teamId: string; captainId: string }>): FusionGame {
    if (teams.length < 2) throw new FusionError('Fusion requires at least two teams');
    if (new Set(teams.map((team) => team.teamId)).size !== teams.length) throw new FusionError('Fusion teams must be distinct');
    const game: FusionGame = {
      id: randomUUID(),
      matchId,
      teams: teams.map((team) => ({ ...team, details: {}, contributions: {} })),
    };
    this.games.set(game.id, game);
    return game;
  }

  updateTeamDetails(gameId: string, captainId: string, details: Record<string, unknown>): FusionGame {
    const game = this.require(gameId);
    const team = game.teams.find((entry) => entry.captainId === captainId);
    if (!team) throw new FusionError('Captain is not a Fusion participant');
    team.details = { ...team.details, ...details };
    return game;
  }

  recordContribution(gameId: string, captainId: string, playerId: string, amount: number): FusionGame {
    const game = this.require(gameId);
    const team = game.teams.find((entry) => entry.captainId === captainId);
    if (!team) throw new FusionError('Captain is not a Fusion participant');
    if (!Number.isFinite(amount) || amount < 0) throw new FusionError('Contribution amount is invalid');
    team.contributions[playerId] = amount;
    return game;
  }

  get(gameId: string): FusionGame | undefined { return this.games.get(gameId); }

  private require(gameId: string): FusionGame {
    const game = this.games.get(gameId);
    if (!game) throw new FusionError('Fusion game not found');
    return game;
  }
}
