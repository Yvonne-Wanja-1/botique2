import { z } from 'zod';

const uuid = z.string().uuid();
const money = z.number().finite().nonnegative();
const positiveInt = z.number().int().positive();
const nonNegativeInt = z.number().int().nonnegative();

export const variantSchema = z
  .object({
    sku: z.string().min(1),
    size: z.string().optional().nullable(),
    color: z.string().optional().nullable(),
    shade: z.string().optional().nullable(),
    price: money.optional().nullable(),
    stockQty: nonNegativeInt.default(0),
  })
  .refine((v) => v.size || v.color || v.shade, { message: 'variant needs size, color, or shade' });

export const productObjectSchema = z.object({
  name: z.string().min(1).max(200),
  slug: z.string().min(1).max(200),
  description: z.string().default(''),
  categoryId: uuid,
  brandId: uuid,
  basePrice: money,
  discountPrice: money.nullable().optional(),
  stockThreshold: nonNegativeInt.default(5),
  isFeatured: z.boolean().default(false),
  isNewArrival: z.boolean().default(false),
  isBestSeller: z.boolean().default(false),
  isTrending: z.boolean().default(false),
  specifications: z.record(z.string(), z.string()).default({}),
  variants: z.array(variantSchema).default([]),
});

export const productSchema = productObjectSchema.refine(
  (p) => p.discountPrice === null || p.discountPrice === undefined || p.discountPrice < p.basePrice,
  { message: 'discountPrice must be less than basePrice' },
);

export const categorySchema = z.object({
  name: z.string().min(1).max(200),
  slug: z.string().min(1).max(200),
  parentId: uuid.nullable().optional(),
  description: z.string().optional().nullable(),
  imageUrl: z.string().optional().nullable(),
});

export const productImageUpdateSchema = z.object({
  isPrimary: z.boolean(),
});

export const brandSchema = z.object({
  name: z.string().min(1).max(200),
  slug: z.string().min(1).max(200),
  logoUrl: z.string().optional().nullable(),
});

export const cartItemSchema = z.object({
  productId: uuid,
  variantId: uuid.nullable().optional(),
  quantity: positiveInt,
});

export const cartQuantitySchema = z.object({ quantity: positiveInt });

export const wishlistItemSchema = z.object({
  productId: uuid,
});

export const placeOrderSchema = z.object({
  customerName: z.string().min(1),
  customerPhone: z.string().min(1),
  customerEmail: z.string().email(),
  shippingAddress: z.string().min(1),
  paymentMethod: z.enum(['cash_on_delivery', 'bank_transfer', 'paybill', 'card', 'installment']),
  promotionCode: z.string().optional().nullable(),
  installmentRequested: z.boolean().default(false),
  confirmationMessage: z.string().optional().nullable(),
  items: z
    .array(z.object({ productId: uuid, variantId: uuid.nullable(), quantity: positiveInt }))
    .min(1),
});

export const orderStatusSchema = z.object({
  status: z.enum(['pending', 'paid', 'processing', 'ready', 'delivered', 'cancelled']),
});

export const adjustInventorySchema = z.object({
  quantity: z.number().int().refine((n) => n !== 0, { message: 'quantity cannot be zero' }),
  reason: z.string().min(1),
  changeType: z.enum(['add', 'reduce', 'adjust', 'purchase']).default('adjust'),
});

export const reviewSchema = z.object({
  productId: uuid,
  orderId: uuid.nullable().optional(),
  rating: z.number().min(1).max(5),
  comment: z.string().default(''),
});

export const reviewCreateSchema = z.object({
  rating: z.number().int().min(1).max(5),
  comment: z.string().min(1),
});

export const reviewModerateSchema = z.object({
  approved: z.boolean(),
});

export const promotionSchema = z
  .object({
    code: z.string().min(1).max(50),
    title: z.string().min(1),
    type: z.enum(['percentage', 'fixed']),
    value: money,
    categoryId: uuid.nullable().optional(),
    productId: uuid.nullable().optional(),
    minimumOrderAmount: money.nullable().optional(),
    maximumDiscount: money.nullable().optional(),
    usageLimit: positiveInt.nullable().optional(),
    startDate: z.string().nullable().optional(),
    endDate: z.string().nullable().optional(),
    isActive: z.boolean().default(true),
  })
  .refine((p) => !(p.type === 'percentage' && p.value > 100), { message: 'percentage value cannot exceed 100' })
  .refine((p) => !(p.type === 'fixed' && p.value <= 0), { message: 'fixed value must be positive' });

export const notificationSchema = z.object({
  type: z.enum(['account', 'order', 'payment', 'installment', 'promotion', 'announcement']),
  userId: uuid.nullable().optional(),
  title: z.string().min(1),
  body: z.string().min(1),
});

export const staffSchema = z.object({
  email: z.string().email(),
  phone: z.string().min(1),
  fullName: z.string().min(1),
  role: z.enum(['super_admin', 'store_manager', 'sales_staff', 'inventory_staff']),
});

// Public self-registration. Strict mode rejects any unknown field (e.g. a
// client-supplied `role`) so a public user can never select a privileged role.
export const registerSchema = z
  .object({
    fullName: z.string().min(1).max(200),
    email: z.string().email(),
    phone: z.string().min(1).max(50),
    password: z.string().min(8, 'Password must be at least 8 characters').max(128),
  })
  .strict();

export const loginSchema = z
  .object({
    email: z.string().email(),
    password: z.string().min(1),
  })
  .strict();

export const staffCreateSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  fullName: z.string().min(1),
  phone: z.string().min(1),
  role: z.enum(['super_admin', 'store_manager', 'sales_staff', 'inventory_staff']),
});

export const roleUpdateSchema = z.object({
  role: z.enum(['super_admin', 'store_manager', 'sales_staff', 'inventory_staff']),
});

export const userActiveSchema = z.object({
  isActive: z.boolean(),
});

export const customerUpdateSchema = z.object({
  phone: z.string().min(1).optional(),
  fullName: z.string().min(1).optional(),
});

export const addressSchema = z.object({
  label: z.string().default('Home'),
  fullName: z.string().min(1),
  phone: z.string().min(1),
  street: z.string().min(1),
  city: z.string().min(1),
  state: z.string().min(1),
  isDefault: z.boolean().default(false),
});

export const installmentActionSchema = z.object({
  approvedBy: uuid.optional(),
});

export const installmentPlanSchema = z.object({
  plans: z.number().int().min(2).max(12),
});

export const installmentPaySchema = z.object({
  amount: z.number().positive(),
});

export const paymentSubmitSchema = z.object({
  orderId: uuid,
  amount: z.number().positive(),
  paymentDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'paymentDate must be YYYY-MM-DD'),
  reference: z.string().optional().nullable(),
  confirmationMessage: z.string().min(1),
  note: z.string().optional().nullable(),
});

export const paymentRejectSchema = z.object({
  reason: z.string().min(1),
});

export const notificationCreateSchema = z.object({
  userId: uuid.nullable().optional(),
  title: z.string().min(1),
  body: z.string().min(1),
  type: z.enum(['account', 'order', 'payment', 'installment', 'promotion', 'announcement']),
});