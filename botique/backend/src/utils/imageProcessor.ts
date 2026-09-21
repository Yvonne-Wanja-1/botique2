import sharp from 'sharp';
import { readFile } from 'node:fs/promises';

const MAX_PRODUCT_WIDTH = 1200;
const MAX_AVATAR_WIDTH = 400;
const QUALITY = 82;

export async function processProductImage(inputPath: string): Promise<{ buffer: Buffer; mimeType: string; extension: string } | null> {
  try {
    const input = await readFile(inputPath);
    const metadata = await sharp(input).metadata();
    if (!metadata.width) return null;

    const result = await sharp(input)
      .resize({ width: MAX_PRODUCT_WIDTH, withoutEnlargement: true })
      .webp({ quality: QUALITY })
      .toBuffer({ resolveWithObject: true });

    return { buffer: result.data, mimeType: 'image/webp', extension: '.webp' };
  } catch {
    return null;
  }
}

export async function processAvatar(inputPath: string): Promise<{ buffer: Buffer; mimeType: string; extension: string } | null> {
  try {
    const input = await readFile(inputPath);
    const result = await sharp(input)
      .resize({ width: MAX_AVATAR_WIDTH, height: MAX_AVATAR_WIDTH, fit: 'cover' })
      .webp({ quality: QUALITY })
      .toBuffer({ resolveWithObject: true });

    return { buffer: result.data, mimeType: 'image/webp', extension: '.webp' };
  } catch {
    return null;
  }
}

export function isProcessableImage(mimetype: string): boolean {
  return ['image/jpeg', 'image/png', 'image/webp'].includes(mimetype);
}
