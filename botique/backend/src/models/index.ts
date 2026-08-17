export type Role = 'super_admin' | 'store_manager' | 'sales_staff' | 'inventory_staff' | 'customer';
export const ROLES: Role[] = ['super_admin', 'store_manager', 'sales_staff', 'inventory_staff', 'customer'];

export interface User {
  id: string;
  email: string;
  phone: string;
  fullName: string;
  role: Role;
  passwordHash: string | null;
  avatarUrl: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export type CategoryStatus = 'active' | 'inactive';
export interface Category {
  id: string;
  parentId: string | null;
  name: string;
  slug: string;
  description: string | null;
  imageUrl: string | null;
  isActive: boolean;
}

export interface Brand {
  id: string;
  name: string;
  slug: string;
  logoUrl: string | null;
  isActive: boolean;
}

export type ProductStatus = 'active' | 'inactive' | 'discontinued';
export interface ProductVariant {
  id: string;
  productId: string;
  sku: string;
  size: string | null;
  color: string | null;
  shade: string | null;
  price: number | null;
  stockQty: number;
  isActive: boolean;
}
export interface Product {
  id: string;
  name: string;
  slug: string;
  description: string;
  categoryId: string;
  brandId: string;
  basePrice: number;
  discountPrice: number | null;
  stockThreshold: number;
  status: ProductStatus;
  rating: number;
  reviewCount: number;
  soldCount: number;
  viewCount: number;
  isFeatured: boolean;
  isNewArrival: boolean;
  isBestSeller: boolean;
  isTrending: boolean;
  specifications: Record<string, string>;
  variants: ProductVariant[];
  images: string[];
  createdAt: string;
  updatedAt: string;
}
export type ProductRow = Omit<Product, 'variants' | 'images' | 'specifications' | 'categoryId' | 'brandId' | 'basePrice' | 'discountPrice' | 'stockThreshold' | 'rating' | 'reviewCount' | 'soldCount' | 'viewCount' | 'isFeatured' | 'isNewArrival' | 'isBestSeller' | 'isTrending' | 'createdAt' | 'updatedAt'> & {
  category_id: string;
  brand_id: string;
  base_price: string;
  discount_price: string | null;
  stock_threshold: string;
  rating: string;
  review_count: string;
  sold_count: string;
  view_count: string;
  is_featured: boolean;
  is_new_arrival: boolean;
  is_best_seller: boolean;
  is_trending: boolean;
  specifications: string;
  created_at: string;
  updated_at: string;
};

export interface ProductImage {
  id: string;
  productId: string;
  url: string;
  position: number;
  isPrimary: boolean;
}

export type OrderStatus = 'pending' | 'paid' | 'processing' | 'ready' | 'delivered' | 'cancelled';
export type PaymentStatus = 'pending' | 'successful' | 'failed' | 'refunded';
export type PaymentMethod = 'cash_on_delivery' | 'bank_transfer' | 'card' | 'installment';
export type InstallmentStatus = 'pending_approval' | 'approved' | 'active' | 'completed' | 'rejected' | 'overdue';

export const ORDER_STATUS_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  pending: ['paid', 'cancelled'],
  paid: ['processing', 'cancelled'],
  processing: ['ready', 'cancelled'],
  ready: ['delivered'],
  delivered: [],
  cancelled: [],
};
export const PAYMENT_STATUS_TRANSITIONS: Record<PaymentStatus, PaymentStatus[]> = {
  pending: ['successful', 'failed'],
  successful: ['refunded'],
  failed: ['pending'],
  refunded: [],
};
export const INSTALLMENT_STATUS_TRANSITIONS: Record<InstallmentStatus, InstallmentStatus[]> = {
  pending_approval: ['approved', 'rejected'],
  approved: ['active'],
  active: ['completed'],
  completed: [],
  rejected: [],
  overdue: ['active', 'completed'],
};

export interface OrderItemInput {
  productId: string;
  variantId: string | null;
  quantity: number;
}
export interface OrderRow {
  id: string;
  orderNumber: string;
  customerId: string;
  customerName: string;
  customerPhone: string;
  customerEmail: string;
  shippingAddress: string;
  subtotal: number;
  discount: number;
  shippingFee: number;
  total: number;
  status: OrderStatus;
  paymentStatus: PaymentStatus;
  paymentMethod: PaymentMethod;
  installmentRequested: boolean;
  promotionCode: string | null;
  createdAt: string;
}
export interface OrderItemRow {
  id: string;
  orderId: string;
  productId: string;
  variantId: string | null;
  productName: string;
  variantLabel: string | null;
  unitPrice: number;
  quantity: number;
  lineTotal: number;
}

export type PromotionType = 'percentage' | 'fixed';
export interface Promotion {
  id: string;
  code: string;
  title: string;
  type: PromotionType;
  value: number;
  categoryId: string | null;
  productId: string | null;
  minimumOrderAmount: number | null;
  maximumDiscount: number | null;
  usageLimit: number | null;
  usageCount: number;
  startDate: string | null;
  endDate: string | null;
  isActive: boolean;
}

export interface CartRow {
  id: string;
  userId: string;
}
export interface CartItemRow {
  id: string;
  cartId: string;
  productId: string;
  variantId: string | null;
  quantity: number;
}

export type NotificationType = 'account' | 'order' | 'payment' | 'installment' | 'promotion' | 'announcement';
export interface NotificationRow {
  id: string;
  userId: string | null;
  type: NotificationType;
  title: string;
  body: string;
  isRead: boolean;
  createdAt: string;
}

export type AuditAction = 'create' | 'update' | 'delete' | 'approve' | 'reject' | 'adjust' | 'login' | 'logout';
export interface AuditLogRow {
  id: string;
  actorUserId: string | null;
  actorName: string;
  action: AuditAction;
  resource: string;
  resourceId: string | null;
  description: string;
  previousValue: unknown | null;
  newValue: unknown | null;
  createdAt: string;
}

export type InventoryChangeType = 'add' | 'reduce' | 'adjust' | 'purchase' | 'order';
export interface InventoryTransactionRow {
  id: string;
  variantId: string;
  productId: string;
  changeType: InventoryChangeType;
  quantityChange: number;
  previousQuantity: number;
  newQuantity: number;
  reason: string;
  staffUserId: string | null;
  orderId: string | null;
  createdAt: string;
}

export interface ReviewRow {
  id: string;
  productId: string;
  customerId: string;
  rating: number;
  comment: string;
  isVerifiedPurchase: boolean;
  isApproved: boolean;
  isReported: boolean;
  createdAt: string;
}

export function normalizePercent(value: number): number {
  return Math.min(100, Math.max(0, value));
}

export function toNumber(value: unknown): number {
  const n = typeof value === 'number' ? value : Number(value);
  return Number.isFinite(n) ? n : 0;
}

export function assertTransition<T extends string>(
  transitions: Record<T, T[]>,
  current: T,
  next: T,
  label: string,
): void {
  if (!transitions[current]?.includes(next)) {
    const error = new Error(`Invalid ${label} transition: ${current} -> ${next}`);
    (error as Error & { statusCode?: number }).statusCode = 409;
    throw error;
  }
}