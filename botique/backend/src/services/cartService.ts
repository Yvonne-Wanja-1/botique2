import type { CartRepository } from '../repositories/cartRepository.js';

export class CartService {
  constructor(private cartRepo: CartRepository) {}

  getCart(customerId: string) {
    return this.cartRepo.getCart(customerId);
  }
  addToCart(customerId: string, input: { productId: string; variantId: string | null; quantity: number }) {
    return this.cartRepo.addItem(customerId, input.productId, input.variantId, input.quantity);
  }
  updateQuantity(customerId: string, itemId: string, quantity: number) {
    return this.cartRepo.updateItemQuantity(customerId, itemId, quantity);
  }
  removeItem(customerId: string, itemId: string) {
    return this.cartRepo.removeItem(customerId, itemId);
  }
  clearCart(customerId: string) {
    return this.cartRepo.clearCart(customerId);
  }
  getWishlist(customerId: string) {
    return this.cartRepo.getWishlist(customerId);
  }
  toggleWishlist(customerId: string, productId: string) {
    return this.cartRepo.toggleWishlist(customerId, productId);
  }
}