import type { AuditRepository } from '../repositories/auditRepository.js';

export class AuditService {
  constructor(private auditRepo: AuditRepository) {}

  log(input: Parameters<AuditRepository['log']>[0]) {
    return this.auditRepo.log(input);
  }

  list(params: Parameters<AuditRepository['list']>[0]) {
    return this.auditRepo.list(params);
  }
}