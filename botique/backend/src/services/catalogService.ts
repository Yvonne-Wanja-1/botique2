import { NotFoundError } from '../utils/errors.js';
import type { BrandRepository, CategoryRepository } from '../repositories/catalogRepository.js';

export class CatalogService {
  constructor(
    private categoryRepo: CategoryRepository,
    private brandRepo: BrandRepository,
  ) {}

  listRootCategories() {
    return this.categoryRepo.getRootCategories();
  }
  listSubcategories(parentId: string) {
    return this.categoryRepo.getSubcategories(parentId);
  }
  async getCategory(id: string) {
    const category = await this.categoryRepo.getById(id);
    if (!category) throw new NotFoundError('Category not found');
    return category;
  }
  listBrands() {
    return this.brandRepo.getAll();
  }
  createCategory(input: { name: string; slug: string; parentId?: string | null; description?: string | null; imageUrl?: string | null }) {
    return this.categoryRepo.create(input);
  }
}