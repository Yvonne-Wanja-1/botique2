import { ConflictError, ForbiddenError, NotFoundError } from '../utils/errors.js';
import type { PaymentRepository } from '../repositories/paymentRepository.js';

export class PaymentService {
  constructor(private paymentRepo: PaymentRepository) {}

  async getByOrder(orderId: string, viewerId: string, viewerRole: string) {
    const payment = await this.paymentRepo.getByOrder(orderId);
    if (!payment) throw new NotFoundError('Payment not found for this order');
    if (viewerRole === 'customer' && payment.customerId !== viewerId) {
      throw new ForbiddenError('You can only view payments for your own orders');
    }
    return payment;
  }

  async verify(orderId: string, reference: string, viewerId: string, viewerRole: string) {
    const payment = await this.paymentRepo.getByOrder(orderId);
    if (!payment) throw new NotFoundError('Payment not found for this order');
    if (viewerRole === 'customer' && payment.customerId !== viewerId) {
      throw new ForbiddenError('You can only verify payments for your own orders');
    }
    const updated = await this.paymentRepo.verify(orderId, reference);
    if (!updated) throw new ConflictError('Payment is not in a payable state');
    return updated;
  }

  transferDetails() {
    return this.paymentRepo.transferDetails();
  }
}