import 'dart:math';

import 'package:flutter/material.dart';

import 'qts_animation.dart';

/// Delicate, low-density floating particles for perfume presentation.
/// Subtle by design; disabled under reduced motion.
class MistParticles extends StatefulWidget {
  const MistParticles({
    super.key,
    this.particleCount = 7,
    this.color = Colors.white,
  });

  final int particleCount;
  final Color color;

  @override
  State<MistParticles> createState() => _MistParticlesState();
}

class _MistParticlesState extends State<MistParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    final random = Random();
    _particles = [
      for (var i = 0; i < widget.particleCount; i++)
        _Particle(
          x: random.nextDouble(),
          baseY: random.nextDouble(),
          size: 2 + random.nextDouble() * 4,
          speed: 0.4 + random.nextDouble() * 0.6,
          opacity: 0.12 + random.nextDouble() * 0.18,
        ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (QtMotion.reduceMotion(context)) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final size = MediaQuery.sizeOf(context);
        return Stack(
          children: [
            for (final p in _particles)
              Positioned(
                left: p.x * size.width,
                top: ((p.baseY - _controller.value * p.speed) % 1.0) * size.height,
                child: Opacity(
                  opacity: p.opacity,
                  child: Container(
                    width: p.size,
                    height: p.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Particle {
  const _Particle({
    required this.x,
    required this.baseY,
    required this.size,
    required this.speed,
    required this.opacity,
  });

  final double x;
  final double baseY;
  final double size;
  final double speed;
  final double opacity;
}
