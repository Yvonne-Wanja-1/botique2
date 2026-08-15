import { describe, expect, it } from 'vitest';
import { placeOrderSchema, adjustInventorySchema, productSchema } from './schemas.js';

describe('validation schemas', () => {
  it('rejects negative quantities in order items', () => {
    const r = placeOrderSchema.safeParse({
      customerName: 'A', customerPhone: '1', customerEmail: 'a@b.com',
      shippingAddress: 'Street', paymentMethod: 'card', items: [{ productId: 'x', variantId: 'y', quantity: -1 }],
    });
    expect(r.success).toBe(false);
  });

  it('rejects negative inventory adjustments', () => {
    expect(adjustInventorySchema.safeParse({ quantity: -5 }).success).toBe(false);
    expect(adjustInventorySchema.safeParse({ quantity: 0 }).success).toBe(false);
  });

  it('rejects invalid discount price on product', () => {
    const r = productSchema.safeParse({
      name: 'P', slug: 'p', description: 'd', categoryId: 'c', brandId: 'b',
      basePrice: 10, discountPrice: 20,
    });
    expect(r.success).toBe(false);
  });
});