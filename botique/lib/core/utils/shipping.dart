/// Delivery fee rules shared by the UI and matching the backend constants in
/// `backend/src/repositories/orderRepository.ts` (DELIVERY_FEE / FREE_DELIVERY_THRESHOLD).
const double kDeliveryFee = 2500;
const double kFreeDeliveryThreshold = 100000;

double shippingFor(double subtotal) =>
    subtotal >= kFreeDeliveryThreshold ? 0 : kDeliveryFee;