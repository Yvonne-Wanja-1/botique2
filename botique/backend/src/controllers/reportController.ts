import type { Request, Response } from 'express';
import type { ReportService } from '../services/reportService.js';
import { ok } from '../utils/apiResponse.js';

export function reportController(reportService: ReportService) {
  return {
    async salesSummary(req: Request, res: Response): Promise<void> {
      ok(
        res,
        await reportService.salesSummary(
          req.query.from ? String(req.query.from) : undefined,
          req.query.to ? String(req.query.to) : undefined,
        ),
      );
    },
    async topProducts(req: Request, res: Response): Promise<void> {
      ok(res, await reportService.topProducts(req.query.limit ? Number(req.query.limit) : 10));
    },
    async inventorySummary(_req: Request, res: Response): Promise<void> {
      ok(res, await reportService.inventorySummary());
    },
    async customerSummary(_req: Request, res: Response): Promise<void> {
      ok(res, await reportService.customerSummary());
    },
  };
}