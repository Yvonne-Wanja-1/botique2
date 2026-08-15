import type { Request, Response } from 'express';
import type { InstallmentService } from '../services/installmentService.js';
import { ok } from '../utils/apiResponse.js';
import { principalId } from '../middleware/authStub.js';

export function installmentController(installmentService: InstallmentService) {
  return {
    async createPlan(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      ok(res, await installmentService.createPlan(req.params.orderId, principal.userId, req.body.plans), 201);
    },
    async listPlans(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      ok(res, await installmentService.getByOrder(req.params.orderId, principal.userId, principal.role));
    },
    async payPayment(req: Request, res: Response): Promise<void> {
      const principal = req.principal!;
      ok(res, await installmentService.payPayment(req.params.paymentId, principal.userId, req.body.amount));
    },
  };
}