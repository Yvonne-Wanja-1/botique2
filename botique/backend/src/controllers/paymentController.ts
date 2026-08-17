import type { Request, Response } from 'express';
import type { PaymentService } from '../services/paymentService.js';
import { ok } from '../utils/apiResponse.js';

export function paymentController(paymentService: PaymentService) {
  return {
    async submit(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      ok(res, await paymentService.submit(principal.userId, req.body), 201);
    },
    async list(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      const page = req.query.page ? Number(req.query.page) : undefined;
      const pageSize = req.query.pageSize ? Number(req.query.pageSize) : undefined;
      ok(res, await paymentService.list(principal.userId, principal.role, {
        status: req.query.status ? String(req.query.status) : undefined,
        page,
        pageSize,
      }));
    },
    async listForOrder(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      ok(res, await paymentService.listForOrder(req.params.orderId, principal.userId, principal.role));
    },
    async getById(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      ok(res, await paymentService.getById(req.params.id, principal.userId, principal.role));
    },
    async verify(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      ok(res, await paymentService.verify(req.params.id, principal.userId));
    },
    async reject(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      ok(res, await paymentService.reject(req.params.id, principal.userId, req.body.reason));
    },
    async transferDetails(_req: Request, res: Response): Promise<void> {
      ok(res, paymentService.transferDetails());
    },
  };
}