# AGENTS.md

Flutter/Dart accounting app (muhasib / محاسب). Arabic-first, RTL, multi-feature
business/ERP app. Entrypoint: `lib/main.dart`.

## Commands

- `flutter analyze` — lint/static checks (flutter_lints rules in `analysis_options.yaml`).
- `flutter test` — full suite. Run one file: `flutter test test/path_to_test.dart`.
- `flutter run` — run app (needs a device/emulator; DB uses sqflite with FFI on desktop/web).

## Architecture

- Feature-first layout under `lib/features/<feature>/` with three layers: `data`
  (datasources, repository impls), `domain` (entities, repository interfaces, usecases,
  services), `presentation` (cubit, pages, widgets). Shared infrastructure lives in `lib/core/`.
- State management is **BLoC** (`bloc` / `flutter_bloc` / `hydrated_bloc`). `HydratedBloc.storage`
  is initialized in `main.dart`; many cubits are provided at the root via `MultiBlocProvider`.
- Dependency injection is **get_it**. Every repository/service/cubit must be registered in
  `lib/core/helpers/get_it.dart` (`GetItHelper.init()`); an unregistered lookup fails at runtime.
- Routing is **go_router**, centralized in `lib/core/route/app_router.dart` (route names in
  `route_names.dart`). Bottom navigation is a `StatefulShellRoute.indexedStack`
  (Home / Sales / Reports / Settings). Several routes (login, dashboard, profile, about*)
  are `PlaceholderWidget` stubs — do not assume those screens exist.

## Database

- `sqflite` with FFI on desktop/web (`database_initializer*.dart` selects the factory).
- Schema migrations are plain SQL files in `lib/core/database/migrations/` (e.g. `001_*.sql`),
  executed in order by `MigrationRunner` in `lib/core/database/migration_runner.dart`.
  **A new migration must be added to the hardcoded `migrations` list there** or it will never run.
- Table definitions: `lib/core/database/tables/`. Seed data: `lib/core/database/seeders/`.
- Settings are loaded into `SettingsCubit` at startup and read DB-backed/live across features.

## i18n (flutter_intl)

- User-facing strings come from ARB files in `lib/l10n/*.arb` (e.g. `intl_en.arb`), generated
  into `lib/generated/` by the flutter-intl tooling. Reference them as `S.of(context).key`.
  Do not hardcode UI text; add the key to the ARB and regenerate.
- `Directionality(textDirection: rtl)` is forced globally in `main.dart` — account for RTL in
  layout, widget tests, and text alignment defaults.

## Conventions / gotchas

- There are two similar Settings cubits: `setting_cubit.SettingCubit` and
  `settings_cubit.SettingsCubit` (aliased as `new_settings_cubit` in the router). Disambiguate
  before editing either.
- `build_runner`, `json_serializable`, and `freezed` are declared dependencies but **not currently
  used** in the source — do not assume generated `*.g.dart`/`*.freezed.dart` files exist; if you
  introduce codegen, run it and commit/regenerate the outputs.
- Keep changes surgical: this is a large 750+ file codebase; match existing BLoC/feature patterns
  rather than introducing new state or DI approaches.
