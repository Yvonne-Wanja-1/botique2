import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { Pool } from 'pg';
import { loadPgMem, schemaPath } from '../db/pgMem.js';
import { createApp } from '../app.js';

const STAFF = { 'x-user-id': '00000000-0000-0000-0000-000000000203', 'x-user-role': 'store_manager' };
const CUSTOMER = { 'x-user-id': '00000000-0000-0000-0000-000000000201', 'x-user-role': 'customer' };
const PRODUCT = '00000000-0000-0000-0000-000000000501';
const PRODUCT_INACTIVE = '00000000-0000-0000-0000-000000000502';

function pngBuffer(): Buffer {
  // Minimal 1x1 PNG so multer's size/mimetype checks pass.
  return Buffer.from(
    '89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4890000000d49444154789c626001000000ffff03000006000557bfabd40000000049454e44ae426082',
    'hex',
  );
}

describe('product images API', () => {
  let pool: Pool;
  let app: ReturnType<typeof createApp>;
  let uploadsDir: string;

  beforeAll(async () => {
    uploadsDir = mkdtempSync(join(tmpdir(), 'qt-uploads-'));
    pool = loadPgMem(schemaPath());
    app = createApp(pool, { uploadsDir });
  });

  afterAll(async () => {
    await pool.end();
    rmSync(uploadsDir, { recursive: true, force: true });
  });

  it('denies customers from uploading images', async () => {
    const res = await request(app)
      .post(`/api/products/${PRODUCT}/images`)
      .set(CUSTOMER)
      .attach('images', pngBuffer(), { filename: 'a.png', contentType: 'image/png' });
    expect(res.status).toBe(403);
  });

  it('uploads images and returns image records', async () => {
    const res = await request(app)
      .post(`/api/products/${PRODUCT}/images`)
      .set(STAFF)
      .attach('images', pngBuffer(), { filename: 'front.png', contentType: 'image/png' })
      .attach('images', pngBuffer(), { filename: 'back.png', contentType: 'image/png' });
    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    const images = res.body.data as Array<Record<string, unknown>>;
    expect(images).toHaveLength(2);
    expect(images[0].url).toMatch(/^\/images\//);
    expect(images[0].position).toBe(1);
    expect(images[1].position).toBe(2);
    expect(images[0].isPrimary).toBe(false);
  });

  it('lists image records for a product', async () => {
    const res = await request(app).get(`/api/products/${PRODUCT}/images`).set(STAFF);
    expect(res.status).toBe(200);
    const images = res.body.data as Array<Record<string, unknown>>;
    expect(images.length).toBeGreaterThanOrEqual(1);
    expect(images[0]).toHaveProperty('id');
    expect(images[0]).toHaveProperty('position');
    expect(images[0]).toHaveProperty('isPrimary');
  });

  it('lists all products including inactive for staff', async () => {
    const res = await request(app).get('/api/products/all').set(STAFF);
    expect(res.status).toBe(200);
    const ids = (res.body.data.products as Array<Record<string, unknown>>).map((p) => p.id);
    expect(ids).toContain(PRODUCT_INACTIVE);
  });

  it('rejects uploads for a missing product', async () => {
    const res = await request(app)
      .post('/api/products/00000000-0000-0000-0000-00000000ffff/images')
      .set(STAFF)
      .attach('images', pngBuffer(), { filename: 'a.png', contentType: 'image/png' });
    expect(res.status).toBe(404);
  });

  it('rejects non-image uploads', async () => {
    const res = await request(app)
      .post(`/api/products/${PRODUCT}/images`)
      .set(STAFF)
      .attach('images', Buffer.from('not an image'), { filename: 'a.txt', contentType: 'text/plain' });
    expect(res.status).toBe(422);
  });

  it('sets a primary image and swaps positions', async () => {
    const listRes = await request(app).get(`/api/products/${PRODUCT}/images`).set(STAFF);
    const images = listRes.body.data as Array<Record<string, unknown>>;
    const original = images.find((i) => i.position === 0) as { id: string };
    const other = images.find((i) => i.id !== original.id) as { id: string };

    const res = await request(app)
      .patch(`/api/products/${PRODUCT}/images/${other.id}`)
      .set(STAFF)
      .send({ isPrimary: true });
    expect(res.status).toBe(200);
    expect(res.body.data.id).toBe(other.id);
    expect(res.body.data.isPrimary).toBe(true);
    expect(res.body.data.position).toBe(0);

    const after = (await request(app).get(`/api/products/${PRODUCT}/images`).set(STAFF))
      .body.data as Array<Record<string, unknown>>;
    expect(after.find((i) => i.id === original.id)?.isPrimary).toBe(false);
  });

  it('removes an image and reassigns primary', async () => {
    const before = (await request(app).get(`/api/products/${PRODUCT}/images`).set(STAFF))
      .body.data as Array<Record<string, unknown>>;
    const primary = before.find((i) => i.isPrimary === true) as { id: string };
    expect(primary).toBeDefined();

    const res = await request(app).delete(`/api/products/${PRODUCT}/images/${primary.id}`).set(STAFF);
    expect(res.status).toBe(200);
    expect(res.body.data.removed).toBe(true);

    const after = (await request(app).get(`/api/products/${PRODUCT}/images`).set(STAFF))
      .body.data as Array<Record<string, unknown>>;
    expect(after.some((i) => i.id === primary.id)).toBe(false);
    expect(after.filter((i) => i.isPrimary === true)).toHaveLength(1);
  });
});
