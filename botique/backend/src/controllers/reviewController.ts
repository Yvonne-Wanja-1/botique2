import type { Request, Response } from 'express';
import type { ReviewService } from '../services/reviewService.js';
import { ok } from '../utils/apiResponse.js';
import { principalId } from '../middleware/authStub.js';

export function reviewController(reviewService: ReviewService) {
  return {
    async add(req: Request, res: Response): Promise<void> {
      ok(res, await reviewService.add(principalId(req), req.params.productId, req.body), 201);
    },
    async listForProduct(req: Request, res: Response): Promise<void> {
      ok(res, await reviewService.listForProduct(req.params.productId));
    },
    async listPending(_req: Request, res: Response): Promise<void> {
      ok(res, await reviewService.listPending());
    },
    async eligibility(req: Request, res: Response): Promise<void> {
      ok(res, await reviewService.getEligibility(principalId(req), req.params.productId));
    },
    async moderate(req: Request, res: Response): Promise<void> {
      ok(res, await reviewService.moderate(req.params.id, req.body.approved));
    },
    async report(req: Request, res: Response): Promise<void> {
      ok(res, await reviewService.report(req.params.id));
    },
  };
}