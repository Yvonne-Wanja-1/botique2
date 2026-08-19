import 'package:flutter/material.dart';

import 'qts_animation.dart';

/// One-shot staggered entrance: fades in and slides up, with an optional
/// per-index stagger delay (capped so long grids stay snappy). Runs once on
/// first build.
class StaggerReveal extends StatefulWidget {
  const StaggerReveal({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = const Offset(0, 16),
  });

  final Widget child;
  final int index;
  final Offset offset;

  @override
  State<StaggerReveal> createState() => _StaggerRevealState();
}

class _StaggerRevealState extends State<StaggerReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: QtMotion.normal);
    final curve = CurvedAnimation(parent: _controller, curve: QtMotion.signature);
    _opacity = curve;
    _slide = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(curve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (QtMotion.reduceMotion(context)) {
      _controller.value = 1.0;
    } else {
      Future<void>.delayed(Duration(milliseconds: widget.index.clamp(0, 8) * 70), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _slide, child: widget.child),
      ),
    );
  }
}
