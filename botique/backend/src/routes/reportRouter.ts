import { Router } from 'express';
import { reportController } from '../controllers/reportController.js';
import { requireRole } from '../middleware/authStub.js';
import type { ReportService } from '../services/reportService.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const REPORT_ROLES = ['super_admin', 'store_manager', 'sales_staff', 'inventory_staff'] as const;

export function reportRouter(reportService: ReportService): Router {
  const router = Router();
  const c = reportController(reportService);

  router.get('/sales-summary', requireRole(...REPORT_ROLES), asyncHandler(c.salesSummary));
  router.get('/sales', requireRole(...REPORT_ROLES), asyncHandler(c.salesReport));
  router.get('/top-products', requireRole(...REPORT_ROLES), asyncHandler(c.topProducts));
  router.get('/inventory', requireRole(...REPORT_ROLES), asyncHandler(c.inventoryReport));
  router.get('/inventory-summary', requireRole(...REPORT_ROLES), asyncHandler(c.inventorySummary));
  router.get('/customer-summary', requireRole(...REPORT_ROLES), asyncHandler(c.customerSummary));
  router.get('/orders', requireRole(...REPORT_ROLES), asyncHandler(c.ordersSummary));
  router.get('/payments', requireRole(...REPORT_ROLES), asyncHandler(c.paymentsSummary));
  router.get('/installments', requireRole(...REPORT_ROLES), asyncHandler(c.installmentsSummary));

  return router;
}