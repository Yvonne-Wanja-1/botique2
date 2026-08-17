import cors from 'cors';
import express from 'express';
import { mkdirSync } from 'node:fs';
import { resolve } from 'node:path';
import type { Pool } from 'pg';
import { authStub } from './middleware/authStub.js';
import { errorHandler } from './middleware/errorHandler.js';
import { requestLogger } from './middleware/requestLogger.js';
import { healthRouter } from './routes/healthRouter.js';
import { ProductRepository } from './repositories/productRepository.js';
import { ProductService } from './services/productService.js';
import { productRouter } from './routes/productRouter.js';
import { BrandRepository, CategoryRepository } from './repositories/catalogRepository.js';
import { CatalogService } from './services/catalogService.js';
import { catalogRouter } from './routes/catalogRouter.js';
import { InventoryRepository } from './repositories/inventoryRepository.js';
import { InventoryService } from './services/inventoryService.js';
import { inventoryRouter } from './routes/inventoryRouter.js';
import { CartRepository } from './repositories/cartRepository.js';
import { CartService } from './services/cartService.js';
import { cartRouter } from './routes/cartRouter.js';
import { OrderRepository } from './repositories/orderRepository.js';
import { OrderService } from './services/orderService.js';
import { orderRouter } from './routes/orderRouter.js';
import { PaymentRepository } from './repositories/paymentRepository.js';
import { PaymentService } from './services/paymentService.js';
import { paymentRouter } from './routes/paymentRouter.js';
import { InstallmentRepository } from './repositories/installmentRepository.js';
import { InstallmentService } from './services/installmentService.js';
import { installmentRouter } from './routes/installmentRouter.js';
import { ReviewRepository } from './repositories/reviewRepository.js';
import { ReviewService } from './services/reviewService.js';
import { reviewRouter } from './routes/reviewRouter.js';
import { CustomerRepository } from './repositories/customerRepository.js';
import { CustomerService } from './services/customerService.js';
import { customerRouter } from './routes/customerRouter.js';
import { UserRepository } from './repositories/userRepository.js';
import { UserService } from './services/userService.js';
import { userRouter } from './routes/userRouter.js';
import { NotificationRepository } from './repositories/notificationRepository.js';
import { NotificationService } from './services/notificationService.js';
import { notificationRouter } from './routes/notificationRouter.js';
import { ReportService } from './services/reportService.js';
import { reportRouter } from './routes/reportRouter.js';
import { AuditRepository } from './repositories/auditRepository.js';
import { AuditService } from './services/auditService.js';
import { auditRouter } from './routes/auditRouter.js';

export function createApp(pool: Pool, options: { uploadsDir?: string } = {}): express.Express {
  const app = express();
  app.use(cors());
  app.use(express.json());
  app.use(requestLogger);

  const uploadsDir = resolve(process.cwd(), options.uploadsDir ?? 'uploads');
  mkdirSync(uploadsDir, { recursive: true });
  app.use('/images', express.static(uploadsDir));

  app.use('/health', healthRouter(pool));

  app.use('/api', authStub);

  const productRepo = new ProductRepository(pool);
  const productService = new ProductService(productRepo);
  app.use('/api/products', productRouter(productService, { uploadsDir }));

  const categoryRepo = new CategoryRepository(pool);
  const brandRepo = new BrandRepository(pool);
  const catalogService = new CatalogService(categoryRepo, brandRepo);
  app.use('/api', catalogRouter(catalogService));

  const auditRepo = new AuditRepository(pool);
  const auditService = new AuditService(auditRepo);
  app.use('/api/audit-logs', auditRouter(auditService));

  const inventoryRepo = new InventoryRepository(pool);
  const inventoryService = new InventoryService(inventoryRepo, auditService);
  app.use('/api/inventory', inventoryRouter(inventoryService));

  const cartRepo = new CartRepository(pool);
  const cartService = new CartService(cartRepo);
  app.use('/api/cart', cartRouter(cartService));

  const orderRepo = new OrderRepository(pool);
  const orderService = new OrderService(orderRepo);
  app.use('/api/orders', orderRouter(orderService));

  const paymentRepo = new PaymentRepository(pool);
  const paymentService = new PaymentService(paymentRepo);
  app.use('/api/payments', paymentRouter(paymentService));

  const installmentRepo = new InstallmentRepository(pool);
  const installmentService = new InstallmentService(installmentRepo);
  app.use('/api/installments', installmentRouter(installmentService));

  const reviewRepo = new ReviewRepository(pool);
  const reviewService = new ReviewService(reviewRepo);
  app.use('/api/reviews', reviewRouter(reviewService));

  const customerRepo = new CustomerRepository(pool);
  const customerService = new CustomerService(customerRepo, orderRepo);
  app.use('/api/customers', customerRouter(customerService));

  const userRepo = new UserRepository(pool);
  const userService = new UserService(userRepo);
  app.use('/api/users', userRouter(userService));

  const notificationRepo = new NotificationRepository(pool);
  const notificationService = new NotificationService(notificationRepo);
  app.use('/api/notifications', notificationRouter(notificationService));

  const reportService = new ReportService(pool);
  app.use('/api/reports', reportRouter(reportService));

  app.use((_req, res) => {
    res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'Route not found' } });
  });
  app.use(errorHandler);
  return app;
}