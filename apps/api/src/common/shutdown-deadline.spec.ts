import { EventEmitter } from 'node:events';

import { afterEach, beforeEach, describe, expect, it, type Mock, vi } from 'vitest';

import { SHUTDOWN_DEADLINE_MS, armShutdownDeadline } from './shutdown-deadline.js';

// The deadline is the safety net behind graceful shutdown: if anything keeps the event loop alive after
// SIGTERM, the API must still exit before the container runtime's SIGKILL (Docker default: 10 s).
describe('armShutdownDeadline', () => {
  let signals: EventEmitter;
  let onOverrun: Mock<(signal: NodeJS.Signals) => void>;

  beforeEach(() => {
    vi.useFakeTimers();
    signals = new EventEmitter();
    onOverrun = vi.fn<(signal: NodeJS.Signals) => void>();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('stays under the Docker default stop grace period of 10 s', () => {
    expect(SHUTDOWN_DEADLINE_MS).toBeLessThan(10_000);
  });

  it('does nothing until a termination signal arrives', () => {
    armShutdownDeadline(onOverrun, 1_000, signals);

    vi.advanceTimersByTime(60_000);

    expect(onOverrun).not.toHaveBeenCalled();
  });

  it.each(['SIGTERM', 'SIGINT'] as const)('fires once the deadline passes after %s', (signal) => {
    armShutdownDeadline(onOverrun, 1_000, signals);

    signals.emit(signal);
    vi.advanceTimersByTime(999);
    expect(onOverrun).not.toHaveBeenCalled();

    vi.advanceTimersByTime(1);
    expect(onOverrun).toHaveBeenCalledExactlyOnceWith(signal);
  });

  it('arms only once even if the signal repeats', () => {
    armShutdownDeadline(onOverrun, 1_000, signals);

    signals.emit('SIGTERM');
    signals.emit('SIGTERM');
    vi.advanceTimersByTime(1_000);

    expect(onOverrun).toHaveBeenCalledTimes(1);
  });
});
