import { ConflictError } from '../utils/errors.js';
import type { InventoryRepository } from '../repositories/inventoryRepository.js';
import type { AuditService } from './auditService.js';

export class InventoryService {
  constructor(
    private inventoryRepo: InventoryRepository,
    private auditService: AuditService | null = null,
  ) {}

  listVariantInventory(stock?: 'low' | 'out' | 'all') {
    return this.inventoryRepo.listVariantInventory(stock);
  }

  async adjust(
    variantId: string,
    input: { quantity: number; reason: string; changeType: 'add' | 'reduce' | 'adjust' | 'purchase' },
    staffUserId: string | null,
  ) {
    const result = await this.inventoryRepo.adjust(variantId, input.quantity, input.reason, input.changeType, staffUserId);
    if (!result) throw new ConflictError('Insufficient stock for adjustment');
    if (this.auditService) {
      await this.auditService.log({
        actorUserId: staffUserId,
        action: 'adjust',
        resource: 'inventory.variant',
        resourceId: variantId,
        description: `Inventory adjusted by ${input.quantity} (${input.changeType}): ${input.reason}`,
        previousValue: { stock_qty: result.previousQuantity },
        newValue: { stock_qty: result.newQuantity },
      });
    }
    return result;
  }
}