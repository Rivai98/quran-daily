# Prompt: new spec 004 (design system foundation)

Run in Spec Kit / Codex:

```
/speckit-specify
```

Paste everything inside the block below as the input. Spec Kit will create
`specs/004-design-system-foundation/`.

---

```text
Feature: Implement the design system defined in constitution Principle VI
and migrate the existing UI to it.

Read .specify/memory/constitution.md (Principle VI is the source of truth)
and docs/design/design-system-mock.html (visual reference) first.

Scope:
1. Create lib/core/design_system/ with app_colors.dart (light + dark tokens
   exactly as in the constitution tables), app_typography.dart (the 8-step
   type scale, Cairo for UI, Amiri for quranLabel),
   app_spacing.dart, app_radius.dart, and app_theme.dart (Material 3 light and
   dark ThemeData built only from tokens; follows system theme).
2. Bundle fonts as assets (Cairo 400/500/600/700, Amiri
   400/700) and register them in pubspec.yaml. No runtime font downloading.
3. Arabic-Indic numeral formatter in lib/core/localization/.
4. Shared widgets in lib/core/design_system/widgets/: AppButton (primary,
   tonal, secondary, text, destructive, icon; loading and disabled states),
   AppTextField, AppCard, AppSectionHeader, StatusChip (completed, pending,
   missed, late, available, unread), PartTile, ProgressHeader, StatePanel,
   OfflineBanner, ConfirmSheet, AppSnackBar, skeleton loaders.
5. Replace lib/core/theme/ with the new design system and migrate every
   existing screen and widget under lib/features/ to use only tokens and
   shared widgets (no raw colors, font sizes, spacing numbers, or radii).
6. App root: Arabic locale, RTL, light/dark following the system.

Acceptance: widget tests for every shared widget in light, dark, RTL, and
200% text scale; golden or widget tests proving status chips always show
color + icon + label; a test that fails if a feature file contains a raw
Color(0x...) or a hard-coded fontSize.

Out of scope: new screens or business logic; Mushaf font (spec 003).
```

---

## After this prompt

`/speckit-clarify` (likely nothing to ask), `/speckit-plan`, `/speckit-tasks`,
`/speckit-analyze`, then `/speckit-implement`.
