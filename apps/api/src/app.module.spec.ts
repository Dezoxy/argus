import { describe, expect, it, vi } from 'vitest';

const closeDb = vi.fn((): Promise<void> => Promise.resolve());

vi.mock('./db/index.js', async (importOriginal) => ({
  ...(await importOriginal<typeof import('./db/index.js')>()),
  closeDb,
}));

const { AppModule } = await import('./app.module.js');

// The Postgres pool is module-level (db/index.ts), not a Nest provider, so Nest's own shutdown never
// reaches it. AppModule's hook is the one place that releases it; without it an idle connection keeps
// the process alive after SIGTERM until the container runtime SIGKILLs it.
describe('AppModule shutdown', () => {
  it('closes the database pool on application shutdown', async () => {
    await new AppModule().onApplicationShutdown();

    expect(closeDb).toHaveBeenCalledTimes(1);
  });
});
