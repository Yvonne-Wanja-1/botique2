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
  getReviews(productId: string) {
    return this.productRepo.getReviews(productId);
  }
}