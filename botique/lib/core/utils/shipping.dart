/// Flat delivery fee shared by the UI and matching the backend constant in
/// `backend/src/repositories/orderRepository.ts` (DELIVERY_FEE).
const double kDeliveryFee = 200;

enum DeliveryMethod { pickup, delivery }

double shippingFor(double subtotal, {DeliveryMethod method = DeliveryMethod.delivery}) =>
    method == DeliveryMethod.delivery ? kDeliveryFee : 0;
