import type { Request, Response } from 'express';
import type { CustomerService } from '../services/customerService.js';
import { ok } from '../utils/apiResponse.js';
import { principalId } from '../middleware/authStub.js';

export function customerController(customerService: CustomerService) {
  return {
    async getMe(req: Request, res: Response): Promise<void> {
      ok(res, await customerService.getProfile(principalId(req)));
    },
    async getMeOrders(req: Request, res: Response): Promise<void> {
      ok(res, await customerService.getOrders(principalId(req)));
    },
    async getMeAddresses(req: Request, res: Response): Promise<void> {
      ok(res, await customerService.getAddresses(principalId(req)));
    },
    async addMeAddress(req: Request, res: Response): Promise<void> {
      ok(res, await customerService.addAddress(principalId(req), req.body), 201);
    },
    async setDefaultAddress(req: Request, res: Response): Promise<void> {
      ok(res, await customerService.setDefaultAddress(principalId(req), req.params.id));
    },
    async list(req: Request, res: Response): Promise<void> {
      ok(
        res,
        await customerService.listStaff({
          search: req.query.search ? String(req.query.search) : undefined,
          page: req.query.page ? Number(req.query.page) : undefined,
          pageSize: req.query.pageSize ? Number(req.query.pageSize) : undefined,
        }),
      );
    },
  };
}