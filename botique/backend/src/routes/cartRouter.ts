import { Router } from 'express';
import { cartController } from '../controllers/cartController.js';
import { anyAuthenticated } from '../middleware/authStub.js';
import { validateBody } from '../middleware/validate.js';
import { cartItemSchema, cartQuantitySchema } from '../validation/schemas.js';
import type { CartService } from '../services/cartService.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export function cartRouter(cartService: CartService): Router {
  const router = Router();
  const c = cartController(cartService);

  router.get('/', anyAuthenticated, asyncHandler(c.getCart));
  router.post('/items', anyAuthenticated, validateBody(cartItemSchema), asyncHandler(c.addItem));
  router.patch('/items/:itemId', anyAuthenticated, validateBody(cartQuantitySchema), asyncHandler(c.updateQuantity));
  router.delete('/items/:itemId', anyAuthenticated, asyncHandler(c.removeItem));
  router.delete('/', anyAuthenticated, asyncHandler(c.clearCart));

  router.get('/wishlist', anyAuthenticated, asyncHandler(c.getWishlist));
  router.post('/wishlist/:productId', anyAuthenticated, asyncHandler(c.toggleWishlist));
  router.delete('/wishlist/:productId', anyAuthenticated, asyncHandler(c.toggleWishlist));

  return router;
}