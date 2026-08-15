import type { Request, Response } from 'express';
import type { CartService } from '../services/cartService.js';
import { ok } from '../utils/apiResponse.js';
import { principalId } from '../middleware/authStub.js';

export function cartController(cartService: CartService) {
  return {
    async getCart(req: Request, res: Response): Promise<void> {
      ok(res, await cartService.getCart(principalId(req)));
    },
    async addItem(req: Request, res: Response): Promise<void> {
      ok(res, await cartService.addToCart(principalId(req), req.body), 201);
    },
    async updateQuantity(req: Request, res: Response): Promise<void> {
      ok(res, await cartService.updateQuantity(principalId(req), req.params.itemId, req.body.quantity));
    },
    async removeItem(req: Request, res: Response): Promise<void> {
      ok(res, await cartService.removeItem(principalId(req), req.params.itemId));
    },
    async clearCart(req: Request, res: Response): Promise<void> {
      await cartService.clearCart(principalId(req));
      ok(res, { cleared: true });
    },
    async getWishlist(req: Request, res: Response): Promise<void> {
      ok(res, await cartService.getWishlist(principalId(req)));
    },
    async toggleWishlist(req: Request, res: Response): Promise<void> {
      ok(res, await cartService.toggleWishlist(principalId(req), req.params.productId));
    },
  };
}