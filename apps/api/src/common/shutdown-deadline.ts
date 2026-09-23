import type { EventEmitter } from 'node:events';

// Under Docker's default 10 s stop grace period (compose.prod.yaml sets none), so the API exits on its
// own — and logs why — before the runtime SIGKILLs it.
export const SHUTDOWN_DEADLINE_MS = 8_000;

/**
 * Bound graceful shutdown. Because observability/tracing.ts listens for SIGTERM/SIGINT, Node does not
 * terminate on the signal: the process exits only once every socket and timer has drained. If a future
 * change leaks one (as the unclosed Postgres pool did), shutdown would hang until SIGKILL. This arms a
 * timer on the first termination signal and calls `onOverrun` if the process is still alive when it fires.
 * The timer is unref'd, so it never delays a clean exit.
 */
export function armShutdownDeadline(
  onOverrun: (signal: NodeJS.Signals) => void,
  deadlineMs: number = SHUTDOWN_DEADLINE_MS,
  signals: Pick<EventEmitter, 'once'> = process,
): void {
  for (const signal of ['SIGTERM', 'SIGINT'] as const) {
    signals.once(signal, () => {
      setTimeout(() => onOverrun(signal), deadlineMs).unref();
    });
  }
}
