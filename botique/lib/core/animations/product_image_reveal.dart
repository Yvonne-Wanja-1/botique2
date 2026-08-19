import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/utils/image_url.dart';
import 'mist_particles.dart';
import 'product_presentation.dart';
import 'qts_animation.dart';

/// Renders a product image with premium loading / loaded / error / empty
/// states and a category-aware presentation overlay. The uploaded image file
/// is never modified.
class ProductImageReveal extends StatefulWidget {
  const ProductImageReveal({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.heroTag,
    this.presentation = ProductPresentation.generic,
    this.semanticLabel,
    this.cacheWidth,
  });

  final String imageUrl;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Object? heroTag;
  final ProductPresentation presentation;
  final String? semanticLabel;
  final int? cacheWidth;

  @override
  State<ProductImageReveal> createState() => _ProductImageRevealState();
}

class _ProductImageRevealState extends State<ProductImageReveal> {
  bool _loaded = false;

  @override
  void didUpdateWidget(covariant ProductImageReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) _loaded = false;
  }

  void _markLoaded() {
    if (mounted && !_loaded) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(16);
    final surface = ClipRRect(
      borderRadius: radius,
      child: _buildSurface(context),
    );
    final reveal = AnimatedScale(
      scale: _loaded ? 1.0 : 0.985,
      duration: QtMotion.normal,
      curve: QtMotion.signature,
      child: surface,
    );
    return Semantics(
      image: true,
      label: widget.semanticLabel,
      child: widget.heroTag != null
          ? Hero(tag: widget.heroTag!, child: reveal)
          : reveal,
    );
  }

  Widget _buildSurface(BuildContext context) {
    final url = widget.imageUrl.trim();
    if (url.isEmpty) return _PlaceholderSurface(icon: Icons.checkroom);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          resolveImageUrl(url),
          fit: widget.fit,
          cacheWidth: widget.cacheWidth,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _markLoaded());
              return child;
            }
            if (frame == null) {
              return const _SkeletonSurface();
            }
            WidgetsBinding.instance.addPostFrameCallback((_) => _markLoaded());
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: QtMotion.normal,
              curve: QtMotion.signature,
              builder: (context, v, c) => Opacity(opacity: v, child: c),
              child: child,
            );
          },
          loadingBuilder: (context, child, event) {
            if (event == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _markLoaded());
              return child;
            }
            return const _SkeletonSurface();
          },
          errorBuilder: (context, error, stackTrace) =>
              const _PlaceholderSurface(icon: Icons.broken_image),
        ),
        if (!QtMotion.reduceMotion(context) && _loaded)
          IgnorePointer(child: _PresentationOverlay(presentation: widget.presentation)),
      ],
    );
  }
}

/// Static elegant skeleton surface (no infinite animation — test-safe).
class _SkeletonSurface extends StatelessWidget {
  const _SkeletonSurface();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [QueensTouchColors.blushLight, QueensTouchColors.blush],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.spa_outlined,
          size: 28,
          color: QueensTouchColors.plumLight,
        ),
      ),
    );
  }
}

class _PlaceholderSurface extends StatelessWidget {
  const _PlaceholderSurface({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [QueensTouchColors.blushLight, QueensTouchColors.blush],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: QueensTouchColors.plumLight),
            const SizedBox(height: 6),
            const Text(
              'QUEENS\' TOUCH',
              style: TextStyle(
                color: QueensTouchColors.plumLight,
                fontSize: 9,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category-aware presentation overlay layered over the loaded image.
class _PresentationOverlay extends StatelessWidget {
  const _PresentationOverlay({required this.presentation});

  final ProductPresentation presentation;

  @override
  Widget build(BuildContext context) {
    switch (presentation) {
      case ProductPresentation.perfume:
        return const MistParticles();
      case ProductPresentation.fashion:
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: -1.0, end: 1.0),
          duration: QtMotion.slow,
          curve: QtMotion.signatureInOut,
          builder: (context, v, c) => FractionalTranslation(
            translation: Offset(v, 0),
            child: c,
          ),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.white, Colors.transparent],
                stops: [0.35, 0.5, 0.65],
              ),
            ),
          ),
        );
      default:
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: QtMotion.slow,
          curve: QtMotion.signature,
          builder: (context, v, _) => DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.2, -0.4),
                radius: 0.9,
                colors: [
                  QueensTouchColors.goldLight.withValues(alpha: 0.28 * v),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
    }
  }
}
