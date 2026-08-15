import type { Request, Response } from 'express';
import type { ProductService } from '../services/productService.js';
import { ok } from '../utils/apiResponse.js';

export function productController(productService: ProductService) {
  return {
    async list(req: Request, res: Response): Promise<void> {
      const q = req.query;
      const result = await productService.search({
        featured: q.featured === 'true',
        newArrival: q.newArrival === 'true',
        bestSeller: q.bestSeller === 'true',
        trending: q.trending === 'true',
        onSaleOnly: q.onSale === 'true',
        availability: q.availability === 'true' ? true : q.availability === 'false' ? false : undefined,
        categoryId: q.categoryId ? String(q.categoryId) : undefined,
        brandId: q.brandId ? String(q.brandId) : undefined,
        minPrice: q.minPrice ? Number(q.minPrice) : undefined,
        maxPrice: q.maxPrice ? Number(q.maxPrice) : undefined,
        minRating: q.minRating ? Number(q.minRating) : undefined,
        sizes: q.sizes ? String(q.sizes).split(',') : undefined,
        colors: q.colors ? String(q.colors).split(',') : undefined,
        search: q.q ? String(q.q) : undefined,
        sort: q.sort as never,
        page: q.page ? Number(q.page) : undefined,
        pageSize: q.pageSize ? Number(q.pageSize) : undefined,
      });
      ok(res, { products: result.rows, total: result.total });
    },

    async get(req: Request, res: Response): Promise<void> {
      ok(res, await productService.getById(req.params.id));
    },

    async create(req: Request, res: Response): Promise<void> {
      ok(res, await productService.create(req.body), 201);
    },

    async update(req: Request, res: Response): Promise<void> {
      ok(res, await productService.update(req.params.id, req.body));
    },

    async deactivate(req: Request, res: Response): Promise<void> {
      await productService.deactivate(req.params.id);
      ok(res, { id: req.params.id, status: 'inactive' });
    },

    async reviews(req: Request, res: Response): Promise<void> {
      ok(res, await productService.getReviews(req.params.id));
    },
  };
}