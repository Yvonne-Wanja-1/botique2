import type { Request, Response } from 'express';
import type { PaymentService } from '../services/paymentService.js';
import { ok } from '../utils/apiResponse.js';

export function paymentController(paymentService: PaymentService) {
  return {
    async get(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      ok(res, await paymentService.getByOrder(req.params.orderId, principal.userId, principal.role));
    },
    async verify(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      ok(res, await paymentService.verify(req.params.orderId, req.body.reference, principal.userId, principal.role));
    },
    async transferDetails(_req: Request, res: Response): Promise<void> {
      ok(res, paymentService.transferDetails());
    },
  };
}