import { randomUUID } from 'node:crypto';

export interface ExternalBookingDeclaration {
  id: string;
  matchId: string;
  venueId: string;
  requestedAt: string;
  sourceUrl: string;
  externalReference?: string;
  receiptMetadata?: { objectKey: string; contentType: string };
  authority: 'user_declared';
  verificationLevel: 'user_declared';
  status: 'externally_declared';
}

export class ExternalBookingError extends Error {}

export class ExternalBookingService {
  private readonly declarations = new Map<string, ExternalBookingDeclaration>();

  declare(input: Omit<ExternalBookingDeclaration, 'id' | 'authority' | 'verificationLevel' | 'status'>): ExternalBookingDeclaration {
    if (!input.matchId || !input.venueId) throw new ExternalBookingError('Venue and match are required');
    if (!Number.isFinite(Date.parse(input.requestedAt))) throw new ExternalBookingError('Requested time is invalid');
    let url: URL;
    try { url = new URL(input.sourceUrl); } catch { throw new ExternalBookingError('Source URL is invalid'); }
    if (!['https:', 'http:'].includes(url.protocol)) throw new ExternalBookingError('Source URL must be HTTP or HTTPS');
    const declaration: ExternalBookingDeclaration = { ...input, id: randomUUID(), authority: 'user_declared', verificationLevel: 'user_declared', status: 'externally_declared' };
    this.declarations.set(declaration.id, declaration);
    return declaration;
  }

  get(id: string): ExternalBookingDeclaration | undefined { return this.declarations.get(id); }
}
