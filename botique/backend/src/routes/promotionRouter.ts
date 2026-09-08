import { Router } from 'express';
import { z } from 'zod';
import type { PromotionRepository } from '../repositories/promotionRepository.js';
import { validateBody } from '../middleware/validate.js';
import { promotionSchema } from '../validation/schemas.js';
import { asyncHandler } from '../utils/asyncHandler.js';
import { ok } from '../utils/apiResponse.js';

const promotionUpdateSchema = z.object({
  code: z.string().min(1).max(50).optional(),
  title: z.string().min(1).optional(),
  description: z.string().nullable().optional(),
  type: z.enum(['percentage', 'fixed']).optional(),
  value: z.number().positive().optional(),
  categoryId: z.string().uuid().nullable().optional(),
  productId: z.string().uuid().nullable().optional(),
  minimumOrderAmount: z.number().positive().nullable().optional(),
  maximumDiscount: z.number().positive().nullable().optional(),
  usageLimit: z.number().int().positive().nullable().optional(),
  startDate: z.string().nullable().optional(),
  endDate: z.string().nullable().optional(),
  isActive: z.boolean().optional(),
});

export function promotionRouter(promotionRepo: PromotionRepository) {
  const router = Router();

  // Admin: list all promotions
  router.get('/', asyncHandler(async (_req, res) => {
    ok(res, await promotionRepo.listAll());
  }));

  // Get single promotion
  router.get('/:id', asyncHandler(async (req, res) => {
    const promo = await promotionRepo.getById(req.params.id);
    if (!promo) {
      res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'Promotion not found' } });
      return;
    }
    ok(res, promo);
  }));

  // Create promotion
  router.post('/', validateBody(promotionSchema), asyncHandler(async (req, res) => {
    const promo = await promotionRepo.create(req.body);
    ok(res, promo, 201);
  }));

  // Validate a promo code and return discount info (for checkout preview)
  router.post('/validate', asyncHandler(async (req, res) => {
    const { code, subtotal } = req.body as { code?: string; subtotal?: number };
    if (!code || typeof code !== 'string') {
      res.status(400).json({ success: false, error: { code: 'VALIDATION', message: 'Promo code is required' } });
      return;
    }
    const promo = await promotionRepo.getByCode(code);
    if (!promo || !promo.isActive) {
      res.status(400).json({ success: false, error: { code: 'VALIDATION', message: 'Promotion code is invalid or inactive' } });
      return;
    }
    if (promo.startDate && new Date(promo.startDate) > new Date()) {
      res.status(400).json({ success: false, error: { code: 'VALIDATION', message: 'This promotion has not started yet' } });
      return;
    }
    if (promo.endDate && new Date(promo.endDate) < new Date()) {
      res.status(400).json({ success: false, error: { code: 'VALIDATION', message: 'This promotion has expired' } });
      return;
    }
    if (promo.usageLimit !== null && promo.usageCount >= promo.usageLimit) {
      res.status(400).json({ success: false, error: { code: 'VALIDATION', message: 'This promotion has reached its usage limit' } });
      return;
    }
    const sub = typeof subtotal === 'number' ? subtotal : 0;
    if (promo.minimumOrderAmount !== null && sub < promo.minimumOrderAmount) {
      res.status(400).json({ success: false, error: { code: 'VALIDATION', message: `Minimum order amount is ${promo.minimumOrderAmount}` } });
      return;
    }
    let discount = promo.type === 'percentage' ? (sub * promo.value) / 100 : promo.value;
    if (promo.maximumDiscount !== null && discount > promo.maximumDiscount) {
      discount = promo.maximumDiscount;
    }
    if (discount > sub) discount = sub;
    ok(res, { code: promo.code, title: promo.title, discount, type: promo.type, value: promo.value });
  }));

  // Update promotion (including toggle isActive)
  router.put('/:id', validateBody(promotionUpdateSchema), asyncHandler(async (req, res) => {
    ok(res, await promotionRepo.update(req.params.id, req.body));
  }));

  // Delete promotion
  router.delete('/:id', asyncHandler(async (req, res) => {
    await promotionRepo.delete(req.params.id);
    ok(res, { deleted: true });
  }));

  return router;
}
