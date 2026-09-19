import { ForbiddenError, NotFoundError } from '../utils/errors.js';
import type { CheckoutInput, Order, OrderRepository } from '../repositories/orderRepository.js';
import type { InstallmentRepository } from '../repositories/installmentRepository.js';
import type { PaymentRepository } from '../repositories/paymentRepository.js';
import type { NotificationRepository } from '../repositories/notificationRepository.js';

export class OrderService {
  constructor(
    private orderRepo: OrderRepository,
    private installmentRepo: InstallmentRepository,
    private paymentRepo?: PaymentRepository,
    private notificationRepo?: NotificationRepository,
  ) {}

  async create(customerId: string, input: CheckoutInput): Promise<Order> {
    const order = await this.orderRepo.create(customerId, input);
    if (input.installmentRequested) {
      await this.installmentRepo.createPlan(order.id, customerId, 3);
    }
    if (input.confirmationMessage && this.paymentRepo) {
      await this.paymentRepo.submit({
        orderId: order.id,
        customerId,
        amount: order.total,
        paymentDate: new Date().toISOString().slice(0, 10),
        confirmationMessage: input.confirmationMessage,
      });
    }
    if (this.notificationRepo) {
      const mpesaSnippet = input.confirmationMessage
        ? input.confirmationMessage.slice(0, 120)
        : 'No payment proof submitted';
      try {
        await this.notificationRepo.create({
          userId: customerId,
          type: 'order',
          title: 'Order placed',
          body: `Your order ${order.orderNumber} has been placed and is awaiting approval.`,
        });
        await this.notificationRepo.create({
          type: 'order',
          title: `New order ${order.orderNumber}`,
          body: `New order from ${input.customerName}. M-Pesa confirmation: ${mpesaSnippet}`,
          target: 'staff',
        });
      } catch {
        // Notification failure should not block order creation
      }
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
