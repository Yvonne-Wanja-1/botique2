import argon2 from 'argon2';

// Argon2id — the recommended KDF for password storage.
// Returns a self-describing encoded hash (includes algorithm + parameters).
export async function hashPassword(plain: string): Promise<string> {
  return argon2.hash(plain, { type: argon2.argon2id });
}

export async function verifyPassword(plain: string, hash: string): Promise<boolean> {
  try {
    return await argon2.verify(hash, plain);
  } catch {
    return false;
  }
}
