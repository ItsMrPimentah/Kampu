import 'dotenv/config';
import { readFile } from 'node:fs/promises';
import { Client } from 'pg';

async function main(): Promise<void> {
  const databaseUrl = process.env.DATABASE_URL ?? 'postgres://showtime:showtime@localhost:5432/showtime';
  const migrations = ['0000_initial.sql', '0001_auth.sql', '0002_community.sql'];
  const client = new Client({ connectionString: databaseUrl });
  await client.connect();
  try {
    await client.query('BEGIN');
    for (const name of migrations) {
      const migration = await readFile(new URL(`../drizzle/migrations/${name}`, import.meta.url), 'utf8');
      await client.query(migration);
    }
    await client.query('COMMIT');
    console.log(`Applied ${migrations.join(', ')}`);
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    await client.end();
  }
}

main().catch((error: unknown) => {
  console.error(error);
  process.exitCode = 1;
});
