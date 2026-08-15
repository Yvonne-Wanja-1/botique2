import type { Request, Response } from 'express';
import type { AuditService } from '../services/auditService.js';
import { ok } from '../utils/apiResponse.js';

export function auditController(auditService: AuditService) {
  return {
    async list(req: Request, res: Response): Promise<void> {
      ok(
        res,
        await auditService.list({
          resource: req.query.resource ? String(req.query.resource) : undefined,
          action: req.query.action ? String(req.query.action) : undefined,
          userId: req.query.userId ? String(req.query.userId) : undefined,
          page: req.query.page ? Number(req.query.page) : undefined,
          pageSize: req.query.pageSize ? Number(req.query.pageSize) : undefined,
        }),
      );
    },
  };
}