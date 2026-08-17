import type { Request, Response } from 'express';
import type { ProductService } from '../services/productService.js';
import { ok } from '../utils/apiResponse.js';
import { ValidationError } from '../utils/errors.js';

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

    async listAll(req: Request, res: Response): Promise<void> {
      const q = req.query;
      const result = await productService.getAll({
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

    async listImages(req: Request, res: Response): Promise<void> {
      ok(res, await productService.getImages(req.params.id));
    },

    async uploadImages(req: Request, res: Response): Promise<void> {
      const files = (req.files as Express.Multer.File[] | undefined) ?? [];
      if (!files.length) throw new ValidationError('No image files provided');
      const urls = files.map((f) => `/images/${f.filename}`);
      ok(res, await productService.addImages(req.params.id, urls), 201);
    },

    async removeImage(req: Request, res: Response): Promise<void> {
      await productService.removeImage(req.params.id, req.params.imageId);
      ok(res, { id: req.params.imageId, removed: true });
    },

    async setPrimaryImage(req: Request, res: Response): Promise<void> {
      const image = await productService.setPrimaryImage(req.params.id, req.params.imageId);
      ok(res, image);
    },

    async reviews(req: Request, res: Response): Promise<void> {
      ok(res, await productService.getReviews(req.params.id));
    },
  };
}