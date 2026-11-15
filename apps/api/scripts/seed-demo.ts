import { seedLocalDemo } from './demo-seed';

seedLocalDemo().then(result => {
  console.log(result === 'seeded' ? 'Local demo seeded.' : 'Local demo already seeded; existing data preserved.');
}).catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : 'Local demo seed failed');
  process.exitCode = 1;
});
