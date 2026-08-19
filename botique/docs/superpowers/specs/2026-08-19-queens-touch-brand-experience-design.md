# Queens' Touch — Premium Brand Experience, Signature Animations & Dynamic Product Imagery

Date: 2026-08-19
Status: Approved (design)
Author: opencode session, working from the Queens' Touch spec

## 1. Overview

Transform the existing Queens' Touch Flutter boutique from a functional ecommerce
app into a memorable, premium **fashion + beauty editorial** experience. The
visual language and animation are inspired by the products themselves:

- **Fashion** (clothing): flowing fabric, garment reveals, editorial lookbooks,
  elegant reveals, parallax.
- **Beauty** (cosmetics): lipstick shade reveals, liquid/blending movement,
  powder/soft reveals, mist for perfume, fluid skincare motion.

Key constraints from the brief:

- Quality over quantity. Five excellent brand-specific animations beat fifty
  generic ones. No fade/slide-everywhere, no confetti, no children's-app feel.
- Animation must work on **dynamically uploaded product images** (admin uploads
  from the phone gallery). No hardcoded filenames, no `assets/`-bundled products.
- The uploaded image itself is never permanently modified; animation happens
  around / during presentation (masks, clipping, parallax, scale, opacity,
  layered overlays).
- Existing functionality must not break: PostgreSQL, backend/API, product CRUD,
  image upload, cart, wishlist, checkout, orders, payments, installments,
  reviews, reports, notifications, admin, auth.

## 2. Current State (verified during exploration)

- Flutter app using `provider` + `go_router`. Entry: `lib/main.dart`.
  Repositories/services are wired via `MultiProvider`.
- Backend: Express + TypeScript + PostgreSQL under `backend/`.
- **Image upload pipeline already fully works end-to-end:**
  - Admin `ProductFormScreen` (`lib/admin/products/product_form_screen.dart`)
    uses `image_picker` `pickMultiImage()`, previews picked images, allows
    removing a picked image, uploads via `AdminCatalogService.uploadImages`
    (multipart POST `/api/products/:id/images`), displays existing images,
    supports deleting an image and setting a primary image.
  - Backend stores files under `/images/<filename>` and returns image URLs on
    the product. `Product.images` is `List<String>` (URLs).
  - No reorder API exists. Reorder of **picked (not yet uploaded) images** is a
    client-side concern only.
- Categories are hierarchical with slugs:
  - Root `clothing` → `clothing-dresses`, `clothing-tops`, `clothing-jackets`,
    `clothing-trousers`, `clothing-jeans`, `clothing-skirts`, `clothing-sweaters`,
    `clothing-jumpsuits`, `clothing-activewear`, `clothing-loungewear`.
  - Root `beauty` → `beauty-makeup`, `beauty-lip`, `beauty-foundation`,
    `beauty-concealer`, `beauty-blush`, `beauty-eyeshadow`, `beauty-mascara`,
    `beauty-skincare`, `beauty-body`, `beauty-hair`, `beauty-accessories`.
  - The **product API payload exposes only the UUID `categoryId`, not the
    category slug** (`backend/src/repositories/productRepository.ts`).
- Payment matches the brief already: Family Bank M-Pesa Paybill **222111**,
  Account **65727**. Customer pays externally, submits the confirmation message;
  admin verifies/rejects. No M-Pesa API integration exists (correct).
- Screens are flat; there are **no animations** today.
- Currency inconsistency exists (catalog uses `$`, orders use KSh). Out of scope;
  left untouched.
- Existing test suite is solid (`test/` includes product detail gallery, order
  detail, dashboard, reports, api repository tests). Must remain green.

## 3. Confirmed Decisions

1. **Run mode:** live backend (`--dart-define=USE_API=true`). Real uploaded
   images will display. Mock-mode placeholders must still look premium.
2. **Typography:** add `google_fonts` dependency; introduce an elegant editorial
   serif (Cormorant Garamond) for brand moments, paired with the existing sans
   for body/UI. This is the **only new dependency**.

## 4. Brand Foundation

### 4.1 Typography (`lib/core/theme/theme.dart` + `lib/core/theme/brand_text.dart`)

- Add `google_fonts`. Define a display serif family (Cormorant Garamond,
  weights 500/600/700) used for: the `Queens' Touch` wordmark, hero headlines,
  section titles, key editorial moments.
- Body and interactive text keep the Material default (sans) for readability.
- Apply via `ThemeData` text theme overrides (extend, do not replace).

### 4.2 Motion tokens (`lib/core/animations/qts_animation.dart`)

Central constants/curves so the whole app shares a consistent feel:

- `kQtDurationFast = 250ms`, `kQtDuration = 400ms`, `kQtDurationSlow = 650ms`.
- `kQtEaseOut = Curves.easeOutCubic`, `kQtEaseInOut = Curves.easeInOutCubic`,
  a signature `QtCurves.signature` (gentle overshoot-free ease) for reveals.
- `QtMotion.shouldReduceMotion(context)` → true when
  `MediaQuery.disableAnimationsOf(context)`; callers then skip or drastically
  shorten animations. Information is never conveyed by animation alone.

## 5. Category-Aware Presentation Engine

### 5.1 Minimal additive backend change

Expose the category slug on product payloads so the app can classify any
product (current and future admin-uploaded) without hardcoding IDs:

- `backend/src/repositories/productRepository.ts`:
  - `search(...)`: change `SELECT p.* FROM products p` → add
    `LEFT JOIN categories c ON c.id = p.category_id` and select
    `c.slug AS category_slug`.
  - `findById(...)`: same JOIN.
  - `mapProductRow(...)`: add `categorySlug: row.category_slug`.
- `Product` interface (`backend/src/repositories/productRepository.ts`): add
  `categorySlug: string`.
- No new tables, no new endpoints, no changes to the image pipeline, no changes
  to create/update/delete. Purely additive.

### 5.2 Flutter model

- `Product` (`lib/models/product.dart`): add `categorySlug` field, parsed from
  JSON (`json['categorySlug']`); default `''` (mock data uses slug-style
  categoryIds, so the classifier also falls back to `categoryId`).

### 5.3 Classifier (`lib/core/animations/product_presentation.dart`)

- `enum ProductPresentation { fashion, lip, foundation, powder, eyeshadow,
  skincare, perfume, hair, accessory, generic }`.
- `ProductPresentation presentationFor({String categorySlug, String categoryId,
  String categoryName})` with precedence:
  1. explicit slug matches (`beauty-lip` → lip, `beauty-foundation` → foundation,
     `beauty-blush` → powder, `beauty-eyeshadow` → eyeshadow,
     `beauty-skincare` → skincare, `perfume`/`fragrance` → perfume,
     `beauty-hair` → hair, `clothing*` → fashion, `beauty-accessories` or
     accessory-ish → accessory).
  2. substring checks on slug (e.g. contains `lip` → lip, `foundation` →
     foundation, `skincare`/`skin` → skincare).
  3. fallback by name keywords (e.g. `lipstick`, `foundation`, `perfume`).
  4. final fallback → `generic` (elegant default presentation).
- Pure Dart, unit-testable. No product IDs, no filenames.

## 6. Reusable Animation Components

New module `lib/core/animations/` (naming consistent with existing `core/`
conventions). Each component is a small `StatelessWidget`/`StatefulWidget`
driven by a one-shot `AnimationController`.

### 6.1 `ProductImageReveal`

The workhorse for every product image (cards, gallery, cart, wishlist, admin
tiles). Behavior:

- **Loading:** elegant skeleton placeholder (soft shimmer/breathing, not
  pulsing aggressively) sized to the box.
- **Loaded:** smooth fade + subtle scale reveal when the frame is available
  (`Image.network` + `frameBuilder`, `gaplessPlayback: true`).
- **Failed:** refined fallback (monogram + "image unavailable"), never crashes.
- **No image:** premium Queens' Touch placeholder (brand monogram on blush
  gradient, category-aware glyph). In mock mode this is what users see.
- **Category-aware overlay:** for fashion, a soft editorial sweep across the
  image on reveal; for cosmetics, a gentle radial glow / soft mist veil.
- Accepts the image URL, `fit`, an optional `heroTag`, and the presentation type.

### 6.2 `FashionReveal` / `BeautyReveal`

- `FashionReveal`: editorial layered reveal — masked wipe + subtle
  scale/parallax. Used for fashion heroes, collection headers, garment reveals.
- `BeautyReveal`: soft radial glow bloom + gentle float; smooth, never cartoonish.

### 6.3 `MistParticles`

Delicate, low-density floating particles (for perfume presentation) using a
handful of `AnimatedBuilder`-driven opacity/position particles. Always subtle;
disabled under reduced motion.

### 6.4 `StaggerReveal`

Scroll/entrance-aware staggered reveal for collections and grids. Items
translate+fade in once with a short per-item stagger. Runs on first appearance;
does not replay on every scroll pass.

### 6.5 `PressScale`

Refined press feedback: the child scales to ~0.98 with opacity ease on
tap-down and springs back. Applied to product cards and key tappables — not
every button.

### 6.6 `AnimatedCounter`

Smooth number transitions (`TweenAnimationBuilder`-style) used for KSh totals,
stats, counts. Animates value changes; skips animation under reduced motion.

### 6.7 `AddToCartFly`

Add-to-cart feedback:
1. Product image/badge subtly flies toward the cart area.
2. Button morphs to a short "Added ✓" confirmation then reverts.
Fast (≤600ms), non-blocking. Implemented as a local overlay; no dependency on
cart badge position (keeps it simple and robust).

### 6.8 `WishlistHeart`

Heart tap: subtle scale bounce + gentle gold/rose glow + selected state.
No cartoon explosions. Uses the existing `WishlistService.toggle` result.

### 6.9 `ShadeSelector`

Animated shade/color selection for cosmetics:
- Color-aware chip (uses a small built-in palette map for common shade names,
  else a neutral chip with the shade label).
- Animated selection indicator (fill + ring) and a smooth product-preview
  transition when the selected shade changes.
- Fast, clear which shade is selected (accessibility: label always visible).

### 6.10 `OrderTimeline`

Refined order-progress timeline: Pending → Paid → Processing → Ready →
Delivered. Animated fill between reached milestones; communicates progress
without distracting. Also used (simplified) for payment status:
submitted → pending verification → verified / rejected.

### 6.11 `AnimatedStarRating`

Star selection for reviews: smooth star appearance, subtle scale on the tapped
star. Submission shows a subtle confirmation state.

### 6.12 `AnimatedBarChart`

Chart bars/segments animate into their heights once when first displayed.
Used in admin dashboard and reports. Replays only on data/filter change
(reduced under reduced motion).

## 7. Screen Integration Plan

Priority order follows the brief's section 36.

### 7.1 Home (`lib/customer/home/home_screen.dart`)

Rebuild as a premium digital boutique with the existing data/services:

1. **Hero** — fashion-campaign hero: serif headline with staggered
   letter/line reveal, subtle parallax on the hero panel, layered composition
   (brand pattern overlay), "Shop Now" CTA. Uses `FashionReveal`.
2. **New Collection** — editorial section: collection image/title reveals
   (serif title, supporting text, then products) with staggered entry
   (`CollectionReveal` style, `StaggerReveal`).
3. **Shop by Category** — category chips with gentle entrance; cosmetic
   categories get the beauty treatment.
4. **Featured / New Arrivals / Best Sellers / Trending / Recommended** —
   horizontal product rows with `ProductImageReveal` cards and staggered
   entrances; category-aware presentation per product.
5. **Promotions** — offer banner with a tasteful reveal.
6. Keep `_NewsletterSection` and `_FooterSection` clean (no animation).

Data flow unchanged: `CatalogService.loadHome()` feeds the same lists.

### 7.2 Product card (`lib/core/widgets/product_card.dart`)

- `ProductImageReveal` replaces the raw `Image.network`/placeholder.
- `PressScale` for tap feedback; category-aware presentation.
- Card entrance via `StaggerReveal` when in grids/rows.
- Discount/`NEW` badges kept; badge appearance may animate subtly on entrance.
- Wishlist heart available on the card (uses `WishlistHeart` + `WishlistService`).

### 7.3 Catalog / discovery (`lib/customer/catalog/catalog_screen.dart`)

- `_ProductGrid` cards get staggered entrance on first load and on filter/sort
  change (lightweight; not on every rebuild).
- Search/sort/filter bars stay clean.

### 7.4 Product detail (`lib/customer/catalog/product_detail_screen.dart`)

- **Hero/shared-element transition** from the tapped card image to the gallery.
  Implementation: give the card's `ProductImageReveal` container a `heroTag`
  and give the gallery container the same tag. The destination `Hero` wraps the
  gallery container itself (blush surface + reveal), so it exists on the
  destination's first frame even while `getProduct` is still loading — the
  flight always runs and resolves into the loaded image.
- Gallery uses `ProductImageReveal` per page; category-aware presentation.
- `ShadeSelector` for shades; `_VariantSection` for sizes gets fast, subtle
  press feedback (no over-animation).
- Quantity stepper gets smooth value transitions (small).
- **Add to cart:** `AddToCartFly` + button confirm; cart badge updates via
  existing `CartService`.
- Wishlist button uses `WishlistHeart`.
- Reviews section: keep functional; star tiles already static (fine).
- Product remains the visual focus; no perpetual motion.

### 7.5 Cart (`lib/customer/cart/cart_screen.dart`)

- Cart tiles show real product images via `ProductImageReveal` (currently a
  static icon).
- Animated item entrance on add, and a smooth removal/exit transition.
- Quantity changes transition smoothly.
- Total uses `AnimatedCounter`.
- Empty-cart transition is a graceful cross-fade to the empty state.

### 7.6 Wishlist (`lib/customer/wishlist/wishlist_screen.dart`)

- Product images via `ProductImageReveal`.
- Heart/remove interactions use `WishlistHeart` and smooth list updates.

### 7.7 Checkout (`lib/customer/checkout/checkout_screen.dart`)

- Calm and trustworthy. Only an elegant confirmation-screen reveal after the
  order is placed. Forms untouched.

### 7.8 Payment experience (`lib/customer/orders/submit_payment_screen.dart`)

- Polished visual states: submitted → pending verification → verified, and
  submitted → rejected, using the existing status data (`PaymentStatus`,
  order `paymentStatus`). `OrderTimeline`-style progress, not a fake success.
- Keep the Paybill 222111 / Account 65727 instructions prominent.
- No M-Pesa API integration (unchanged).

### 7.9 Order detail (`lib/customer/orders/order_detail_screen.dart`)

- `OrderTimeline` for order status.
- Payment summary numbers use `AnimatedCounter`.
- Installment card: animated progress bar (verified / remaining), animated
  schedule checkmarks when paid. Data unchanged (`OrderRepository`).

### 7.10 Write review (`lib/customer/catalog/write_review_screen.dart`)

- `AnimatedStarRating` for selection; subtle confirmation on submit.

### 7.11 Admin dashboard (`lib/admin/dashboard/dashboard_screen.dart`)

- Stat cards count up via `AnimatedCounter` on first display.
- Sales-trend bars animate to height once (`AnimatedBarChart`).
- Pending cards get a gentle emphasis (no constant pulsing).
- Remains professional, never game-like.

### 7.12 Reports (`lib/admin/reports/reports_screen.dart`)

- Chart entry animation on first display; smooth filter transitions;
  animated statistic changes. No replay of large animations unnecessarily.

### 7.13 Notifications (`lib/customer/account/account_screen.dart` + `lib/customer/customer_shell.dart`)

- Subtle unread-badge emphasis only; no constant pulsing. Notification list
  items may fade in.

### 7.14 Admin product form (`lib/admin/products/product_form_screen.dart`)

- Add client-side **reorder** for picked (not-yet-uploaded) images (move
  left/right arrows on the preview tiles) — upload order determines `position`.
- Existing-image management (delete / set primary) unchanged.
- Upload flow otherwise unchanged (uses `AdminCatalogService.uploadImages`).

### 7.15 Admin shell / product list (`lib/admin/`)

- Keep clean; product list tiles may use `ProductImageReveal` if images are
  shown (consistent loading/error behavior).

## 8. Non-Goals / Out of Scope

- No backend architecture changes beyond the additive `categorySlug` field.
- No M-Pesa API integration; payment stays manual + admin verification.
- No currency unification ($ vs KSh) — pre-existing inconsistency, untouched.
- No reorder of already-uploaded images (no backend reorder endpoint).
- No mock data for production; animations run on real API data in API mode.
- No new product/image repository or second upload system.

## 9. Performance

- One-shot animations with short durations (250–650ms); no infinite loops,
  no constant repaints, no excessive battery use.
- `RepaintBoundary` around animated/overlaid regions.
- `ProductImageReveal` uses `Image.network` caching + `cacheWidth` on cards to
  bound decode memory; no `cached_network_image` dependency.
- Reduced-motion check short-circuits heavy effects.
- Keep scrolling smooth: stagger only on first appearance.

## 10. Accessibility

- Respect `MediaQuery.disableAnimations` (reduced motion) globally.
- Information (selected shade/size, payment status, order status, success,
  failure, loading) is always conveyed by text/state, never by animation alone.
- Contrast and touch targets preserved.
- Semantics labels added where animation components obscure meaning.

## 11. Dependencies

- **Add:** `google_fonts` (only for the editorial serif). Documented here.
- **No other new dependencies.** All animation built on Flutter's built-in
  `AnimationController`/`Tween` APIs. `image_picker`, `http`, `provider`,
  `go_router` reused as-is.

## 12. Testing

- Unit tests: `ProductPresentation` classifier (slugs, substrings, name
  fallback, generic fallback); `Product.fromJson` `categorySlug` parsing.
- Keep the full existing suite green.
- Run `flutter analyze` and `flutter test`; fix all issues introduced.
- Manual on-device verification (by the human partner) against the live
  backend: admin gallery upload, uploaded images display, fashion vs cosmetic
  presentation, product detail, cart, checkout, payment submission,
  installments, reviews, orders, reports, notifications, auth.

## 13. Final Report

After implementation, deliver the report requested by the brief: screens
enhanced; brand/fashion/cosmetic animations; dynamic image support verified;
admin upload verified; reusable components; dependencies; performance;
accessibility; `flutter analyze` result; `flutter test` result; manual device
testing status; remaining limitations.