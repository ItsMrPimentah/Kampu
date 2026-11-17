import assert from 'node:assert/strict';
import test from 'node:test';
import { pageRequest } from '../src/shared/contracts';
import { ErrorCode, DomainError } from '../src/shared/errors';

test('normalizes paginated API requests', () => {
  assert.deepEqual(pageRequest({ page: 0, pageSize: 500 }), { page: 1, pageSize: 100 });
});

test('exposes stable domain error codes', () => {
  const error = new DomainError(ErrorCode.Conflict, 'Opponent already selected');
  assert.equal(error.code, 'CONFLICT');
  assert.equal(error.message, 'Opponent already selected');
});
