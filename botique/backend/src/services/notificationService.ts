import type { NotificationRepository } from '../repositories/notificationRepository.js';
import type { NotificationType } from '../models/index.js';

export class NotificationService {
  constructor(private notificationRepo: NotificationRepository) {}

  listForUser(userId: string, unreadOnly?: boolean) {
    return this.notificationRepo.listForUser(userId, unreadOnly);
  }

  markRead(userId: string, id: string) {
    return this.notificationRepo.markRead(userId, id);
  }

  markAllRead(userId: string) {
    return this.notificationRepo.markAllRead(userId);
  }

  create(input: { userId?: string | null; title: string; body: string; type: NotificationType }) {
    return this.notificationRepo.create(input);
  }
}