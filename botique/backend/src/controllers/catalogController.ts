import type { Request, Response } from 'express';
import type { CatalogService } from '../services/catalogService.js';
import { ok } from '../utils/apiResponse.js';

export function catalogController(catalogService: CatalogService) {
  return {
    async rootCategories(_req: Request, res: Response): Promise<void> {
      ok(res, await catalogService.listRootCategories());
    },
    async subcategories(req: Request, res: Response): Promise<void> {
      ok(res, await catalogService.listSubcategories(req.params.parentId));
    },
    async brands(_req: Request, res: Response): Promise<void> {
      ok(res, await catalogService.listBrands());
    },
    async createCategory(req: Request, res: Response): Promise<void> {
      ok(res, await catalogService.createCategory(req.body), 201);
    },
  };
}