import { afterAll, describe, expect, it } from 'vitest';

import { closeDb, getDb } from './index.js';

// The pool behind getDb() is module-level, outside Nest's DI container, so nothing but closeDb() ends it.
// An idle pooled connection is enough to keep the process alive after SIGTERM (see AppModule's
// onApplicationShutdown), so these pin that closeDb() really releases it.
const DB_URL = process.env.DATABASE_URL;

describe('closeDb — no pool opened', () => {
  it('resolves without opening a connection', async () => {
    await expect(closeDb()).resolves.toBeUndefined();
  });
});

describe.skipIf(!DB_URL)('closeDb — with a live pool', () => {
  afterAll(async () => {
    await closeDb();
  });

  it('ends the pool, so the old handle refuses new queries', async () => {
    const { sql } = getDb();
    await sql`select 1`;

    await closeDb();

    await expect(sql`select 1`).rejects.toThrow();
  });

  it('is safe to call twice', async () => {
    const { sql } = getDb();
    await sql`select 1`;

    await closeDb();
    await expect(closeDb()).resolves.toBeUndefined();
  });

  it('lets getDb() open a fresh pool afterwards', async () => {
    const first = getDb().sql;
    await first`select 1`;
    await closeDb();

    const second = getDb().sql;

    expect(second).not.toBe(first);
    await expect(second`select 1 as ok`).resolves.toEqual([{ ok: 1 }]);
  });
});
