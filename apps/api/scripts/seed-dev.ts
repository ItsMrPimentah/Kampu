import { config } from 'dotenv';
import { resolve } from 'node:path';
import { seedDevAccount } from './dev-seed';

config({ path: resolve(__dirname, '../.env'), override: false, quiet: true });
seedDevAccount().then(result => {
  console.log(result === 'seeded' ? 'Development demo account seeded.' : 'Development demo account already exists; preserved.');
}).catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : 'Development seed failed');
  process.exitCode = 1;
});
