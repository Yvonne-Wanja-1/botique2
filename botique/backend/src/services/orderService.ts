import { ForbiddenError, NotFoundError } from '../utils/errors.js';
import type { CheckoutInput, Order, OrderRepository } from '../repositories/orderRepository.js';
import type { InstallmentRepository } from '../repositories/installmentRepository.js';

export class OrderService {
  constructor(
    private orderRepo: OrderRepository,
    private installmentRepo: InstallmentRepository,
  ) {}

  async create(customerId: string, input: CheckoutInput): Promise<Order> {
    const order = await this.orderRepo.create(customerId, input);
    if (input.installmentRequested) {
      await this.installmentRepo.createPlan(order.id, customerId, 3);
    }
    return order;
  }

  async getById(id: string, viewerId: string, viewerRole: string): Promise<Order> {
    const order = await this.orderRepo.findById(id);
    if (!order) throw new NotFoundError('Order not found');
    if (viewerRole === 'customer' && order.customerId !== viewerId) {
      throw new ForbiddenError('You can only view your own orders');
    }
    return order;
  }

  listForCustomer(customerId: string, status?: string) {
    return this.orderRepo.listByCustomer(customerId, status);
  }

  listForStaff(params: { status?: string; page?: number; pageSize?: number }) {
    return this.orderRepo.listAll(params);
  }

  cancel(customerId: string, orderId: string) {
    return this.orderRepo.cancel(customerId, orderId);
  }

  async updateStatus(orderId: string, status: string, staffUserId: string) {
    const order = await this.orderRepo.setStatus(orderId, status as Order['status']);
    if (!order) throw new NotFoundError('Order not found');
    await this.orderRepo.logAudit('order', orderId, 'update', staffUserId, `Order status changed to ${status}`, { status });
    return order;
  }
}
