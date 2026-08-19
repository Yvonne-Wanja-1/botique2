# Queens' Touch Premium Brand Experience — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the Queens' Touch Flutter boutique into a premium fashion + beauty editorial experience with signature, category-aware animations that work on dynamically uploaded product images.

**Architecture:** A reusable `lib/core/animations/` module (presentation classifier + small brand animation widgets) integrated into existing screens, driven by Flutter's built-in animation APIs. One minimal additive backend change exposes the category slug on product payloads so the classifier works for any current or future admin-uploaded product. One new dependency (`google_fonts`) for an editorial serif.

**Tech Stack:** Flutter (provider, go_router, image_picker), Dart, Express + TypeScript + PostgreSQL backend, vitest + flutter_test.

**Spec:** `docs/superpowers/specs/2026-08-19-queens-touch-brand-experience-design.md`

## Global Constraints

- Run mode is **live backend** (`--dart-define=USE_API=true`). Real uploaded images must animate; mock-mode placeholders must still look premium.
- Category-aware presentation keys off the **category slug / name**, never product IDs or filenames.
- The uploaded image is never permanently modified; all animation is presentation-only (mask/clip/scale/opacity/layer).
- Only new dependency: `google_fonts`. Everything else uses Flutter built-ins.
- Never replace real API data with mocks. No new product repository or second upload system.
- Keep the full existing test suite green (`test/` and `backend/src/**/*.test.ts`).
- Respect reduced motion (`MediaQuery.disableAnimationsOf`); information is never conveyed by animation alone.
- Existing copy stays: Paybill **222111**, Account **65727**, `$` in catalog, `KSh` in orders (do not unify currencies).
- Every task ends with a commit. Final task runs `flutter analyze`, `flutter test`, backend `npm run typecheck` + `npm test`.

---

### Task 1: Backend — expose `categorySlug` on product payloads

**Files:**
- Modify: `backend/src/models/index.ts` (Product + ProductRow interfaces)
- Modify: `backend/src/repositories/productRepository.ts` (`mapProductRow`, `search`, `findById`)
- Test: `backend/src/routes/productRouter.test.ts`

**Interfaces:**
- Consumes: existing `Product`, `ProductRow`, `Pool`.
- Produces: `Product.categorySlug: string`; `ProductRow.category_slug: string | null`; product payloads include `categorySlug`.

- [ ] **Step 1: Write the failing backend test**

Append to `backend/src/routes/productRouter.test.ts` inside the existing `describe('products API', ...)` block:

```ts
it('returns the category slug on product payloads', async () => {
  const res = await request(app)
    .get('/api/products/00000000-0000-0000-0000-000000000501')
    .set('x-user-id', '00000000-0000-0000-0000-000000000201');
  expect(res.status).toBe(200);
  expect(res.body.data.categorySlug).toBe('clothing-dresses');

  const list = await request(app)
    .get('/api/products?featured=true')
    .set('x-user-id', '00000000-0000-0000-0000-000000000201');
  expect(list.status).toBe(200);
  expect(list.body.data.products.length).toBeGreaterThan(0);
  expect(list.body.data.products[0].categorySlug).toBeTruthy();
});
```

- [ ] **Step 2: Run it to verify it fails**

Run: `npm test -- src/routes/productRouter.test.ts`
Expected: FAIL — `categorySlug` is `undefined`.

- [ ] **Step 3: Update the models**

In `backend/src/models/index.ts`, add to `Product`:

```ts
  categorySlug: string;
```

And to `ProductRow`:

```ts
  category_slug: string | null;
```

- [ ] **Step 4: Update `mapProductRow`**

In `backend/src/repositories/productRepository.ts`, add one line to the object returned by `mapProductRow` (after `categoryId`):

```ts
    categorySlug: String(row.category_slug ?? ''),
```

- [ ] **Step 5: Join categories in `search`**

Replace the data query in `search(...)` (currently `SELECT p.* FROM products p ${whereClause} ...`) with:

```ts
    const dataRes = await this.pool.query(
      `SELECT p.*, c.slug AS category_slug
       FROM products p
       LEFT JOIN categories c ON c.id = p.category_id
       ${whereClause} ORDER BY ${ORDER_BY[sort]} LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, pageSize, offset],
    );
```

- [ ] **Step 6: Join categories in `findById`**

Replace the query in `findById(...)` with:

```ts
    const res = await this.pool.query(
      `SELECT p.*, c.slug AS category_slug
       FROM products p
       LEFT JOIN categories c ON c.id = p.category_id
       WHERE p.id = $1`,
      [id],
    );
```

(`create`/`update` already return through `findById`, so they gain `categorySlug` automatically.)

- [ ] **Step 7: Run backend tests + typecheck**

Run: `npm run typecheck`
Run: `npm test`
Expected: PASS (including the new test).

- [ ] **Step 8: Commit**

```bash
git add backend/src/models/index.ts backend/src/repositories/productRepository.ts backend/src/routes/productRouter.test.ts
git commit -m "feat(backend): expose category slug on product payloads"
```

---

### Task 2: Add `google_fonts`, motion tokens, brand serif

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/animations/qts_animation.dart`
- Modify: `lib/core/theme/theme.dart`

**Interfaces:**
- Produces: `QtMotion.fast/normal/slow`, `QtMotion.signature/signatureInOut`, `QtMotion.reduceMotion(context)`; `QueensTouchTheme.brandSerif({...})`.

- [ ] **Step 1: Add dependency**

Run: `flutter pub add google_fonts`

- [ ] **Step 2: Create motion tokens**

Create `lib/core/animations/qts_animation.dart`:

```dart
import 'package:flutter/widgets.dart';

/// Central motion tokens for the Queens' Touch brand.
abstract final class QtMotion {
  static const Duration fast = Duration(milliseconds: 250);
  static const Duration normal = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 650);

  /// Signature easing — a gentle ease-out that feels like fabric settling.
  static const Curve signature = Curves.easeOutCubic;
  static const Curve signatureInOut = Curves.easeInOutCubic;

  /// True when the platform requests reduced motion or animations are disabled.
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}
```

- [ ] **Step 3: Add brand serif helper + theme text overrides**

In `lib/core/theme/theme.dart`, add import:

```dart
import 'package:google_fonts/google_fonts.dart';
```

Add to `QueensTouchTheme`:

```dart
  /// Editorial serif for brand moments (wordmark, hero, section titles).
  static TextStyle brandSerif({
    double fontSize = 24,
    FontWeight weight = FontWeight.w600,
    Color color = QueensTouchColors.textDark,
    double height = 1.15,
    double letterSpacing = 0.5,
  }) {
    return GoogleFonts.cormorantGaramond(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
```

Replace the `textTheme` block in `light()` with:

```dart
      textTheme: base.textTheme.copyWith(
        displayLarge: base.textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        displayMedium: GoogleFonts.cormorantGaramond(
          fontSize: 34,
          fontWeight: FontWeight.w600,
          color: base.colorScheme.onSurface,
        ),
        headlineLarge: GoogleFonts.cormorantGaramond(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: base.colorScheme.onSurface,
        ),
        headlineSmall: GoogleFonts.cormorantGaramond(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: base.colorScheme.onSurface,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
```

- [ ] **Step 4: Run analyze + existing tests**

Run: `flutter analyze`
Run: `flutter test`
Expected: PASS.

> If any widget test errors on GoogleFonts runtime font fetching, add `setUp(() => GoogleFonts.config.allowRuntimeFetching = false);` to the affected test file only (import `package:google_fonts/google_fonts.dart`). This is a test-only guard; the real app keeps runtime fetching enabled.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/animations/qts_animation.dart lib/core/theme/theme.dart
git commit -m "feat(brand): editorial serif and central motion tokens"
```

---

### Task 3: `Product.categorySlug` + presentation classifier + tests

**Files:**
- Modify: `lib/models/product.dart`
- Create: `lib/core/animations/product_presentation.dart`
- Test: `test/models/product_model_test.dart`
- Test: `test/core/animations/product_presentation_test.dart`

**Interfaces:**
- Consumes: `Product` (adds field).
- Produces: `enum ProductPresentation { fashion, lip, foundation, powder, eyeshadow, skincare, perfume, hair, accessory, generic }` and `ProductPresentation presentationFor({String categorySlug = '', String categoryId = '', String categoryName = ''})`.

- [ ] **Step 1: Write failing tests**

Create `test/models/product_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:botique/models/product.dart';

void main() {
  test('Product.fromJson parses categorySlug', () {
    final product = Product.fromJson({
      'id': 'p1',
      'name': 'Rosé Dress',
      'description': 'd',
      'basePrice': 10,
      'categoryId': '00000000-0000-0000-0000-000000000402',
      'categorySlug': 'clothing-dresses',
      'brandId': 'b1',
      'images': <String>[],
    });
    expect(product.categorySlug, 'clothing-dresses');
  });

  test('Product.fromJson defaults categorySlug to empty', () {
    final product = Product.fromJson({
      'id': 'p1',
      'name': 'x',
      'description': '',
      'basePrice': 1,
      'categoryId': 'beauty-lip',
      'brandId': 'b1',
      'images': <String>[],
    });
    expect(product.categorySlug, '');
  });
}
```

Create `test/core/animations/product_presentation_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:botique/core/animations/product_presentation.dart';

void main() {
  ProductPresentation p({String slug = '', String id = '', String name = ''}) =>
      presentationFor(categorySlug: slug, categoryId: id, categoryName: name);

  test('classifies fashion by slug', () {
    expect(p(slug: 'clothing-dresses'), ProductPresentation.fashion);
    expect(p(slug: 'clothing-jackets'), ProductPresentation.fashion);
  });

  test('classifies cosmetics by slug', () {
    expect(p(slug: 'beauty-lip'), ProductPresentation.lip);
    expect(p(slug: 'beauty-foundation'), ProductPresentation.foundation);
    expect(p(slug: 'beauty-blush'), ProductPresentation.powder);
    expect(p(slug: 'beauty-eyeshadow'), ProductPresentation.eyeshadow);
    expect(p(slug: 'beauty-skincare'), ProductPresentation.skincare);
    expect(p(slug: 'beauty-hair'), ProductPresentation.hair);
  });

  test('classifies perfume/fragrance slugs', () {
    expect(p(slug: 'perfume'), ProductPresentation.perfume);
    expect(p(slug: 'beauty-fragrance'), ProductPresentation.perfume);
  });

  test('falls back to categoryId when categorySlug is empty (mock data)', () {
    expect(p(id: 'clothing-dresses'), ProductPresentation.fashion);
    expect(p(id: 'beauty-lip'), ProductPresentation.lip);
  });

  test('falls back to product name keywords', () {
    expect(p(name: 'Velvet Matte Lipstick'), ProductPresentation.lip);
    expect(p(name: 'Luminous Foundation'), ProductPresentation.foundation);
    expect(p(name: 'Silk Garden Maxi Dress'), ProductPresentation.fashion);
  });

  test('returns generic when nothing matches', () {
    expect(p(), ProductPresentation.generic);
    expect(p(slug: 'misc-mystery', name: 'Gadget 3000'), ProductPresentation.generic);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/models/product_model_test.dart test/core/animations/product_presentation_test.dart`
Expected: FAIL — `categorySlug` not found; `presentationFor` not defined.

- [ ] **Step 3: Add `categorySlug` to Product model**

In `lib/models/product.dart`:
- Add `final String categorySlug;` to `Product`.
- Add `this.categorySlug = '',` to the constructor.
- In `Product.fromJson`, add:

```dart
      categorySlug: json['categorySlug'] as String? ?? '',
```

- [ ] **Step 4: Implement the classifier**

Create `lib/core/animations/product_presentation.dart`:

```dart
/// The visual treatment applied to a product based on its category.
/// Category-aware, never product- or filename-specific.
enum ProductPresentation {
  fashion,
  lip,
  foundation,
  powder,
  eyeshadow,
  skincare,
  perfume,
  hair,
  accessory,
  generic,
}

/// Resolves the presentation for a product from its category slug/id/name.
///
/// Precedence: category slug (or category id, which mock data uses as a slug),
/// then product-name keywords, then [ProductPresentation.generic].
ProductPresentation presentationFor({
  String categorySlug = '',
  String categoryId = '',
  String categoryName = '',
}) {
  final slug = (categorySlug.isNotEmpty ? categorySlug : categoryId)
      .toLowerCase()
      .trim();
  final name = categoryName.toLowerCase().trim();

  ProductPresentation? bySlug(String s) {
    if (s.isEmpty) return null;
    if (s.contains('clothing') || s.contains('apparel')) {
      return ProductPresentation.fashion;
    }
    if (s.contains('lip')) return ProductPresentation.lip;
    if (s.contains('foundation') || s.contains('concealer')) {
      return ProductPresentation.foundation;
    }
    if (s.contains('blush') || s.contains('powder')) {
      return ProductPresentation.powder;
    }
    if (s.contains('eyeshadow')) return ProductPresentation.eyeshadow;
    if (s.contains('skincare') || s.contains('skin-care')) {
      return ProductPresentation.skincare;
    }
    if (s.contains('perfume') ||
        s.contains('fragrance') ||
        s.contains('cologne')) {
      return ProductPresentation.perfume;
    }
    if (s.contains('hair')) return ProductPresentation.hair;
    if (s.contains('accessor')) return ProductPresentation.accessory;
    return null;
  }

  ProductPresentation? byName(String n) {
    if (n.isEmpty) return null;
    final tokens =
        n.split(RegExp(r'[^a-z]+')).where((t) => t.isNotEmpty).toList();
    final exact = <String, ProductPresentation>{
      'lip': ProductPresentation.lip,
      'lipstick': ProductPresentation.lip,
      'lipgloss': ProductPresentation.lip,
      'foundation': ProductPresentation.foundation,
      'concealer': ProductPresentation.foundation,
      'blush': ProductPresentation.powder,
      'powder': ProductPresentation.powder,
      'eyeshadow': ProductPresentation.eyeshadow,
      'palette': ProductPresentation.eyeshadow,
      'serum': ProductPresentation.skincare,
      'skincare': ProductPresentation.skincare,
      'moisturizer': ProductPresentation.skincare,
      'cleanser': ProductPresentation.skincare,
      'toner': ProductPresentation.skincare,
      'perfume': ProductPresentation.perfume,
      'fragrance': ProductPresentation.perfume,
      'cologne': ProductPresentation.perfume,
      'dress': ProductPresentation.fashion,
      'gown': ProductPresentation.fashion,
      'skirt': ProductPresentation.fashion,
      'trousers': ProductPresentation.fashion,
      'jeans': ProductPresentation.fashion,
      'jacket': ProductPresentation.fashion,
      'blouse': ProductPresentation.fashion,
      'jumpsuit': ProductPresentation.fashion,
      'shirt': ProductPresentation.fashion,
      'coat': ProductPresentation.fashion,
      'sweater': ProductPresentation.fashion,
      'cardigan': ProductPresentation.fashion,
      'shampoo': ProductPresentation.hair,
      'conditioner': ProductPresentation.hair,
    };
    for (final token in tokens) {
      final hit = exact[token];
      if (hit != null) return hit;
    }
    return null;
  }

  return bySlug(slug) ?? byName(name) ?? ProductPresentation.generic;
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/models/product_model_test.dart test/core/animations/product_presentation_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/models/product.dart lib/core/animations/product_presentation.dart test/models/product_model_test.dart test/core/animations/product_presentation_test.dart
git commit -m "feat(brand): category-aware presentation classifier"
```

---

### Task 4: `ProductImageReveal` + `FashionReveal`/`BeautyReveal`/`MistParticles`

**Files:**
- Create: `lib/core/animations/product_image_reveal.dart`
- Create: `lib/core/animations/fashion_beauty_reveal.dart`
- Create: `lib/core/animations/mist_particles.dart`
- Test: `test/core/animations/product_image_reveal_test.dart`

**Interfaces:**
- Consumes: `QtMotion`, `ProductPresentation`, `resolveImageUrl` (`lib/core/utils/image_url.dart`), `QueensTouchColors`.
- Produces:
  - `ProductImageReveal({required String imageUrl, BoxFit fit, BorderRadius? borderRadius, Object? heroTag, ProductPresentation presentation, String? semanticLabel, int? cacheWidth})`
  - `FashionReveal({required Widget child})`, `BeautyReveal({required Widget child})`
  - `MistParticles({int particleCount = 7, Color color = Colors.white})`

- [ ] **Step 1: Write failing widget tests**

Create `test/core/animations/product_image_reveal_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:botique/core/animations/product_image_reveal.dart';
import 'package:botique/core/animations/product_presentation.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: SizedBox(width: 120, height: 120, child: child));

  testWidgets('shows premium placeholder when no image', (tester) async {
    await tester.pumpWidget(wrap(const ProductImageReveal(imageUrl: '')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.checkroom), findsOneWidget);
  });

  testWidgets('falls back gracefully on image error', (tester) async {
    await tester.pumpWidget(wrap(const ProductImageReveal(imageUrl: '/nope.png')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.broken_image), findsOneWidget);
  });

  testWidgets('wraps in Hero when heroTag provided', (tester) async {
    await tester.pumpWidget(wrap(const ProductImageReveal(imageUrl: '', heroTag: 'tag-1')));
    await tester.pumpAndSettle();
    final hero = tester.widget<Hero>(find.byType(Hero));
    expect(hero.tag, 'tag-1');
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/animations/product_image_reveal_test.dart`
Expected: FAIL — `ProductImageReveal` not found.

- [ ] **Step 3: Create `MistParticles`**

Create `lib/core/animations/mist_particles.dart`:

```dart
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
```

- [ ] **Step 4: Create `FashionReveal` / `BeautyReveal`**

Create `lib/core/animations/fashion_beauty_reveal.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'qts_animation.dart';

/// Editorial top-to-bottom wipe reveal for fashion moments.
class FashionReveal extends StatelessWidget {
  const FashionReveal({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (QtMotion.reduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: QtMotion.slow,
      curve: QtMotion.signature,
      builder: (context, v, c) => ClipRect(
        child: ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white, Colors.transparent],
            stops: [0.0, v.clamp(0.0, 1.0), (v + 0.001).clamp(0.0, 1.0)],
          ).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: c,
        ),
      ),
      child: child,
    );
  }
}

/// Soft radial glow bloom + gentle scale for cosmetics moments.
class BeautyReveal extends StatelessWidget {
  const BeautyReveal({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (QtMotion.reduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: QtMotion.slow,
      curve: QtMotion.signature,
      builder: (context, v, c) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              QueensTouchColors.goldLight.withValues(alpha: 0.5 * (1 - v)),
              Colors.transparent,
            ],
          ),
        ),
        child: Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.96 + 0.04 * v,
            child: c,
          ),
        ),
      ),
      child: child,
    );
  }
}
```

- [ ] **Step 5: Create `ProductImageReveal`**

Create `lib/core/animations/product_image_reveal.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/utils/image_url.dart';
import 'fashion_beauty_reveal.dart';
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
              _markLoaded();
              return child;
            }
            if (frame == null) {
              return const _SkeletonSurface();
            }
            _markLoaded();
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: QtMotion.normal,
              curve: QtMotion.signature,
              builder: (context, v, c) => Opacity(opacity: v, child: c),
              child: child,
            );
          },
          loadingBuilder: (context, child, event) {
            if (event == null) return child;
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
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/core/animations/product_image_reveal_test.dart`
Expected: PASS.

- [ ] **Step 7: Run analyze + full test suite**

Run: `flutter analyze`
Run: `flutter test`
Expected: PASS. Note: `MistParticles` repeats indefinitely — only rendered for perfume products, which no current test renders. If a future test renders one, use `tester.pump(duration)` instead of `pumpAndSettle`.

- [ ] **Step 8: Commit**

```bash
git add lib/core/animations/product_image_reveal.dart lib/core/animations/fashion_beauty_reveal.dart lib/core/animations/mist_particles.dart test/core/animations/product_image_reveal_test.dart
git commit -m "feat(brand): product image reveal with category-aware presentation"
```

---

### Task 5: `StaggerReveal`, `PressScale`, `AnimatedCounter`

**Files:**
- Create: `lib/core/animations/stagger_reveal.dart`
- Create: `lib/core/animations/press_scale.dart`
- Create: `lib/core/animations/animated_counter.dart`
- Test: `test/core/animations/brand_widgets_test.dart`

**Interfaces:**
- Consumes: `QtMotion`.
- Produces:
  - `StaggerReveal({required Widget child, int index = 0, Offset offset = const Offset(0, 16)})`
  - `PressScale({required Widget child, VoidCallback? onTap, double scale = 0.97})`
  - `AnimatedCounter({required double value, required String Function(double) format, Duration duration = QtMotion.normal, TextStyle? style, TextAlign? textAlign})`

- [ ] **Step 1: Write failing widget tests**

Create `test/core/animations/brand_widgets_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:botique/core/animations/animated_counter.dart';
import 'package:botique/core/animations/press_scale.dart';
import 'package:botique/core/animations/stagger_reveal.dart';

void main() {
  testWidgets('StaggerReveal reveals its child', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StaggerReveal(child: Text('revealed'))),
    ));
    expect(find.text('revealed'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('revealed'), findsOneWidget);
  });

  testWidgets('PressScale fires onTap and scales on press', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PressScale(
          onTap: () => tapped = true,
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    ));
    await tester.tap(find.byType(PressScale));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('AnimatedCounter renders formatted final value', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AnimatedCounter(
          value: 48290,
          format: _ksh,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('KSh 48,290.00'), findsOneWidget);
  });
}

String _ksh(double value) {
  final s = value.toStringAsFixed(2);
  return 'KSh ${s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/animations/brand_widgets_test.dart`
Expected: FAIL — widgets not found.

- [ ] **Step 3: Create `StaggerReveal`**

Create `lib/core/animations/stagger_reveal.dart`:

```dart
import 'package:flutter/material.dart';

import 'qts_animation.dart';

/// One-shot staggered entrance: fades in and slides up, with an optional
/// per-index stagger delay. Runs once on first build.
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: QtMotion.normal);
    final curve = CurvedAnimation(parent: _controller, curve: QtMotion.signature);
    _opacity = curve;
    _slide = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(curve);
    if (QtMotion.reduceMotion(context)) {
      _controller.value = 1.0;
    } else {
      Future<void>.delayed(Duration(milliseconds: widget.index * 70), () {
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
```

- [ ] **Step 4: Create `PressScale`**

Create `lib/core/animations/press_scale.dart`:

```dart
import 'package:flutter/material.dart';

import 'qts_animation.dart';

/// Refined press feedback: gently scales the child down while pressed and
/// springs back on release. Fires [onTap] on tap.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: QtMotion.fast,
        curve: QtMotion.signature,
        child: widget.child,
      ),
    );
  }
}
```

- [ ] **Step 5: Create `AnimatedCounter`**

Create `lib/core/animations/animated_counter.dart`:

```dart
import 'package:flutter/material.dart';

import 'qts_animation.dart';

/// Smoothly animates between numeric values, formatting each intermediate
/// value with [format]. Skips animation under reduced motion.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    required this.format,
    this.duration = QtMotion.normal,
    this.style,
    this.textAlign,
  });

  final double value;
  final String Function(double value) format;
  final Duration duration;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: QtMotion.reduceMotion(context) ? Duration.zero : duration,
      curve: QtMotion.signature,
      builder: (context, v, _) =>
          Text(format(v), style: style, textAlign: textAlign),
    );
  }
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/core/animations/brand_widgets_test.dart`
Expected: PASS.

- [ ] **Step 7: Run analyze + full suite**

Run: `flutter analyze`
Run: `flutter test`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/core/animations/stagger_reveal.dart lib/core/animations/press_scale.dart lib/core/animations/animated_counter.dart test/core/animations/brand_widgets_test.dart
git commit -m "feat(brand): stagger reveal, press scale, animated counter"
```

---

### Task 6: `WishlistHeart`, `AnimatedStarRating`, `ShadeSelector`

**Files:**
- Create: `lib/core/animations/wishlist_heart.dart`
- Create: `lib/core/animations/animated_star_rating.dart`
- Create: `lib/core/animations/shade_selector.dart`
- Test: `test/core/animations/selection_widgets_test.dart`

**Interfaces:**
- Consumes: `QtMotion`, `QueensTouchColors`.
- Produces:
  - `WishlistHeart({required bool isSelected, required VoidCallback onPressed, double size = 24, Color? color})`
  - `AnimatedStarRating({required int rating, required ValueChanged<int> onChanged, double size = 40, bool enabled = true})`
  - `ShadeSelector({required List<String> shades, required String? selected, required ValueChanged<String> onSelected, String label = 'Select Shade'})`
  - `Color shadeColor(String shade)` (exported from shade_selector.dart)

- [ ] **Step 1: Write failing widget tests**

Create `test/core/animations/selection_widgets_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:botique/core/animations/animated_star_rating.dart';
import 'package:botique/core/animations/shade_selector.dart';
import 'package:botique/core/animations/wishlist_heart.dart';

void main() {
  testWidgets('WishlistHeart fires onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WishlistHeart(
          isSelected: false,
          onPressed: () => tapped = true,
        ),
      ),
    ));
    await tester.tap(find.byType(WishlistHeart));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('AnimatedStarRating reports the tapped rating', (tester) async {
    int? chosen;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AnimatedStarRating(rating: 3, onChanged: (v) => chosen = v),
      ),
    ));
    await tester.tap(find.byIcon(Icons.star).last);
    await tester.pump();
    expect(chosen, 5);
  });

  testWidgets('ShadeSelector shows shades and reports selection', (tester) async {
    String? chosen;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ShadeSelector(
          shades: const ['Rose', 'Plum'],
          selected: 'Rose',
          onSelected: (v) => chosen = v,
        ),
      ),
    ));
    expect(find.text('Rose'), findsOneWidget);
    expect(find.text('Plum'), findsOneWidget);
    await tester.tap(find.text('Plum'));
    await tester.pump();
    expect(chosen, 'Plum');
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/animations/selection_widgets_test.dart`
Expected: FAIL — widgets not found.

- [ ] **Step 3: Create `WishlistHeart`**

Create `lib/core/animations/wishlist_heart.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'qts_animation.dart';

/// Wishlist heart with a subtle scale bounce and soft glow on selection.
class WishlistHeart extends StatefulWidget {
  const WishlistHeart({
    super.key,
    required this.isSelected,
    required this.onPressed,
    this.size = 24,
    this.color = QueensTouchColors.danger,
  });

  final bool isSelected;
  final VoidCallback onPressed;
  final double size;
  final Color color;

  @override
  State<WishlistHeart> createState() => _WishlistHeartState();
}

class _WishlistHeartState extends State<WishlistHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: QtMotion.normal,
    )..value = 1.0;
  }

  @override
  void didUpdateWidget(covariant WishlistHeart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _controller, curve: QtMotion.signature);
    return GestureDetector(
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final bounce = 1.0 + 0.25 * (1 - (1 - _controller.value) * (1 - _controller.value));
          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.isSelected)
                Container(
                  width: widget.size * 1.7,
                  height: widget.size * 1.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.14 * scale.value),
                  ),
                ),
              Transform.scale(
                scale: bounce,
                child: Icon(
                  widget.isSelected ? Icons.favorite : Icons.favorite_border,
                  size: widget.size,
                  color: widget.isSelected ? widget.color : QueensTouchColors.textMuted,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Create `AnimatedStarRating`**

Create `lib/core/animations/animated_star_rating.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'qts_animation.dart';

/// Star selection with smooth appearance and subtle scale on the tapped star.
class AnimatedStarRating extends StatelessWidget {
  const AnimatedStarRating({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 40,
    this.enabled = true,
  });

  final int rating;
  final ValueChanged<int> onChanged;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            onTap: enabled ? () => onChanged(i) : null,
            child: AnimatedScale(
              scale: i <= rating ? 1.0 : 0.9,
              duration: QtMotion.fast,
              curve: QtMotion.signature,
              child: AnimatedOpacity(
                opacity: i <= rating ? 1.0 : 0.45,
                duration: QtMotion.fast,
                child: Icon(
                  i <= rating ? Icons.star : Icons.star_border,
                  size: size,
                  color: QueensTouchColors.gold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 5: Create `ShadeSelector`**

Create `lib/core/animations/shade_selector.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'qts_animation.dart';

const Map<String, Color> kShadeColors = {
  'red': Color(0xFFC0392B),
  'rose': Color(0xFFB76E79),
  'nude': Color(0xFFD9B8A0),
  'berry': Color(0xFF8B3A5B),
  'plum': Color(0xFF6D2E4F),
  'coral': Color(0xFFE86A58),
  'pink': Color(0xFFE8A7B8),
  'mauve': Color(0xFFA98B8E),
  'brown': Color(0xFF6B4A2F),
  'black': Color(0xFF26211F),
  'tan': Color(0xFFC49A6C),
  'gold': Color(0xFFC9A24B),
  'beige': Color(0xFFE3C9A6),
  'burgundy': Color(0xFF6E1E2E),
  'peach': Color(0xFFF2B8A2),
  'maroon': Color(0xFF701D2B),
  'neutral': Color(0xFFD8BFA8),
};

/// Best-effort color for a cosmetic shade name; falls back to brand plum.
Color shadeColor(String shade) {
  final key = shade.trim().toLowerCase();
  final direct = kShadeColors[key];
  if (direct != null) return direct;
  for (final entry in kShadeColors.entries) {
    if (key.contains(entry.key)) return entry.value;
  }
  return QueensTouchColors.plumLight;
}

/// Animated shade/color selection for cosmetics with a color-aware chip and
/// an animated selection indicator.
class ShadeSelector extends StatelessWidget {
  const ShadeSelector({
    super.key,
    required this.shades,
    required this.selected,
    required this.onSelected,
    this.label = 'Select Shade',
  });

  final List<String> shades;
  final String? selected;
  final ValueChanged<String> onSelected;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final shade in shades)
              _ShadeChip(
                shade: shade,
                selected: selected == shade,
                onTap: () => onSelected(shade),
              ),
          ],
        ),
      ],
    );
  }
}

class _ShadeChip extends StatelessWidget {
  const _ShadeChip({required this.shade, required this.selected, required this.onTap});

  final String shade;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = shadeColor(shade);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: QtMotion.fast,
        curve: QtMotion.signature,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? QueensTouchColors.blushLight
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : const Color(0xFFE4D5DA),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: QtMotion.fast,
              curve: QtMotion.signature,
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: selected ? 0.4 : 0.15),
                    blurRadius: selected ? 6 : 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              shade,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/core/animations/selection_widgets_test.dart`
Expected: PASS.

- [ ] **Step 7: Run analyze + full suite**

Run: `flutter analyze`
Run: `flutter test`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/core/animations/wishlist_heart.dart lib/core/animations/animated_star_rating.dart lib/core/animations/shade_selector.dart test/core/animations/selection_widgets_test.dart
git commit -m "feat(brand): wishlist heart, star rating, shade selector"
```

---

### Task 7: `AddToCartButton` + `AddToCartFly`

**Files:**
- Create: `lib/core/animations/add_to_cart_fly.dart`
- Test: `test/core/animations/add_to_cart_test.dart`

**Interfaces:**
- Consumes: `QtMotion`, `QueensTouchColors`.
- Produces:
  - `AddToCartButton({required VoidCallback onPressed, String label = 'Add to Cart', IconData icon = Icons.add_shopping_cart, String confirmLabel = 'Added to Bag', bool enabled = true})` — shows a short "added" confirmation after `onPressed`; does not block.
  - `AddToCartFly.show(BuildContext context, {required String imageUrl, Rect? from, double size = 56})` — animates a thumbnail from `from` (defaults to screen centre) toward the top-right, fading out; uses a bag glyph when there is no image.

- [ ] **Step 1: Write failing widget tests**

Create `test/core/animations/add_to_cart_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:botique/core/animations/add_to_cart_fly.dart';

void main() {
  testWidgets('AddToCartButton fires onPressed and confirms', (tester) async {
    var pressed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AddToCartButton(
          onPressed: () => pressed = true,
        ),
      ),
    ));
    await tester.tap(find.text('Add to Cart'));
    await tester.pump();
    expect(pressed, isTrue);
    expect(find.text('Added to Bag'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Add to Cart'), findsOneWidget);
  });

  testWidgets('AddToCartFly inserts and removes an overlay entry', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    AddToCartFly.show(tester.element(find.byType(Scaffold)), imageUrl: '');
    await tester.pump();
    expect(find.byType(Overlay), findsWidgets);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.shopping_bag_outlined), findsNothing);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/animations/add_to_cart_test.dart`
Expected: FAIL — not found.

- [ ] **Step 3: Create `AddToCartFly`**

Create `lib/core/animations/add_to_cart_fly.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'qts_animation.dart';

/// Elevated "Add to Cart" button that briefly morphs to a confirmation after
/// [onPressed] fires. Non-blocking and fast.
class AddToCartButton extends StatefulWidget {
  const AddToCartButton({
    super.key,
    required this.onPressed,
    this.label = 'Add to Cart',
    this.icon = Icons.add_shopping_cart,
    this.confirmLabel = 'Added to Bag',
    this.enabled = true,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final String confirmLabel;
  final bool enabled;

  @override
  State<AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<AddToCartButton> {
  bool _confirmed = false;

  Future<void> _handleTap() async {
    widget.onPressed();
    if (mounted) setState(() => _confirmed = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _confirmed = false);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: widget.enabled ? _handleTap : null,
      icon: AnimatedSwitcher(
        duration: QtMotion.fast,
        child: _confirmed
            ? const Icon(Icons.check, key: ValueKey('check'))
            : Icon(widget.icon, key: const ValueKey('icon')),
      ),
      label: AnimatedSwitcher(
        duration: QtMotion.fast,
        child: Text(
          _confirmed ? widget.confirmLabel : widget.label,
          key: ValueKey(_confirmed),
        ),
      ),
    );
  }
}

/// Flies a product thumbnail toward the top-right of the screen to give
/// add-to-cart a satisfying physical gesture. Pure presentation; does not
/// depend on widget geometry of the cart badge.
class AddToCartFly {
  AddToCartFly._();

  static void show(
    BuildContext context, {
    required String imageUrl,
    Rect? from,
    double size = 56,
  }) {
    final overlay = Overlay.of(context);
    final screen = MediaQuery.sizeOf(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final start = from ??
        Rect.fromCenter(
          center: screen.center(Offset.zero),
          width: size,
          height: size,
        );
    final end = Rect.fromLTWH(screen.width - size - 20, topPad + 24, size, size);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _FlyOverlay(
        imageUrl: imageUrl,
        from: start,
        to: end,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _FlyOverlay extends StatefulWidget {
  const _FlyOverlay({
    required this.imageUrl,
    required this.from,
    required this.to,
    required this.onDone,
  });

  final String imageUrl;
  final Rect from;
  final Rect to;
  final VoidCallback onDone;

  @override
  State<_FlyOverlay> createState() => _FlyOverlayState();
}

class _FlyOverlayState extends State<_FlyOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(parent: _controller, curve: QtMotion.signatureInOut);
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = animation.value;
            final left = widget.from.left + (widget.to.left - widget.from.left) * t;
            final top = widget.from.top + (widget.to.top - widget.from.top) * t;
            final size = widget.from.width + (widget.to.width - widget.from.width) * t;
            return Stack(
              children: [
                Positioned(
                  left: left,
                  top: top,
                  width: size,
                  height: size,
                  child: Opacity(
                    opacity: t < 0.8 ? 1.0 : (1 - t) * 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.imageUrl.trim().isEmpty
                          ? Container(
                              color: QueensTouchColors.plum,
                              child: const Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.white,
                              ),
                            )
                          : Image.network(
                              resolveImageUrl(widget.imageUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: QueensTouchColors.plum,
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

Add import at top of the file:

```dart
import '../../core/utils/image_url.dart';
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/animations/add_to_cart_test.dart`
Expected: PASS.

> The `AddToCartButton` confirmation is one-shot (no infinite animation), so `pumpAndSettle` settles after ~900ms of simulated time.

- [ ] **Step 5: Run analyze + full suite**

Run: `flutter analyze`
Run: `flutter test`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/animations/add_to_cart_fly.dart test/core/animations/add_to_cart_test.dart
git commit -m "feat(brand): add-to-cart button confirmation and fly-to-bag gesture"
```

---

### Task 8: `OrderTimeline`, `PaymentStatusFlow`, `AnimatedBarChart`

**Files:**
- Create: `lib/core/animations/order_timeline.dart`
- Create: `lib/core/animations/animated_bar_chart.dart`
- Test: `test/core/animations/progress_widgets_test.dart`

**Interfaces:**
- Consumes: `QtMotion`, `QueensTouchColors`, `OrderStatus`/`PaymentStatus` (`lib/models/order.dart`).
- Produces:
  - `OrderTimeline({required OrderStatus status})` — animated Pending → Paid → Processing → Ready → Delivered timeline.
  - `PaymentStatusFlow({required PaymentStatus status})` — submitted → pending verification → verified, with a rejected error state.
  - `AnimatedBarChart({required List<double> values, required List<String> labels, Color? color, double height = 120, double barRadius = 4})`

- [ ] **Step 1: Write failing widget tests**

Create `test/core/animations/progress_widgets_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:botique/core/animations/animated_bar_chart.dart';
import 'package:botique/core/animations/order_timeline.dart';
import 'package:botique/models/order.dart';

void main() {
  testWidgets('OrderTimeline renders labels for a delivered order', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OrderTimeline(status: OrderStatus.delivered),
      ),
    ));
    await tester.pumpAndSettle();
    for (final label in ['Pending', 'Paid', 'Processing', 'Ready', 'Delivered']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('PaymentStatusFlow shows verified state', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PaymentStatusFlow(status: PaymentStatus.successful),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Verified'), findsOneWidget);
  });

  testWidgets('AnimatedBarChart renders all bars and labels', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AnimatedBarChart(values: const [10, 20], labels: const ['Mon', 'Tue']),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Tue'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/animations/progress_widgets_test.dart`
Expected: FAIL — not found.

- [ ] **Step 3: Create `OrderTimeline` + `PaymentStatusFlow`**

Create `lib/core/animations/order_timeline.dart`:

```dart
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
                      color: const Color(0xFFEEDFE4),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 14,
                    width: (_reached - 1) / (_steps.length - 1) * constraints.maxWidth,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: 1.0),
                      duration: QtMotion.normal,
                      curve: QtMotion.signature,
                      builder: (context, v, _) => Container(
                        height: 3,
                        color: QueensTouchColors.plum,
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
                                  : Colors.white,
                              border: Border.all(
                                color: i < _reached
                                    ? QueensTouchColors.plum
                                    : const Color(0xFFE4D5DA),
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
                color: i < reached ? QueensTouchColors.success : const Color(0xFFEEDFE4),
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
```

- [ ] **Step 4: Create `AnimatedBarChart`**

Create `lib/core/animations/animated_bar_chart.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'qts_animation.dart';

/// Bars animate to their height once on first display and on value changes
/// (keyed per label so data changes replay the entrance).
class AnimatedBarChart extends StatelessWidget {
  const AnimatedBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.color = QueensTouchColors.plum,
    this.height = 120,
    this.barRadius = 4,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final double height;
  final double barRadius;

  @override
  Widget build(BuildContext context) {
    final max = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey('${labels[i]}-${values[i]}'),
                          tween: Tween(
                            begin: QtMotion.reduceMotion(context) ? 1.0 : 0.0,
                            end: 1.0,
                          ),
                          duration: QtMotion.slow,
                          curve: QtMotion.signature,
                          builder: (context, v, _) => FractionallySizedBox(
                            heightFactor: v,
                            child: Container(
                              decoration: BoxDecoration(
                                color: i == values.length - 1
                                    ? color
                                    : color.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(barRadius),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      style: const TextStyle(
                        fontSize: 10,
                        color: QueensTouchColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/core/animations/progress_widgets_test.dart`
Expected: PASS.

- [ ] **Step 6: Run analyze + full suite**

Run: `flutter analyze`
Run: `flutter test`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/core/animations/order_timeline.dart lib/core/animations/animated_bar_chart.dart test/core/animations/progress_widgets_test.dart
git commit -m "feat(brand): order timeline, payment status flow, animated bar chart"
```

---

### Task 9: Product card enhancements

**Files:**
- Modify: `lib/core/widgets/product_card.dart`

**Interfaces:**
- Consumes: `ProductImageReveal`, `PressScale`, `WishlistHeart`, `presentationFor`, `QtMotion`, `WishlistService`.
- Produces: `ProductCard({required Product product, bool compact = false, Object? heroTag})`.

- [ ] **Step 1: Write failing widget test**

Create `test/core/widgets/product_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:botique/core/widgets/product_card.dart';
import 'package:botique/data/mock/mock_commerce_repositories.dart';
import 'package:botique/models/product.dart';
import 'package:botique/services/wishlist_service.dart';

void main() {
  testWidgets('product card shows name, price and image placeholder', (tester) async {
    final product = Product(
      id: 'p1',
      name: 'Rosé Dress',
      description: 'd',
      price: 50,
      categoryId: 'clothing-dresses',
      brandId: 'b1',
      images: const [],
    );
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => WishlistService(MockWishlistRepository()),
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 150, height: 250, child: ProductCard(product: product)),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Rosé Dress'), findsOneWidget);
    expect(find.text('\$50.00'), findsOneWidget);
    expect(find.byIcon(Icons.checkroom), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/widgets/product_card_test.dart`
Expected: FAIL (or the card does not yet use the new components — the test may pass since it checks existing text; that's fine, the test is a guard for the refactor).

- [ ] **Step 3: Rewrite `ProductCard`**

Replace `lib/core/widgets/product_card.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../core/theme/theme.dart';
import '../../services/wishlist_service.dart';
import '../animations/press_scale.dart';
import '../animations/product_image_reveal.dart';
import '../animations/product_presentation.dart';
import '../animations/wishlist_heart.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.compact = false,
    this.heroTag,
  });

  final Product product;
  final bool compact;

  /// Shared-element tag; only set where the product appears exactly once per
  /// screen (e.g. the catalog grid). Home rows pass null to avoid duplicate
  /// Hero tags.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final presentation = presentationFor(
      categorySlug: product.categorySlug,
      categoryId: product.categoryId,
    );
    return PressScale(
      onTap: () => context.push('/product/${product.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProductImageReveal(
                  imageUrl: product.images.isNotEmpty ? product.images.first : '',
                  heroTag: heroTag,
                  presentation: presentation,
                  semanticLabel: product.name,
                  cacheWidth: 640,
                ),
                if (product.hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: QueensTouchColors.danger,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '-${product.discountPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (product.hasLabel(ProductLabel.newArrival))
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: QueensTouchColors.plum,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: _CardWishlist(productId: product.id),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '\$${product.effectivePrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: QueensTouchColors.plum,
                      ),
                    ),
                    if (product.hasDiscount) ...[
                      const SizedBox(width: 6),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                if (product.rating > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: QueensTouchColors.gold),
                      const SizedBox(width: 2),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardWishlist extends StatelessWidget {
  const _CardWishlist({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistService>();
    return FutureBuilder<bool>(
      future: wishlist.contains(productId),
      builder: (context, snapshot) {
        final selected = snapshot.data ?? false;
        return Material(
          color: Colors.white.withValues(alpha: 0.85),
          shape: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: WishlistHeart(
              isSelected: selected,
              size: 20,
              onPressed: () => wishlist.toggle(productId),
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 4: Run tests + analyze**

Run: `flutter test test/core/widgets/product_card_test.dart`
Run: `flutter analyze`
Run: `flutter test`
Expected: PASS (all existing tests still green — cards now depend on `WishlistService`, so screens that render cards must provide it; the customer shell already does).

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/product_card.dart test/core/widgets/product_card_test.dart
git commit -m "feat(brand): premium product card with reveal, press and wishlist"
```

---

### Task 10: Home screen — premium digital boutique

**Files:**
- Modify: `lib/customer/home/home_screen.dart`

**Interfaces:**
- Consumes: `CatalogService`, `FashionReveal`, `BeautyReveal`, `StaggerReveal`, `ProductImageReveal`, `ProductCard`, `QtMotion`, `QueensTouchTheme.brandSerif`, `presentationFor`.
- Produces: restructured `HomeScreen` with `_CampaignHero`, `_NewCollectionSection`, `_FashionRow`, `_BeautyRow`.

- [ ] **Step 1: Convert `HomeScreen` to stateful with scroll tracking**

Change `HomeScreen` to a `StatefulWidget` holding a `ScrollController` and a `ValueNotifier<double> _scroll`; wrap the `ListView` in a `NotificationListener<ScrollNotification>` that updates `_scroll`. Dispose both. The `ListView` keeps `padding: EdgeInsets.zero` and `controller: _scrollController`.

Replace the `_HeroBanner` usage with `_CampaignHero(scrollOffset: _scroll)` and add a `_NewCollectionSection(products: catalog.newArrivals)` right after it. Add `_FashionRow` and `_BeautyRow` sections before `_OfferBanner`. Section order becomes:

1. `_CampaignHero`
2. `_NewCollectionSection`
3. `_SectionHeader('Shop by Category')` + `_CategoryChips`
4. `_SectionHeader('Featured', 'Handpicked for you')` + `_ProductRow`
5. `_SectionHeader('Fashion', 'Curated womenswear')` + `_FashionRow`
6. `_SectionHeader('Beauty', 'Makeup, skincare and glow')` + `_BeautyRow`
7. `_SectionHeader('Best Sellers', 'Loved by our queens')` + `_ProductRow`
8. `_OfferBanner`
9. `_SectionHeader('Trending Now')` + `_ProductRow`
10. `_SectionHeader('Recommended for You')` + `_ProductRow`
11. `_NewsletterSection`, `_FooterSection`

- [ ] **Step 2: Add `_CampaignHero`**

Replace `_HeroBanner` with `_CampaignHero`:

```dart
class _CampaignHero extends StatelessWidget {
  const _CampaignHero({required this.scrollOffset});

  final ValueNotifier<double> scrollOffset;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: scrollOffset,
      builder: (context, offset, _) {
        final parallax = (offset.clamp(0.0, 200.0) * 0.25).toDouble();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: FashionReveal(
              child: Container(
                height: 300,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [QueensTouchColors.plumDark, QueensTouchColors.plum],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      bottom: -60,
                      child: Transform.translate(
                        offset: Offset(0, parallax),
                        child: Icon(
                          Icons.diamond,
                          size: 220,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StaggerReveal(
                            index: 0,
                            child: Text(
                              'THE NEW COLLECTION',
                              style: TextStyle(
                                color: QueensTouchColors.goldLight,
                                fontSize: 12,
                                letterSpacing: 4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          StaggerReveal(
                            index: 1,
                            child: Text(
                              'Elegance is in\nher every step',
                              style: QueensTouchTheme.brandSerif(
                                fontSize: 34,
                                weight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          StaggerReveal(
                            index: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const CatalogScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: QueensTouchColors.plumDark,
                              ),
                              child: const Text('Shop Now'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 3: Add `_NewCollectionSection`**

Add:

```dart
class _NewCollectionSection extends StatelessWidget {
  const _NewCollectionSection({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final hero = products.isNotEmpty ? products.first : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggerReveal(
            index: 0,
            child: Text(
              'NEW COLLECTION',
              style: QueensTouchTheme.brandSerif(fontSize: 28, weight: FontWeight.w700),
            ),
          ),
          StaggerReveal(
            index: 1,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Fresh from the atelier — discover what is new this season.',
                style: const TextStyle(color: QueensTouchColors.textMuted),
              ),
            ),
          ),
          if (hero != null) ...[
            const SizedBox(height: 14),
            StaggerReveal(
              index: 2,
              child: _CollectionBanner(product: hero),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CollectionBanner extends StatelessWidget {
  const _CollectionBanner({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final presentation = presentationFor(
      categorySlug: product.categorySlug,
      categoryId: product.categoryId,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ProductImageReveal(
              imageUrl: product.images.isNotEmpty ? product.images.first : '',
              presentation: presentation,
              cacheWidth: 800,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: QueensTouchTheme.brandSerif(
                        fontSize: 20,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${product.effectivePrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: QueensTouchColors.goldLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Add `_FashionRow` / `_BeautyRow`**

Add:

```dart
class _CuratedRow extends StatelessWidget {
  const _CuratedRow({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: Responsive.isMobile(context) ? 150 : 200,
            child: StaggerReveal(
              index: index,
              child: ProductCard(product: product),
            ),
          );
        },
      ),
    );
  }
}
```

In `HomeScreen.build`, compute:

```dart
final fashion = catalog.featured
    .where((p) =>
        presentationFor(categorySlug: p.categorySlug, categoryId: p.categoryId) ==
        ProductPresentation.fashion)
    .take(8)
    .toList();
final beauty = catalog.featured
    .where((p) =>
        presentationFor(categorySlug: p.categorySlug, categoryId: p.categoryId) !=
        ProductPresentation.fashion)
    .take(8)
    .toList();
```

and use `_CuratedRow(products: fashion)` / `_CuratedRow(products: beauty)` for the Fashion and Beauty sections. Add imports for `ValueNotifier`, `presentationFor`, `ProductPresentation`, `Product`, `FashionReveal`, `StaggerReveal`, `ProductImageReveal`, `QueensTouchTheme`, `QtMotion` (if used).

Wrap each `_ProductRow`'s card in `StaggerReveal(index: index)` (modify `_ProductRow.itemBuilder` accordingly).

- [ ] **Step 5: Keep section headers premium**

Update `_SectionHeader` title style to use `QueensTouchTheme.brandSerif(fontSize: 20, weight: FontWeight.w700)` for the title (keep the muted subtitle).

- [ ] **Step 6: Run analyze + tests**

Run: `flutter analyze`
Run: `flutter test`
Expected: PASS. (No home screen test exists today; the app boot test must still pass.)

- [ ] **Step 7: Update the shell wordmark to the serif**

In `lib/customer/customer_shell.dart`, replace the AppBar `title` style with `QueensTouchTheme.brandSerif(fontSize: 20, weight: FontWeight.w700, color: QueensTouchColors.textDark)` (remove the inline `fontFamily: 'Georgia'`). Import `../../core/theme/theme.dart` (already imported) — use the new helper.

- [ ] **Step 8: Run tests + commit**

Run: `flutter analyze`
Run: `flutter test`
Expected: PASS.

```bash
git add lib/customer/home/home_screen.dart lib/customer/customer_shell.dart
git commit -m "feat(home): premium campaign hero, new collection and curated rows"
```

---

### Task 11: Catalog grid — staggered entrance + category-aware cards

**Files:**
- Modify: `lib/customer/catalog/catalog_screen.dart`

**Interfaces:**
- Consumes: `StaggerReveal`, `ProductCard` (with `heroTag`).

- [ ] **Step 1: Modify `_ProductGrid`**

In `lib/customer/catalog/catalog_screen.dart`, replace `_ProductGrid.build` with a staggered grid. Add a `gridKey` parameter used to replay entrances on filter/sort change:

```dart
class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products, required this.gridKey});

  final List<Product> products;
  final Key gridKey;

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.gridColumns(context);
    return GridView.builder(
      key: gridKey,
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => StaggerReveal(
        index: index,
        child: ProductCard(
          product: products[index],
          heroTag: 'product-image-${products[index].id}',
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Wire the grid key**

In `CatalogScreenState.build`, replace `_ProductGrid(products: _result!.products)` with:

```dart
_ProductGrid(
  products: _result!.products,
  gridKey: ValueKey('grid-${_sort}-${_filter.hashCode}'),
)
```

Add imports for `StaggerReveal` and `Product` (already imported).

- [ ] **Step 3: Run analyze + tests**

Run: `flutter analyze`
Run: `flutter test`
Expected: PASS. (Cards in the grid provide a unique Hero tag — each product appears once per grid.)

- [ ] **Step 4: Commit**

```bash
git add lib/customer/catalog/catalog_screen.dart
git commit -m "feat(catalog): staggered grid entrance with category-aware cards"
```

---

### Task 12: Product detail — hero transition, gallery, shades, add-to-cart

**Files:**
- Modify: `lib/customer/catalog/product_detail_screen.dart`

**Interfaces:**
- Consumes: `ProductImageReveal`, `ShadeSelector`, `AddToCartButton`, `AddToCartFly`, `WishlistHeart`, `presentationFor`, `QtMotion`.
- Keeps: existing `_VariantSection` (sizes), `_QuantityStepper`, reviews, description.

- [ ] **Step 1: Add a Hero destination + category-aware gallery**

In `_Gallery`, wrap the image container in a `Hero(tag: 'product-image-${widget.product.id}')` so the destination exists on the first frame even while the product loads. The container keeps its blush surface and 320 height. Replace the `PageView` item image with:

```dart
ProductImageReveal(
  imageUrl: images[i],
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(16),
  presentation: presentationFor(
    categorySlug: widget.product.categorySlug,
    categoryId: widget.product.categoryId,
  ),
  semanticLabel: widget.product.name,
)
```

Keep the `1/${images.length}` counter overlay and dot indicators. For the no-image case, keep `Icons.checkroom` in the container (the existing gallery test depends on it) — render it directly (not via `ProductImageReveal`, which also shows `Icons.checkroom`; either is fine, but keep `find.byIcon(Icons.checkroom)` matching once).

- [ ] **Step 2: Use `ShadeSelector` for shades**

In `_ProductDetailBody`, replace the `if (shades.isNotEmpty) _VariantSection(label: 'Select Shade', ...)` block with:

```dart
if (shades.isNotEmpty) ...[
  ShadeSelector(
    shades: shades,
    selected: selectedShade,
    onSelected: onShadeSelected,
  ),
  const SizedBox(height: 16),
],
```

Keep `_VariantSection` for sizes and colors.

- [ ] **Step 3: Animated quantity**

Wrap the quantity `Text('$quantity', ...)` in an `AnimatedSwitcher` with `duration: QtMotion.fast` and a `ValueKey(quantity)` so the number transitions smoothly.

- [ ] **Step 4: Premium add-to-cart**

Replace the `ElevatedButton.icon` add-to-cart block with:

```dart
Expanded(
  flex: 3,
  child: AddToCartButton(
    enabled: !product.isOutOfStock,
    label: product.isOutOfStock ? 'Out of Stock' : 'Add to Cart',
    onPressed: () {
      if (product.isOutOfStock) return;
      cart.addProduct(product, quantity: quantity);
      AddToCartFly.show(
        context,
        imageUrl: product.images.isNotEmpty ? product.images.first : '',
      );
    },
  ),
),
```

Remove the old `ScaffoldMessenger` snackbar for add-to-cart (the fly + button confirmation replace it). Keep the wishlist `OutlinedButton` but replace its `Icon` with a `WishlistHeart`:

```dart
Expanded(
  flex: 1,
  child: OutlinedButton(
    onPressed: () => wishlist.toggle(product.id),
    style: OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: FutureBuilder<bool>(
      future: wishlist.contains(product.id),
      builder: (context, snapshot) {
        final inWishlist = snapshot.data ?? false;
        return WishlistHeart(
          isSelected: inWishlist,
          size: 22,
          onPressed: () => wishlist.toggle(product.id),
        );
      },
    ),
  ),
),
```

- [ ] **Step 5: Run analyze + tests**

Run: `flutter analyze`
Run: `flutter test test/customer/catalog/product_detail_gallery_test.dart test/customer/catalog/product_detail_reviews_test.dart`
Run: `flutter test`
Expected: PASS. If the gallery no-image test now finds two `Icons.checkroom` (one from the Hero container placeholder and one from `ProductImageReveal`), render the no-image placeholder in `_Gallery` directly (blush container + `Icons.checkroom`) so exactly one icon matches.

- [ ] **Step 6: Commit**

```bash
git add lib/customer/catalog/product_detail_screen.dart
git commit -m "feat(detail): hero transition, shade selector, add-to-cart fly"
```

---

### Task 13: Cart — images, totals, transitions

**Files:**
- Modify: `lib/customer/cart/cart_screen.dart`

**Interfaces:**
- Consumes: `ProductImageReveal`, `AnimatedCounter`, `presentationFor`, `QtMotion`.

- [ ] **Step 1: Product images in cart tiles**

In `_CartItemTile`, replace the static icon container (width 72, height 72) with:

```dart
SizedBox(
  width: 72,
  height: 72,
  child: ProductImageReveal(
    imageUrl: item.product.images.isNotEmpty ? item.product.images.first : '',
    borderRadius: BorderRadius.circular(12),
    presentation: presentationFor(
      categorySlug: item.product.categorySlug,
      categoryId: item.product.categoryId,
    ),
  ),
),
```

- [ ] **Step 2: Animated totals**

In `_CartSummary`, wrap the Subtotal and Total values with `AnimatedCounter`:

```dart
AnimatedCounter(
  value: cart.subtotal,
  format: (v) => '\$${v.toStringAsFixed(2)}',
  style: const TextStyle(fontWeight: FontWeight.w600),
),
```

and for the total row:

```dart
AnimatedCounter(
  value: cart.subtotal + shipping,
  format: (v) => '\$${v.toStringAsFixed(2)}',
  style: TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 16,
    color: QueensTouchColors.plum,
  ),
),
```

`_SummaryRow` already handles the layout; pass the `AnimatedCounter` as the `value` widget. Change `_SummaryRow.value` to a `Widget` type (`required this.value` stays a `Widget`; update the `Text(...)` rendering to `value`).

- [ ] **Step 3: Item add/remove transitions**

Wrap each `_CartItemTile` in `AnimatedSize`+`AnimatedSwitcher` is heavy for a list; instead wrap the tile in `TweenAnimationBuilder<double>` keyed by `ValueKey('${item.product.id}-${item.variant?.id}')` that fades in on first appearance:

```dart
itemBuilder: (context, index) => TweenAnimationBuilder<double>(
  key: ValueKey('cart-item-${cart.items[index].product.id}-${cart.items[index].variant?.id}'),
  tween: Tween(begin: 0.0, end: 1.0),
  duration: QtMotion.normal,
  curve: QtMotion.signature,
  builder: (context, v, child) => Opacity(
    opacity: v,
    child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: child),
  ),
  child: _CartItemTile(item: cart.items[index]),
),
```

- [ ] **Step 4: Empty-cart cross-fade**

Wrap the empty-state branch and the populated branch in an `AnimatedSwitcher(duration: QtMotion.normal)` keyed by `cart.isEmpty`.

- [ ] **Step 5: Run analyze + tests**

Run: `flutter analyze`
Run: `flutter test`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/customer/cart/cart_screen.dart
git commit -m "feat(cart): product images, animated totals and item transitions"
```

---

### Task 14: Wishlist — images + animated hearts

**Files:**
- Modify: `lib/customer/wishlist/wishlist_screen.dart`

**Interfaces:**
- Consumes: `ProductImageReveal`, `WishlistHeart`, `presentationFor`.

- [ ] **Step 1: Product images + heart in wishlist tiles**

In `_WishlistTile`, replace the static icon container with `ProductImageReveal` (72×72, like cart). Replace the delete `IconButton` icon with a `WishlistHeart(isSelected: true, size: 22, onPressed: () => wishlist.remove(product.id))` while keeping the icon color `QueensTouchColors.danger`.

- [ ] **Step 2: Run analyze + tests**

Run: `flutter analyze`
Run: `flutter test`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add lib/customer/wishlist/wishlist_screen.dart
git commit -m "feat(wishlist): product images and animated hearts"
```

---

### Task 15: Checkout confirmation — elegant reveal

**Files:**
- Modify: `lib/customer/checkout/checkout_screen.dart`

**Interfaces:**
- Consumes: `BeautyReveal`, `StaggerReveal`, `QueensTouchTheme.brandSerif`.

- [ ] **Step 1: Reveal the confirmation screen**

In `_ConfirmationScreen`, wrap the content column in `BeautyReveal(child: ...)`, and wrap the thank-you headline in a serif:

```dart
Text(
  'Thank you, ${order.customerName}!',
  style: QueensTouchTheme.brandSerif(fontSize: 26, weight: FontWeight.w700),
  textAlign: TextAlign.center,
),
```

Keep the check icon, order card, pay instructions (Paybill 222111 / Account 65727) and "Continue Shopping" button unchanged.

- [ ] **Step 2: Keep checkout form calm**

Do not add animation to the form fields or payment method radios. Only the confirmation screen gets the reveal.

- [ ] **Step 3: Run analyze + tests**

Run: `flutter analyze`
Run: `flutter test`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/customer/checkout/checkout_screen.dart
git commit -m "feat(checkout): elegant confirmation reveal"
```

---

### Task 16: Submit payment + order detail — payment flow, timeline, installment progress

**Files:**
- Modify: `lib/customer/orders/submit_payment_screen.dart`
- Modify: `lib/customer/orders/order_detail_screen.dart`

**Interfaces:**
- Consumes: `OrderTimeline`, `PaymentStatusFlow`, `AnimatedCounter`, `QtMotion`.

- [ ] **Step 1: Submit payment — polished submit + pending confirmation**

In `submit_payment_screen.dart`, after a successful `_submit()`, the screen already pops with a success snackbar. Add an `AnimatedSwitcher` confirmation on the submit button (reuse `AddToCartButton`? No — keep the existing button but add a brief "Submitted ✓" confirmation using `AnimatedSwitcher`, or simply rely on the snackbar). Minimal change: replace the snackbar with `showSuccessSnack(context, 'Payment submitted for verification');` (already present) and wrap the "How to pay" card in a `BeautyReveal` so the paybill details (222111 / 65727) make an elegant entrance.

- [ ] **Step 2: Order detail — status timeline**

In `_StatusHeaderCard` in `order_detail_screen.dart`, replace the two status chips block with:

```dart
OrderTimeline(status: order.status),
const SizedBox(height: 12),
PaymentStatusFlow(status: order.paymentStatus),
```

Keep the order number, divider and total row. Keep the two `_StatusChip`s too (information must remain text-based) — render the chips in a `Row` above the timeline if desired; do not remove status text.

- [ ] **Step 3: Animated payment summary numbers**

In `_PaymentSummaryCard`, wrap each `_SummaryRow` value with `AnimatedCounter` (format via `formatKsh`):

```dart
AnimatedCounter(
  value: summary.verified,
  format: formatKsh,
  style: const TextStyle(fontWeight: FontWeight.w600, color: QueensTouchColors.success),
),
```

Change `_SummaryRow.value` to a `Widget` and pass the `AnimatedCounter` for all three rows (verified / pending / remaining).

- [ ] **Step 4: Installment progress bar**

In `_InstallmentCard`, after the status chip, add an animated progress bar:

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(6),
  child: TweenAnimationBuilder<double>(
    tween: Tween(
      end: plan.totalAmount <= 0 ? 0 : (plan.amountPaid / plan.totalAmount).clamp(0.0, 1.0),
    ),
    duration: QtMotion.normal,
    curve: QtMotion.signature,
    builder: (context, v, _) => LinearProgressIndicator(
      value: v,
      minHeight: 8,
      backgroundColor: const Color(0xFFEEDFE4),
      color: QueensTouchColors.success,
    ),
  ),
),
```

Keep the "Total / Paid" text and the schedule rows (checkmarks are already state-based).

- [ ] **Step 5: Run analyze + tests**

Run: `flutter analyze`
Run: `flutter test test/customer/orders/order_detail_screen_test.dart`
Run: `flutter test`
Expected: PASS (the order detail test checks for `KSh` texts and a `Pay` button — both preserved).

- [ ] **Step 6: Commit**

```bash
git add lib/customer/orders/submit_payment_screen.dart lib/customer/orders/order_detail_screen.dart
git commit -m "feat(orders): order timeline, payment flow, animated installment progress"
```

---

### Task 17: Write review — animated star selection

**Files:**
- Modify: `lib/customer/catalog/write_review_screen.dart`

**Interfaces:**
- Consumes: `AnimatedStarRating`.

- [ ] **Step 1: Use `AnimatedStarRating`**

Replace the manual `for (var i = 1; i <= 5; i++) IconButton(...)` star row with:

```dart
AnimatedStarRating(
  rating: _rating,
  enabled: !_submitting,
  onChanged: (v) => setState(() => _rating = v),
),
```

Keep the "N out of 5" caption below it.

- [ ] **Step 2: Run analyze + tests**

Run: `flutter analyze`
Run: `flutter test test/customer/catalog/write_review_screen_test.dart`
Run: `flutter test`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add lib/customer/catalog/write_review_screen.dart
git commit -m "feat(reviews): animated star rating"
```

---

### Task 18: Admin dashboard — animated stats and chart

**Files:**
- Modify: `lib/admin/dashboard/dashboard_screen.dart`

**Interfaces:**
- Consumes: `AnimatedCounter`, `AnimatedBarChart`, `formatKsh`.

- [ ] **Step 1: Animate stat values**

In `_StatTile`, wrap `stat.value` in `AnimatedCounter` for numeric values. Values like `KSh 48,290.00` are already formatted strings; instead animate the raw value. Change `StatCard` construction to pass numeric `value` and a `format`:

- Add `final double value;` and `final String Function(double) format;` to `StatCard` (drop `final String value;`).
- In `_DashboardScreenState._buildBody`, construct each stat card with `value:` and `format:`:

```dart
StatCard(
  label: 'Total Revenue',
  value: sales.totalRevenue,
  format: formatKsh,
  icon: Icons.attach_money,
  color: QueensTouchColors.success,
),
StatCard(label: "Today's Sales", value: sales.todayRevenue, format: formatKsh, icon: Icons.today, color: QueensTouchColors.plum),
StatCard(label: 'Total Orders', value: sales.totalOrders.toDouble(), format: (v) => v.round().toString(), icon: Icons.receipt_long, color: Colors.blue),
StatCard(label: 'Total Customers', value: data.customers.totalCustomers.toDouble(), format: (v) => v.round().toString(), icon: Icons.people, color: QueensTouchColors.warning),
StatCard(label: 'Total Products', value: data.inventory.totalProducts.toDouble(), format: (v) => v.round().toString(), icon: Icons.inventory_2, color: QueensTouchColors.gold),
StatCard(label: 'Pending Orders', value: sales.pendingOrders.toDouble(), format: (v) => v.round().toString(), icon: Icons.pending_actions, color: QueensTouchColors.warning),
StatCard(label: 'Low Stock', value: data.inventory.lowStock.toDouble(), format: (v) => v.round().toString(), icon: Icons.warning_amber, color: QueensTouchColors.danger),
StatCard(label: 'Out of Stock', value: data.inventory.outOfStock.toDouble(), format: (v) => v.round().toString(), icon: Icons.block, color: QueensTouchColors.danger),
```

- In `_StatTile.build`, replace `Text(stat.value, ...)` with:

```dart
AnimatedCounter(
  value: stat.value,
  format: stat.format,
  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
),
```

- [ ] **Step 2: Animate the sales-trend chart**

In `_SalesTrendChart`, replace the bar rendering block (the `Row` of `Container`s inside the `SizedBox(height: 120, ...)`) with `AnimatedBarChart`:

```dart
AnimatedBarChart(
  values: trend,
  labels: [for (var i = 1; i <= trend.length; i++) '$i'],
  height: 120,
  barRadius: 4,
)
```

- [ ] **Step 3: Run analyze + tests**

Run: `flutter analyze`
Run: `flutter test test/admin/dashboard_screen_test.dart`
Run: `flutter test`
Expected: PASS. The dashboard test expects `find.text('KSh 48,290.00')` and `find.text('KSh 0.00')` after `pumpAndSettle` — `AnimatedCounter` settles at the final formatted value, so these still match.

- [ ] **Step 4: Commit**

```bash
git add lib/admin/dashboard/dashboard_screen.dart
git commit -m "feat(dashboard): animated statistics and chart entrance"
```

---

### Task 19: Reports — polished presentation

**Files:**
- Modify: `lib/admin/reports/reports_screen.dart`

**Interfaces:**
- Consumes: `AnimatedCounter`, `AnimatedBarChart`.

- [ ] **Step 1: Animate stat values in the sales body**

In `_salesBody`, wrap the summary stat values (Total revenue, Today's sales, Orders, Average order value, etc.) in `AnimatedCounter` with `format: formatKsh` (for money) and `(v) => v.round().toString()` (for counts). Locate the stat `Text`s inside `_salesBody` and replace them; do not change the layout or labels.

- [ ] **Step 2: Animate the sales trend chart if present**

If `_salesBody` (or the products body) renders a daily trend bar chart, replace it with `AnimatedBarChart(values: [...], labels: [...])`. If the screen renders trend data as a table only, skip the chart change (nothing to animate) and rely on the animated counters.

- [ ] **Step 3: Smooth filter transitions**

The section/range `ChoiceChip` changes already rebuild via `_reload()` with a `FutureBuilder`. Add a lightweight `AnimatedSwitcher(duration: QtMotion.normal)` around `_buildBody()` keyed by `ValueKey('$_selected-$_rangeIndex')` so section changes cross-fade instead of snapping.

- [ ] **Step 4: Run analyze + tests**

Run: `flutter analyze`
Run: `flutter test test/admin/reports_screen_test.dart`
Run: `flutter test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/admin/reports/reports_screen.dart
git commit -m "feat(reports): animated statistics and smooth section transitions"
```

---

### Task 20: Notifications badge + admin product form reorder

**Files:**
- Modify: `lib/customer/customer_shell.dart`
- Modify: `lib/customer/account/account_screen.dart` (NotificationsScreen)
- Modify: `lib/admin/products/product_form_screen.dart`

**Interfaces:**
- Consumes: `QtMotion`, `AnimatedSwitcher`.

- [ ] **Step 1: Subtle unread-badge emphasis**

In `customer_shell.dart`, wrap the notification `Badge` in an `AnimatedSwitcher(duration: QtMotion.fast)` keyed by `ns.unreadCount`, so the badge count eases in when new notifications arrive. Do not pulse continuously.

In `NotificationsScreen` (in `account_screen.dart`), wrap each notification tile in a `TweenAnimationBuilder` fade-in keyed by the notification id (same pattern as Task 13 step 3), using `QtMotion.normal`.

- [ ] **Step 2: Admin product form — reorder picked images**

In `product_form_screen.dart`, for the picked-image preview tiles (`for (var i = 0; i < _picked.length; i++)`), add move-left/right controls below the thumbnail:

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    IconButton(
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.arrow_back, size: 14),
      onPressed: i == 0
          ? null
          : () => setState(() {
                final tmp = _picked[i];
                _picked[i] = _picked[i - 1];
                _picked[i - 1] = tmp;
              }),
    ),
    IconButton(
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.arrow_forward, size: 14),
      onPressed: i == _picked.length - 1
          ? null
          : () => setState(() {
                final tmp = _picked[i];
                _picked[i] = _picked[i + 1];
                _picked[i + 1] = tmp;
              }),
    ),
  ],
)
```

Upload order (first → last) maps to `position` on the backend, so reordering picked images controls image order. Existing-image management (delete / set primary) is unchanged. No backend reorder endpoint is added (out of scope).

- [ ] **Step 3: Run analyze + tests**

Run: `flutter analyze`
Run: `flutter test`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/customer/customer_shell.dart lib/customer/account/account_screen.dart lib/admin/products/product_form_screen.dart
git commit -m "feat(polish): subtle notification badge, picked-image reorder"
```

---

### Task 21: Final verification + report

**Files:**
- None (verification only).

- [ ] **Step 1: Run the full Flutter checks**

Run: `flutter analyze`
Expected: No issues.

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 2: Run the full backend checks**

Run: `npm run typecheck`
Run: `npm test`
Expected: PASS.

- [ ] **Step 3: Fix any regressions**

If any test or analyzer issue was introduced, fix it in a follow-up commit:

```bash
git add .
git commit -m "fix: resolve post-branding regressions"
```

- [ ] **Step 4: Deliver the final report**

Report to the user (concise, per the spec's section 38):
1. Screens enhanced.
2. Brand-specific animations implemented.
3. Fashion-specific animations implemented.
4. Cosmetics-specific animations implemented.
5. Dynamic product-image support verified (API mode).
6. Admin gallery upload verified (existing pipeline + picked-image reorder).
7. Reusable animation components created (list).
8. Dependencies added (`google_fonts` only).
9. Performance considerations.
10. Accessibility considerations.
11. `flutter analyze` result.
12. `flutter test` result.
13. Manual device testing — left to the user (list the manual checklist from the spec §37).
14. Remaining limitations.

STOP after the report. Do not move on to unrelated features.