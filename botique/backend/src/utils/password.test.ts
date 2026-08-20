import { describe, expect, it } from 'vitest';
import { hashPassword, verifyPassword } from './password.js';

describe('password hashing', () => {
  it('hashes a password to an argon2id string', async () => {
    const hash = await hashPassword('SuperSecret42');
    expect(hash).toMatch(/^\$argon2id\$/);
    expect(hash).not.toContain('SuperSecret42');
  });

  it('verifies the correct password', async () => {
    const hash = await hashPassword('SuperSecret42');
    expect(await verifyPassword('SuperSecret42', hash)).toBe(true);
  });

  it('rejects an incorrect password', async () => {
    const hash = await hashPassword('SuperSecret42');
    expect(await verifyPassword('wrong', hash)).toBe(false);
  });

  it('rejects an invalid hash without throwing', async () => {
    expect(await verifyPassword('x', 'not-a-hash')).toBe(false);
  });
});