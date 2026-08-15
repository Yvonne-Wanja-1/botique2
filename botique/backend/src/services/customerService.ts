import type { CustomerRepository } from '../repositories/customerRepository.js';
import type { OrderRepository } from '../repositories/orderRepository.js';

export class CustomerService {
  constructor(
    private customerRepo: CustomerRepository,
    private orderRepo: OrderRepository,
  ) {}

  getProfile(customerId: string) {
    return this.customerRepo.getProfile(customerId);
  }

  listStaff(params: { search?: string; page?: number; pageSize?: number }) {
    return this.customerRepo.listStaff(params);
  }

  addAddress(customerId: string, input: Parameters<CustomerRepository['addAddress']>[1]) {
    return this.customerRepo.addAddress(customerId, input);
  }

  getAddresses(customerId: string) {
    return this.customerRepo.getAddresses(customerId);
  }

  setDefaultAddress(customerId: string, addressId: string) {
    return this.customerRepo.setDefaultAddress(customerId, addressId);
  }

  getOrders(customerId: string) {
    return this.orderRepo.listByCustomer(customerId);
  }
}