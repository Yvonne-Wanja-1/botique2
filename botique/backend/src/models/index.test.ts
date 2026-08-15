import { describe, expect, it } from 'vitest';
import { normalizePercent, ORDER_STATUS_TRANSITIONS } from './index.js';

describe('models helpers', () => {
  it('clamps percent to [0,100]', () => {
    expect(normalizePercent(150)).toBe(100);
    expect(normalizePercent(-5)).toBe(0);
    expect(normalizePercent(12.5)).toBe(12.5);
  });

  it('declares allowed order status transitions', () => {
    expect(ORDER_STATUS_TRANSITIONS.pending).toContain('paid');
    expect(ORDER_STATUS_TRANSITIONS.paid).toContain('processing');
    expect(ORDER_STATUS_TRANSITIONS.delivered).not.toContain('cancelled');
  });
});