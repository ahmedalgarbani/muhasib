# Design System

Reference for the visual language used across the app. Source of truth is the code in `lib/core/theme/`; this document summarizes it for quick lookup.

## Theme Source Files

| File | Purpose |
|---|---|
| `lib/core/theme/app_color.dart` | Color palette (`AppColors`, `AccountColors`) |
| `lib/core/theme/app_text_style.dart` | Typography (`AppTextStyles`) |
| `lib/core/theme/app_radius.dart` | Corner radius scale (`AppRadius`) |
| `lib/core/theme/light_theme.dart` / `dark_theme.dart` | `ThemeData` wiring (Material 3) |

Design language: **Material 3** (`useMaterial3: true`), via `MaterialApp.router` in `lib/main.dart`. No Cupertino widgets. Icons come from the standard Material `Icons` set — no custom icon font.

## Colors (`AppColors`)

- **Brand**: `primary` (#006C35, "Saudi Deep Royal Emerald"), `primaryDark`, `primaryLight`, `primaryAccent`, `primarySurface`.
- **Semantic**: `success`, `warning`, `error`, `info` — each with a `*Light` variant for surfaces/backgrounds.
- **Surface / border / text tokens**: `surfaceLight`/`surfaceDark`, `borderLight`/`borderDark`, `textPrimaryLight`/`textPrimaryDark`, etc. — use these instead of raw hex values so light/dark mode stay consistent.
- **Utility scales**: Tailwind-style ramps (50–900) for `gray`, `slate`, `blue`, `emerald`, `green`, `sky`, `teal`, `red`, `rose`, `pink`, `amber`, `purple`, `violet`, `indigo`. (`grey*` also exists as a legacy duplicate of `gray*` — prefer `gray*`.)
- **`AccountColors`**: background/text/border/icon colors keyed by `AccountType`, used on account cards.

## Typography (`AppTextStyles`)

Named styles rather than a numeric scale. Font family: **Tajawal** (only the Regular weight is currently bundled; other weights are commented out in `pubspec.yaml`).

| Style | Size / Weight | Typical use |
|---|---|---|
| `heading1` | 24 / bold | Page titles |
| `heading2` | 18 / bold | Section titles |
| `titleMedium` | 16 / bold | Card/dialog titles |
| `label` | 14 / w600 | Field labels |
| `labelLarge` | 15 / w600 | Emphasized labels |
| `labelMedium` | 13.5 / w500 | Secondary labels |
| `labelSmall` | 11 / w500 | Captions/tags |
| `body` | 14 / normal | Body text |
| `bodySmall` / `caption` | 12 | Helper/meta text |
| `buttonLarge` | 16 / bold | Primary button text |
| `numberMedium` / `numberLarge` | 15 / 24, bold, letter-spaced | Amounts/statistics |
| `radioActive` / `radioInactive` | 14 / w600 | Radio/segmented option text |

## Spacing

There is no dedicated spacing-constants file in code yet — padding/margins are set ad hoc per widget. To keep spacing consistent going forward, use this scale (multiples of 4, matching common values already seen in the codebase):

| Token | Value | Typical use |
|---|---|---|
| `xs` | 4 | Tight gaps (icon-to-text, chip padding) |
| `sm` | 8 | Gap between related elements (label ↔ value) |
| `md` | 12 | Gap between list/card items |
| `lg` | 16 | Standard screen horizontal padding; vertical padding inside cards/buttons |
| `xl` | 20 | Section padding; vertical padding on larger cards |
| `xxl` | 24 | Gap between distinct sections |
| `xxxl` | 32 | Large vertical separation (e.g. above/below empty states) |

Guidelines:
- **Horizontal padding**: use `lg` (16) for standard screen/page content, `xl` (20) for wider containers (settings cards, forms). Match existing widgets in the same context rather than picking a new value.
- **Vertical padding**: use `sm`–`md` (8–12) inside compact rows/tiles, `lg` (16) inside cards and buttons.
- **Vertical space between elements** (e.g. `SizedBox(height: ...)`): use `sm` (8) between closely related items, `md`–`lg` (12–16) between form fields, `xxl` (24) between sections.
- Avoid arbitrary values (e.g. `13`, `18`, `22`) — round to the nearest token above so spacing stays visually consistent across screens.

## Corner Radius (`AppRadius`)

`xxs` 2, `xs` 4, `sm6` 6, `sm` 8, `sm10` 10, `md` 12, `sm14` 14, `lg` 16, `lg20` 20, `xl` 24, `xl28` 28, `xl30` 30, `xxl` 32.

Applied via theme defaults: cards `lg` (16), buttons/inputs `sm14` (14), chips `xl28` (28), bottom sheets `xl` (24, top corners), dialogs `lg20` (20).

There is no dedicated spacing-constant file — padding/margins are set ad hoc per widget (commonly `EdgeInsets.symmetric(horizontal: 16–20, vertical: 10–14)`).

## Theme Defaults (`light_theme.dart` / `dark_theme.dart`)

- **AppBar**: flat, centered title, elevation 0.
- **Card**: radius `lg` (16), 1px border.
- **Buttons / Inputs**: filled, radius `sm14` (14).
- **Chips**: radius `xl28` (28).
- **Bottom sheets**: top radius `xl` (24), drag handle.
- **Dialogs**: radius `lg20` (20).

## Shared Widgets (`lib/core/widgets/`)

| Widget | Purpose |
|---|---|
| `custom_app_bar.dart`, `app_bar_icon.dart` | Standard app bar and its icon buttons |
| `hasib_button.dart` | Primary button, variants: `primary`/`secondary`/`text`/`danger`/`success` |
| `custom_card_container.dart` | Unified card (radius/background/border/elevation) |
| `custom_list_tile_card.dart` | Master-detail list item card |
| `settings_card.dart`, `settings_navigation_card.dart` | Settings-section cards |
| `custom_text_field.dart`, `text_input_field.dart` | Text inputs |
| `custom_dropdown_field.dart` | Dropdown matching input styling |
| `custom_checkbox_tile.dart`, `custom_switch_tile.dart` | Checkbox/switch list tiles |
| `settings_switch_tile.dart`, `settings_dropdown_tile.dart`, `settings_text_field_tile.dart`, `settings_image_picker_tile.dart` | Settings-page form tiles |
| `custom_dialog.dart`, `custom_confirm_dialog.dart` | Standard modal layout and confirmation dialog |
| `empty_state_widget.dart`, `error_state_card.dart` | Empty/error states with retry |
| `stat_card.dart` | Dashboard stat card |
| `section_header.dart` | RTL section title |
| `detail_row.dart` | Icon/label/value row |
| `pressable_scale.dart` | Press-down scale micro-interaction |
| `barcode_scanner_sheet.dart` | Barcode/QR scan bottom sheet |
| `product_unit_selector.dart`, `unit_picker_page.dart` | Unit selection |
| `root_shell.dart`, `main_drawer/`, `app_drawer_controller.dart` | App-wide navigation shell/drawer |

Feature-local widget sets also exist (e.g. `lib/features/accounts/presentation/widgets/README.md` documents that feature's account cards).

## Conventions

- Always pull colors/text styles/radii from `AppColors` / `AppTextStyles` / `AppRadius` rather than hardcoding values, so light/dark themes stay in sync.
- Prefer existing shared widgets in `lib/core/widgets/` over building new one-off equivalents.
