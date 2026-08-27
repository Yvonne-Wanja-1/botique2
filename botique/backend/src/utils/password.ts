import { randomBytes, scryptSync, timingSafeEqual } from 'node:crypto';

const KEY_LENGTH = 64;

/**
 * Password hashing using Node.js built-in scrypt. Produces a self-describing
 * encoded hash so the algorithm can be upgraded later without breaking
 * existing hashes.
 */
export async function hashPassword(plain: string): Promise<string> {
  const salt = randomBytes(16).toString('hex');
  const hash = scryptSync(plain, salt, KEY_LENGTH);
  return `scrypt:${salt}:${hash.toString('hex')}`;
}

export async function verifyPassword(plain: string, stored: string): Promise<boolean> {
  try {
    if (stored.startsWith('scrypt:')) {
      const [, salt, hashHex] = stored.split(':');
      const hash = Buffer.from(hashHex, 'hex');
      const derived = scryptSync(plain, salt, KEY_LENGTH);
      return timingSafeEqual(hash, derived);
    }
    return false;
  } catch {
    return false;
  }
}
