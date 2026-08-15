import type { ReviewRepository } from '../repositories/reviewRepository.js';

export class ReviewService {
  constructor(private reviewRepo: ReviewRepository) {}

  add(customerId: string, productId: string, input: { rating: number; comment: string }) {
    return this.reviewRepo.add(customerId, productId, input);
  }

  listForProduct(productId: string) {
    return this.reviewRepo.listForProduct(productId);
  }

  listPending() {
    return this.reviewRepo.listPending();
  }

  moderate(id: string, approved: boolean) {
    return this.reviewRepo.moderate(id, approved);
  }

  report(id: string) {
    return this.reviewRepo.report(id);
  }
}