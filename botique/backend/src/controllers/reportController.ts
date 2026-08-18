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
    async salesReport(req: Request, res: Response): Promise<void> {
      ok(
        res,
        await reportService.salesReport(
          req.query.from ? String(req.query.from) : undefined,
          req.query.to ? String(req.query.to) : undefined,
          req.query.limit ? Number(req.query.limit) : undefined,
        ),
      );
    },
    async topProducts(req: Request, res: Response): Promise<void> {
      ok(
        res,
        await reportService.topProducts(
          req.query.from ? String(req.query.from) : undefined,
          req.query.to ? String(req.query.to) : undefined,
          req.query.limit ? Number(req.query.limit) : 10,
        ),
      );
    },
    async inventoryReport(_req: Request, res: Response): Promise<void> {
      ok(res, await reportService.inventoryReport());
    },
    async inventorySummary(_req: Request, res: Response): Promise<void> {
      ok(res, await reportService.inventorySummary());
    },
    async customerSummary(req: Request, res: Response): Promise<void> {
      ok(
        res,
        await reportService.customerSummary(
          req.query.from ? String(req.query.from) : undefined,
          req.query.to ? String(req.query.to) : undefined,
        ),
      );
    },
    async ordersSummary(req: Request, res: Response): Promise<void> {
      ok(
        res,
        await reportService.ordersSummary(
          req.query.from ? String(req.query.from) : undefined,
          req.query.to ? String(req.query.to) : undefined,
        ),
      );
    },
    async paymentsSummary(req: Request, res: Response): Promise<void> {
      ok(
        res,
        await reportService.paymentsSummary(
          req.query.from ? String(req.query.from) : undefined,
          req.query.to ? String(req.query.to) : undefined,
        ),
      );
    },
    async installmentsSummary(_req: Request, res: Response): Promise<void> {
      ok(res, await reportService.installmentsSummary());
    },
  };
}