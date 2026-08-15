import type { Request, Response } from 'express';
import type { OrderService } from '../services/orderService.js';
import { ok } from '../utils/apiResponse.js';
import { principalId } from '../middleware/authStub.js';

export function orderController(orderService: OrderService) {
  return {
    async list(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      const status = req.query.status ? String(req.query.status) : undefined;
      if (principal.role === 'customer') {
        ok(res, await orderService.listForCustomer(principal.userId, status));
      } else {
        ok(res, await orderService.listForStaff({
          status,
          page: req.query.page ? Number(req.query.page) : undefined,
          pageSize: req.query.pageSize ? Number(req.query.pageSize) : undefined,
        }));
      }
    },
    async create(req: Request, res: Response): Promise<void> {
      ok(res, await orderService.create(principalId(req), req.body), 201);
    },
    async get(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      ok(res, await orderService.getById(req.params.id, principal.userId, principal.role));
    },
    async cancel(req: Request, res: Response): Promise<void> {
      ok(res, await orderService.cancel(principalId(req), req.params.id));
    },
    async updateStatus(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      ok(res, await orderService.updateStatus(req.params.id, req.body.status, principal.userId));
    },
  };
}