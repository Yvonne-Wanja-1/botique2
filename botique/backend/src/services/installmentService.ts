import { ForbiddenError, NotFoundError } from '../utils/errors.js';
import type { InstallmentRepository } from '../repositories/installmentRepository.js';

export class InstallmentService {
  constructor(private installmentRepo: InstallmentRepository) {}

  async getByOrder(orderId: string, viewerId: string, viewerRole: string) {
    const plan = await this.installmentRepo.getByOrder(orderId);
    if (!plan) throw new NotFoundError('No installment plan exists for this order');
    if (viewerRole === 'customer' && plan.customerId !== viewerId) {
      throw new ForbiddenError('You can only view your own installment plans');
    }
    return plan;
  }

  createPlan(orderId: string, customerId: string, planCount: number) {
    return this.installmentRepo.createPlan(orderId, customerId, planCount);
  }

  payPayment(paymentId: string, customerId: string, amount: number) {
    return this.installmentRepo.payPayment(paymentId, customerId, amount);
  }
}