import { Router } from 'express';
import { reportController } from '../controllers/reportController.js';
import { requireRole } from '../middleware/authStub.js';
import type { ReportService } from '../services/reportService.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export function reportRouter(reportService: ReportService): Router {
  const router = Router();
  const c = reportController(reportService);

  router.get('/sales-summary', requireRole('super_admin', 'store_manager'), asyncHandler(c.salesSummary));
  router.get('/top-products', requireRole('super_admin', 'store_manager'), asyncHandler(c.topProducts));
  router.get('/inventory-summary', requireRole('super_admin', 'store_manager'), asyncHandler(c.inventorySummary));
  router.get('/customer-summary', requireRole('super_admin', 'store_manager'), asyncHandler(c.customerSummary));

  return router;
}