import { readFileSync } from 'node:fs';
import pino from 'pino';
import { pinoConfig } from '../observability/logger.js';

const logger = pino({ ...pinoConfig, name: 'PushConfig' });

export interface VapidConfig {
  publicKey: string;
  privateKey: string;
  subject: string;
  /** false when any VAPID value is missing — PushService becomes a no-op. */
  configured: boolean;
}

export function loadVapidConfig(): VapidConfig {
  const publicKey = process.env.VAPID_PUBLIC_KEY ?? '';
  const privateKey = resolvePrivateKey();
  const subject = process.env.VAPID_SUBJECT ?? 'mailto:admin@argus.local';
  const configured = Boolean(publicKey && privateKey && subject);
  return { publicKey, privateKey, subject, configured };
}

function resolvePrivateKey(): string {
  const file = process.env.VAPID_PRIVATE_KEY_FILE;
  if (!file) return '';
  try {
    // The path comes from VAPID_PRIVATE_KEY_FILE, set at deploy time from Key
    // Vault -- it is never user input. Reading secrets from a mounted file
    // rather than an environment variable is required by invariant #5; see
    // docs/architecture/deployment/secrets-inventory.md.
    // eslint-disable-next-line security/detect-non-literal-fs-filename -- deploy-time credential path, not user input
    return readFileSync(file, 'utf8').trim();
  } catch {
    // Log only that the file is unreadable — never the path or its contents (invariant #2).
    logger.warn('push: VAPID credential file unreadable; push disabled');
    return '';
  }
}
