import type { Request, Response } from 'express';
import type { UserService } from '../services/userService.js';
import { ok } from '../utils/apiResponse.js';

export function userController(userService: UserService) {
  return {
    async list(req: Request, res: Response): Promise<void> {
      ok(
        res,
        await userService.list({
          role: req.query.role ? String(req.query.role) : undefined,
          search: req.query.search ? String(req.query.search) : undefined,
          page: req.query.page ? Number(req.query.page) : undefined,
          pageSize: req.query.pageSize ? Number(req.query.pageSize) : undefined,
        }),
      );
    },
    async create(req: Request, res: Response): Promise<void> {
      ok(res, await userService.create(req.body), 201);
    },
    async setRole(req: Request, res: Response): Promise<void> {
      ok(res, await userService.setRole(req.params.id, req.body.role));
    },
    async setActive(req: Request, res: Response): Promise<void> {
      ok(res, await userService.setActive(req.params.id, req.body.isActive));
    },
  };
}