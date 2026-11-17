export interface DomainEvent<TPayload = unknown> {
  id: string;
  type: string;
  aggregateType: string;
  aggregateId: string;
  aggregateVersion: number;
  occurredAt: string;
  payload: TPayload;
  metadata: {
    actorId?: string;
    correlationId?: string;
    causationId?: string;
  };
}

export function createDomainEvent<TPayload>(input: Omit<DomainEvent<TPayload>, 'occurredAt'>): DomainEvent<TPayload> {
  if (!input.id || !input.type || !input.aggregateType || !input.aggregateId) {
    throw new Error('Domain events require id, type, aggregateType, and aggregateId');
  }
  if (!Number.isInteger(input.aggregateVersion) || input.aggregateVersion < 1) {
    throw new Error('Domain event aggregateVersion must be a positive integer');
  }
  return { ...input, occurredAt: new Date().toISOString() };
}
