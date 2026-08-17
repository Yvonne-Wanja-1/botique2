import { ConflictError, ForbiddenError, NotFoundError } from '../utils/errors.js';
import type { PaymentRepository, SubmitPaymentInput } from '../repositories/paymentRepository.js';
import type { OrderRepository } from '../repositories/orderRepository.js';
import type { InstallmentRepository } from '../repositories/installmentRepository.js';
import type { NotificationRepository } from '../repositories/notificationRepository.js';
import type { AuditRepository } from '../repositories/auditRepository.js';

export class PaymentService {
  constructor(
    private paymentRepo: PaymentRepository,
    private orderRepo: OrderRepository,
    private installmentRepo: InstallmentRepository,
    private notificationRepo: NotificationRepository,
    private auditRepo: AuditRepository,
  ) {}

  async submit(customerId: string, input: SubmitPaymentInput) {
    const order = await this.orderRepo.findById(input.orderId);
    if (!order) throw new NotFoundError('Order not found');
    if (order.customerId !== customerId) {
      throw new ForbiddenError('You can only submit payments for your own orders');
    }
    const payment = await this.paymentRepo.submit({ ...input, customerId });
    await this.notificationRepo.create({
      userId: customerId,
      type: 'payment',
      title: 'Payment submitted',
      body: `Payment of ${input.amount} for order ${order.orderNumber} is awaiting verification.`,
    });
    return payment;
  }

  async listForOrder(orderId: string, viewerId: string, viewerRole: string) {
    const order = await this.orderRepo.findById(orderId);
    if (!order) throw new NotFoundError('Order not found');
    if (viewerRole === 'customer' && order.customerId !== viewerId) {
      throw new ForbiddenError('You can only view payments for your own orders');
    }
    return this.paymentRepo.listForOrder(orderId);
  }

  async list(customerId: string, viewerRole: string, params: { status?: string; page?: number; pageSize?: number }) {
    if (viewerRole === 'customer') {
      return { rows: await this.paymentRepo.listForCustomer(customerId), total: 0 };
    }
    return this.paymentRepo.listAll(params);
  }

  async getById(id: string, viewerId: string, viewerRole: string) {
    const payment = await this.paymentRepo.getById(id);
    if (!payment) throw new NotFoundError('Payment not found');
    if (viewerRole === 'customer' && payment.customerId !== viewerId) {
      throw new ForbiddenError('You can only view your own payments');
    }
    return payment;
  }

  async verify(id: string, staffUserId: string) {
    const payment = await this.paymentRepo.getById(id);
    if (!payment) throw new NotFoundError('Payment not found');

    const updated = await this.paymentRepo.verify(id, staffUserId);

    const installment = await this.installmentRepo.getByOrder(payment.orderId);
    if (installment && installment.status === 'active') {
      await this.installmentRepo.applyPayment(installment.id, payment.amount);
    }

    const order = await this.orderRepo.findById(payment.orderId);
    const orderNumber = order?.orderNumber ?? payment.orderId;
    await this.notificationRepo.create({
      userId: payment.customerId,
      type: 'payment',
      title: 'Payment verified',
      body: `Payment of ${payment.amount} for order ${orderNumber} was verified successfully.`,
    });
    if (order && order.paymentStatus === 'successful') {
      await this.notificationRepo.create({
        userId: payment.customerId,
        type: 'payment',
        title: 'Order fully paid',
        body: `Order ${orderNumber} is now fully paid.`,
      });
    }
    await this.auditRepo.log({
      actorUserId: staffUserId,
      action: 'approve',
      resource: 'payment',
      resourceId: id,
      description: `Verified payment of ${payment.amount} for order ${orderNumber}`,
    });
    return updated;
  }

  async reject(id: string, staffUserId: string, reason: string) {
    const payment = await this.paymentRepo.getById(id);
    if (!payment) throw new NotFoundError('Payment not found');

    const updated = await this.paymentRepo.reject(id, staffUserId, reason);

    const order = await this.orderRepo.findById(payment.orderId);
    const orderNumber = order?.orderNumber ?? payment.orderId;
    await this.notificationRepo.create({
      userId: payment.customerId,
      type: 'payment',
      title: 'Payment rejected',
      body: `Your payment of ${payment.amount} for order ${orderNumber} was rejected. ${reason}`,
    });
    await this.auditRepo.log({
      actorUserId: staffUserId,
      action: 'reject',
      resource: 'payment',
      resourceId: id,
      description: `Rejected payment of ${payment.amount} for order ${orderNumber}: ${reason}`,
      newValue: { reason },
    });
    return updated;
  }

  transferDetails() {
    return this.paymentRepo.transferDetails();
  }
}