import { randomUUID } from 'node:crypto';
import { validateChallengeFormat, type ChallengeFormat } from './match-formats';

export type ApplicationStatus = 'pending' | 'approved' | 'waitlisted' | 'rejected' | 'withdrawn';

export interface OpenGame {
  id: string;
  organizerId: string;
  format: ChallengeFormat;
  capacity: number;
  requiredPositions: string[];
  waitingListEnabled: boolean;
  applications: OpenGameApplication[];
}

export interface OpenGameApplication {
  id: string;
  playerId: string;
  position?: string;
  status: ApplicationStatus;
}

export class OpenGameError extends Error {}

export class OpenGameService {
  private readonly games = new Map<string, OpenGame>();

  create(input: { organizerId: string; format: string; capacity: number; requiredPositions?: string[]; waitingListEnabled?: boolean }): OpenGame {
    const capacity = Math.floor(input.capacity);
    if (capacity < 1) throw new OpenGameError('Capacity must be positive');
    const game: OpenGame = {
      id: randomUUID(),
      organizerId: input.organizerId,
      format: validateChallengeFormat(input.format),
      capacity,
      requiredPositions: [...new Set(input.requiredPositions ?? [])],
      waitingListEnabled: input.waitingListEnabled ?? true,
      applications: [],
    };
    this.games.set(game.id, game);
    return game;
  }

  apply(gameId: string, playerId: string, position?: string): OpenGameApplication {
    const game = this.require(gameId);
    if (game.applications.some((application) => application.playerId === playerId && !['withdrawn', 'rejected'].includes(application.status))) {
      throw new OpenGameError('Player already has an active application');
    }
    const application: OpenGameApplication = { id: randomUUID(), playerId, position, status: 'pending' };
    game.applications.push(application);
    return application;
  }

  approve(gameId: string, organizerId: string, applicationId: string): OpenGameApplication {
    const game = this.require(gameId);
    if (game.organizerId !== organizerId) throw new OpenGameError('Organizer permission is required');
    const application = game.applications.find((item) => item.id === applicationId);
    if (!application || application.status !== 'pending') throw new OpenGameError('Application is not pending');
    if (this.approvedCount(game) >= game.capacity) {
      if (game.waitingListEnabled) application.status = 'waitlisted';
      else application.status = 'rejected';
      return application;
    }
    application.status = 'approved';
    return application;
  }

  withdraw(gameId: string, playerId: string): void {
    const game = this.require(gameId);
    const application = game.applications.find((item) => item.playerId === playerId && ['pending', 'waitlisted', 'approved'].includes(item.status));
    if (!application) throw new OpenGameError('Active application not found');
    application.status = 'withdrawn';
    this.promoteNext(game);
  }

  get(gameId: string): OpenGame | undefined { return this.games.get(gameId); }

  private approvedCount(game: OpenGame): number {
    return game.applications.filter((application) => application.status === 'approved').length;
  }

  private promoteNext(game: OpenGame): void {
    if (this.approvedCount(game) >= game.capacity) return;
    const next = game.applications.find((application) => application.status === 'waitlisted');
    if (next) next.status = 'approved';
  }

  private require(gameId: string): OpenGame {
    const game = this.games.get(gameId);
    if (!game) throw new OpenGameError('Open Game not found');
    return game;
  }
}
