/// Flat delivery fee shared by the UI and matching the backend constant in
/// `backend/src/repositories/orderRepository.ts` (DELIVERY_FEE).
const double kDeliveryFee = 200;

double shippingFor(double subtotal) => kDeliveryFee;