import { randomUUID } from 'node:crypto';

export type AttendanceStatus = 'requested' | 'confirmed' | 'declined' | 'no_show';

export interface AttendanceRecord {
  matchId: string;
  userId: string;
  status: AttendanceStatus;
  respondedAt?: string;
}

export interface CompletionEvent {
  id: string;
  matchId: string;
  name: 'match.completed';
  occurredAt: string;
}

export class AttendanceError extends Error {}

export class AttendanceService {
  private readonly attendance = new Map<string, AttendanceRecord>();
  private readonly completed = new Set<string>();
  private readonly completionEvents: CompletionEvent[] = [];

  request(matchId: string, organizerId: string, participantIds: string[], authorizedOrganizerId: string): AttendanceRecord[] {
    if (organizerId !== authorizedOrganizerId) throw new AttendanceError('Organizer permission is required');
    return participantIds.map((userId) => {
      const record: AttendanceRecord = { matchId, userId, status: 'requested' };
      this.attendance.set(this.key(matchId, userId), record);
      return record;
    });
  }

  respond(matchId: string, userId: string, status: 'confirmed' | 'declined'): AttendanceRecord {
    const record = this.attendance.get(this.key(matchId, userId));
    if (!record) throw new AttendanceError('Attendance request not found');
    record.status = status;
    record.respondedAt = new Date().toISOString();
    return record;
  }

  markNoShow(matchId: string, organizerId: string, userId: string, authorizedOrganizerId: string): AttendanceRecord {
    if (organizerId !== authorizedOrganizerId) throw new AttendanceError('Organizer permission is required');
    const record = this.attendance.get(this.key(matchId, userId));
    if (!record) throw new AttendanceError('Attendance request not found');
    record.status = 'no_show';
    record.respondedAt = new Date().toISOString();
    return record;
  }

  complete(matchId: string, organizerId: string, authorizedOrganizerId: string): CompletionEvent {
    if (organizerId !== authorizedOrganizerId) throw new AttendanceError('Organizer permission is required');
    if (this.completed.has(matchId)) return this.completionEvents.find((event) => event.matchId === matchId)!;
    this.completed.add(matchId);
    const event: CompletionEvent = { id: randomUUID(), matchId, name: 'match.completed', occurredAt: new Date().toISOString() };
    this.completionEvents.push(event);
    return event;
  }

  events(): CompletionEvent[] { return [...this.completionEvents]; }

  private key(matchId: string, userId: string): string { return `${matchId}:${userId}`; }
}
