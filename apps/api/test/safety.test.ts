import assert from 'node:assert/strict';
import test from 'node:test';
import { SafetyService } from '../src/modules/safety/safety.service';

test('restricts youth discovery and messaging while preserving authorized contexts', () => {
  const service = new SafetyService();
  const adult = { id: 'adult', eligibility: 'adult' as const };
  const youth = { id: 'youth', eligibility: 'youth' as const };
  assert.equal(service.canDiscover(adult, youth, false), false);
  assert.equal(service.canDiscover(adult, youth, true), true);
  assert.equal(service.canMessage(adult, youth, false), false);
  assert.equal(service.canMessage(adult, youth, true), true);
  service.block('adult', 'youth');
  assert.equal(service.canDiscover(adult, youth, true), false);
});

test('supports reports and moderator review', () => {
  const service = new SafetyService();
  const report = service.report('player', 'content', 'unsafe');
  assert.equal(service.review({ id: 'mod', eligibility: 'adult', moderator: true }, report.id).status, 'reviewed');
});
