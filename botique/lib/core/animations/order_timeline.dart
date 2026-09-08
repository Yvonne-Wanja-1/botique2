import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../models/order.dart';
import 'qts_animation.dart';

/// Refined order-progress timeline: Pending → Paid → Processing → Ready →
/// Delivered. The connector fills up to the reached step with a smooth tween.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.status});

  final OrderStatus status;

  static const List<String> _steps = [
    'Pending',
    'Paid',
    'Processing',
    'Ready',
    'Delivered',
  ];

  int get _reached => switch (status) {
        OrderStatus.pending => 1,
        OrderStatus.paid => 2,
        OrderStatus.processing => 3,
        OrderStatus.ready => 4,
        OrderStatus.delivered => 5,
        OrderStatus.cancelled => 1,
      };

  @override
  Widget build(BuildContext context) {
    final cancelled = status == OrderStatus.cancelled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cancelled) ...[
          Row(
            children: [
              Icon(Icons.cancel, size: 18, color: QueensTouchColors.danger),
              const SizedBox(width: 6),
              const Text(
                'Order cancelled',
                style: TextStyle(
                  color: QueensTouchColors.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final stepWidth = constraints.maxWidth / _steps.length;
            return SizedBox(
              height: 64,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 14,
                    child: Container(
                      height: 3,
                      color: const Color(0xFFE8DED7),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 14,
                    width: (_reached - 1) / (_steps.length - 1) * constraints.maxWidth,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: QtMotion.normal,
                      curve: QtMotion.signature,
                      builder: (context, v, _) => FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: v,
                        child: Container(
                          height: 3,
                          color: QueensTouchColors.plum,
                        ),
                      ),
                    ),
                  ),
                  for (var i = 0; i < _steps.length; i++)
                    Positioned(
                      left: i * stepWidth,
                      width: stepWidth,
                      top: 4,
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: QtMotion.normal,
                            curve: QtMotion.signature,
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < _reached
                                  ? QueensTouchColors.plum
                                  : QueensTouchColors.surfaceLight,
                              border: Border.all(
                                color: i < _reached
                                    ? QueensTouchColors.plum
                                    : QueensTouchColors.surfaceBorder,
                                width: 2,
                              ),
                            ),
                            child: i < _reached
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _steps[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  i < _reached ? FontWeight.w700 : FontWeight.w500,
                              color: i < _reached
                                  ? QueensTouchColors.plum
                                  : QueensTouchColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Payment verification flow: Submitted → Pending verification → Verified,
/// with an explicit rejected state.
class PaymentStatusFlow extends StatelessWidget {
  const PaymentStatusFlow({super.key, required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final rejected = status == PaymentStatus.rejected;
    final verified =
        status == PaymentStatus.successful || status == PaymentStatus.refunded;
    final pending =
        status == PaymentStatus.pendingVerification || status == PaymentStatus.pending;

    if (rejected) {
      return Row(
        children: [
          Icon(Icons.cancel, size: 18, color: QueensTouchColors.danger),
          const SizedBox(width: 6),
          const Text(
            'Payment rejected',
            style: TextStyle(
              color: QueensTouchColors.danger,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    final steps = ['Submitted', 'Pending verification', 'Verified'];
    final reached = verified ? 3 : (pending ? 2 : 1);
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: i < reached ? QueensTouchColors.success : const Color(0xFFE8DED7),
              ),
            ),
          Column(
            children: [
              Icon(
                i < reached ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: i < reached ? QueensTouchColors.success : Colors.grey.shade400,
              ),
              const SizedBox(height: 2),
              Text(
                steps[i],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: i < reached ? FontWeight.w700 : FontWeight.w500,
                  color: i < reached ? QueensTouchColors.success : QueensTouchColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}