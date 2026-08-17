import type { Product } from '../models/index.js';
import { NotFoundError } from '../utils/errors.js';
import type {
  CreateProductInput,
  ProductRepository,
  ProductSearchParams,
} from '../repositories/productRepository.js';

export class ProductService {
  constructor(private productRepo: ProductRepository) {}

  private flag(flag: 'featured' | 'newArrival' | 'bestSeller' | 'trending') {
    return this.productRepo.search({ [flag]: true, sort: 'newest', page: 1, pageSize: 20 });
  }

  listFeatured() {
    return this.flag('featured');
  }
  listNewArrivals() {
    return this.flag('newArrival');
  }
  listBestSellers() {
    return this.flag('bestSeller');
  }
  listTrending() {
    return this.flag('trending');
  }
  listRecommended() {
    return this.productRepo.search({ sort: 'best_selling', page: 1, pageSize: 10 });
  }
  search(params: ProductSearchParams) {
    return this.productRepo.search(params);
  }
  async getAll(params: ProductSearchParams) {
    return this.productRepo.search({ ...params, includeInactive: true });
  }
  async getById(id: string): Promise<Product> {
    const product = await this.productRepo.findById(id);
    if (!product) throw new NotFoundError('Product not found');
    return product;
  }
  create(input: CreateProductInput) {
    return this.productRepo.create(input);
  }
  async update(id: string, input: Partial<CreateProductInput>) {
    const product = await this.productRepo.update(id, input);
    if (!product) throw new NotFoundError('Product not found');
    return product;
  }
  async deactivate(id: string): Promise<void> {
    const ok = await this.productRepo.setStatus(id, 'inactive');
    if (!ok) throw new NotFoundError('Product not found');
  }
  getImages(productId: string) {
    return this.productRepo.getImages(productId);
  }
  addImages(productId: string, urls: string[]) {
    return this.productRepo.addImages(productId, urls);
  }
  async removeImage(productId: string, imageId: string): Promise<void> {
    const ok = await this.productRepo.removeImage(productId, imageId);
    if (!ok) throw new NotFoundError('Product image not found');
  }
  async setPrimaryImage(productId: string, imageId: string) {
    const image = await this.productRepo.setPrimaryImage(productId, imageId);
    if (!image) throw new NotFoundError('Product image not found');
    return image;
  }
  getReviews(productId: string) {
    return this.productRepo.getReviews(productId);
  }
}