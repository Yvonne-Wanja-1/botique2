import type { Request, Response } from 'express';
import type { InventoryService } from '../services/inventoryService.js';
import { ok } from '../utils/apiResponse.js';

export function inventoryController(inventoryService: InventoryService) {
  return {
    async list(req: Request, res: Response): Promise<void> {
      const stock = req.query.stock === 'low' || req.query.stock === 'out' ? req.query.stock : 'all';
      ok(res, await inventoryService.listVariantInventory(stock));
    },
    async adjust(req: Request, res: Response): Promise<void> {
      const result = await inventoryService.adjust(
        req.params.variantId,
        req.body,
        req.principal?.userId ?? null,
      );
      ok(res, result);
    },
  };
}