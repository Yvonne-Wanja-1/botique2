# Persistent Login Fix + Theme Refinement

Two work items:
1. Fix the persistent login bug (users forced to re-login on every app restart)
2. Refine the color palette to match the Quiet Luxury spec

---

## Task A: Fix Persistent Login

### Problem

Users report: "everytime I run the app, I am forced to sign in yet im already registered."

The system has the right architecture (flutter_secure_storage, restoreSession, _applyAuthPayload) but sessions are being destroyed on restart.

### Root Cause Analysis

`AuthService.restoreSession()` flow (auth_service.dart:155-185):
1. Reads token + user from SecureTokenStorage
2. Sets authenticated, notifies
3. Calls `_validateSession()` → `GET /api/auth/me`
4. On 401/403 → `_clearSession()` → destroys the persisted token
5. On network error → keeps cached session (good)

**Root cause:** `_validateSession()` calls `GET /api/auth/me` which hits the authenticate middleware. If the server returns 401 (expired JWT, user deleted, JWT secret mismatch), the session is immediately destroyed. The catch block on line 201 only preserves the session for non-ApiException errors (network failures), NOT for 401 responses.

Additionally, demo mode (`_api == null`) never persists to secure storage (register at line 233-246 just sets in-memory state), so sessions never survive restart in mock mode.

### Plan

#### Step 1: Make `_validateSession()` resilient (auth_service.dart)

Change `_validateSession()` to:
- On 401/403: **Keep the cached session** instead of clearing. Real 401s during normal API usage will be caught by `ApiClient.onUnauthorized` → `handleUnauthorized()` → `_clearSession()`. The startup validation should not be the clearing mechanism.
- On success: update user data from server (already works).
- On network error: keep cached session (already works).

This means: if the server is down or returns a generic 401 at startup, the user stays logged in. They only get logged out when a real API call returns 401 during normal usage (existing behavior via `onUnauthorized`).

#### Step 2: Fix demo mode persistence (auth_service.dart)

In `register()` when `_api == null`:
- After creating the local user, persist user JSON to `_storage` so the session survives restart.

In `restoreSession()` when `_api == null`:
- Check if a stored user exists. If so, restore it (no server to validate against).

#### Step 3: Add tests (auth_service_test.dart)

- Test: register in demo mode → restoreSession with same storage → session restored.
- Test: register via API → restoreSession → /me returns transient 401 → session preserved.
- Test: register via API → restoreSession → network failure → session preserved.

#### Step 4: Verify

- `flutter test` — all pass
- `flutter analyze` — 0 issues

### Files to Modify

- `lib/services/auth_service.dart`
- `test/services/auth_service_test.dart`

---

## Task B: Refine Theme Colors (Quiet Luxury)

### Current State

Dark theme with gold accents. The user wants to refine to a more sophisticated palette.

### Target Spec

User ratio: Black + Ivory 70%, Gold 15%, Espresso/Taupe 10%, Dusty Rose 5%.

Exact hex values:
- Deep Espresso: #2B211E
- Warm Ivory: #FAF7F2
- Dusty Rose: #B76E79
- Champagne Gold: #C6A15B
- Soft Taupe: #E8DED7
- Rich Charcoal: #24201F
- Warm Gray: #766C67
- Success: #71816C (Muted Sage)
- Error: #A6535C (Muted Berry)

### Color Mapping

Map new hex values onto existing QueensTouchColors names. This keeps all 60+ references across the codebase working without changes.

| Existing Name | Current Hex | New Hex | Spec Name | Usage |
|---|---|---|---|---|
| `cream` | #0A0908 | #1A1611 | — | Scaffold bg (warm black) |
| `plum` | #C6A15B | #2B211E | Deep Espresso | Primary buttons, nav, headings |
| `plumDark` | #0B0B0B | #0F0D0B | — | Deeper black for overlays |
| `plumLight` | #D9BC6B | #3D3228 | — | Elevated dark surfaces |
| `blush` | #2B2419 | #24201F | Rich Charcoal | Card bg, secondary surfaces |
| `blushLight` | #1A1611 | #1F1B18 | — | Subtle surface variation |
| `gold` | #D4AF37 | #C6A15B | Champagne Gold | Luxury accent (15%) |
| `goldLight` | #F0E2C0 | #FAF7F2 | Warm Ivory | Light surfaces, text on dark |
| `textDark` | #F5F0E6 | #FAF7F2 | Warm Ivory | Primary text on dark |
| `textMuted` | #A89B84 | #766C67 | Warm Gray | Secondary text, metadata |
| `success` | #43A068 | #71816C | Muted Sage | Success states |
| `danger` | #E05252 | #A6535C | Muted Berry | Error states |
| `warning` | #E0A93B | #C6A15B | Champagne Gold | Warning (unified with gold) |
| `surfaceLight` | #14100C | #2B211E | Deep Espresso | Input fills, card surfaces |
| `surfaceBorder` | #2E2828 | #3D3228 | — | Borders, dividers |
| `onGold` | #1A1206 | #FAF7F2 | Warm Ivory | Text on gold buttons |

#### New Semantic Aliases (optional, for direct spec reference)

Add to QueensTouchColors for screens that want named spec colors:
```dart
static const Color deepEspresso = Color(0xFF2B211E);
static const Color warmIvory = Color(0xFFFAF7F2);
static const Color dustyRose = Color(0xFFB76E79);
static const Color softTaupe = Color(0xFFE8DED7);
static const Color richCharcoal = Color(0xFF24201F);
```

#### Hardcoded Colors to Update

| File | Line | Current | New | Context |
|---|---|---|---|---|
| `lib/core/widgets/dialogs.dart` | 38 | #2E7D55 | #71816C | Success snackbar bg |
| `lib/core/widgets/dialogs.dart` | 48 | #C0392B | #A6535C | Error snackbar bg |
| `lib/core/animations/order_timeline.dart` | 67 | #EEDFE4 | #E8DED7 | Timeline connector |
| `lib/core/animations/order_timeline.dart` | 188 | #EEDFE4 | #E8DED7 | Unreached node |
| `lib/customer/orders/order_detail_screen.dart` | 374 | #EEDFE4 | #E8DED7 | Progress bar bg |
| `lib/customer/catalog/product_detail_screen.dart` | 542 | #E4D5DA | #E8DED7 | Border color |
| `lib/core/theme/theme.dart` | 121 | #9A7B3C | #C6A15B | Chip selected |

### ThemeData Changes

- `colorScheme.fromSeed` seed: `plum` (now Deep Espresso)
- `elevatedButtonTheme`: bg `plum` (#2B211E), fg `textDark` (#FAF7F2)
- `outlinedButtonTheme`: fg/border `plum` (#2B211E)
- `chipTheme.selectedColor`: `gold` (#C6A15B)
- All other theme properties: update color references as per mapping

### Files to Modify

- `lib/core/theme/theme.dart` — QueensTouchColors + ThemeData
- `lib/core/widgets/dialogs.dart` — 2 hardcoded colors
- `lib/core/animations/order_timeline.dart` — 2 hardcoded colors
- `lib/customer/orders/order_detail_screen.dart` — 1 hardcoded color
- `lib/customer/catalog/product_detail_screen.dart` — 1 hardcoded color

### Verification

- `flutter analyze` — 0 issues
- `flutter test` — all pass (96/96)
- Visual: dark background with warm ivory text, deep espresso buttons, champagne gold accents, dusty rose for beauty states

---

## Execution Order

1. **Task A first** (persistent login) — user-facing bug
2. **Task B second** (theme refinement) — visual polish

Each task gets its own commit. Both must pass analyze + tests.
