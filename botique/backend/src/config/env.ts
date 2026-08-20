import 'dotenv/config';

export interface AppConfig {
  port: number;
  databaseUrl: string;
  nodeEnv: string;
  uploadsDir: string;
  jwtSecret: string;
  jwtExpiresIn: string;
}

export function loadConfig(env: Record<string, string | undefined> = process.env): AppConfig {
  const port = Number(env.PORT ?? 8080);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error(`Invalid PORT: ${env.PORT}`);
  }
  const databaseUrl =
    env.DATABASE_URL ??
    buildDatabaseUrl({
      host: env.DB_HOST,
      port: env.DB_PORT,
      name: env.DB_NAME,
      user: env.DB_USER,
      password: env.DB_PASSWORD,
    });
  if (!databaseUrl) {
    throw new Error(
      'DATABASE_URL is required. Copy backend/.env.example to backend/.env and set it.',
    );
  }
  const nodeEnv = env.NODE_ENV ?? 'development';
  const jwtSecret = env.JWT_SECRET ?? '';
  if (jwtSecret.length < 16) {
    if (nodeEnv === 'production') {
      throw new Error(
        'JWT_SECRET is required in production and must be at least 16 characters. ' +
          'Set it in backend/.env (e.g. openssl rand -hex 32).',
      );
    }
    console.warn('WARNING: JWT_SECRET is not set; using an insecure development secret. Set JWT_SECRET in backend/.env.');
  }
  return {
    port,
    databaseUrl,
    nodeEnv,
    uploadsDir: env.UPLOADS_DIR ?? 'uploads',
    jwtSecret: jwtSecret || 'dev-only-jwt-secret-do-not-use-in-production',
    jwtExpiresIn: env.JWT_EXPIRES_IN ?? '7d',
  };
}

function buildDatabaseUrl(opts: {
  host?: string;
  port?: string;
  name?: string;
  user?: string;
  password?: string;
}): string | null {
  const { host, port, name, user, password } = opts;
  if (!host || !name || !user) return null;
  const base = `postgresql://${encodeURIComponent(user)}${password ? `:${encodeURIComponent(password)}` : ''}@${host}`;
  const withPort = port ? `${base}:${Number(port)}` : base;
  return `${withPort}/${name}`;
}