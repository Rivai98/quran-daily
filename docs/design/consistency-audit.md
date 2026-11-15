# App-Wide Consistency Audit (Screens Outside Polish D Scope)

**Date**: 2026-11-15  
**Auditor**: Polish D Agent (UI/UX Craft & Shared Design System)  
**Authority**: Constitution Principle VI (Design System), `briefs/owner-rules.md`, `briefs/ui-craft.md`, `docs/design/design-system-mock.html`

---

## 1. Executive Summary

This audit assesses the visual and behavioral consistency across all screens **outside** the scope of Polish D (`lib/features/auth/**`, `lib/core/design_system/**`, `lib/app/app.dart`). The goal is to provide authors and maintainers of other features with actionable, precise findings and required fixes to achieve complete visual harmony across the entire application.

---

## 2. Global Violations & Anti-Patterns

### G-01: Duplicate Re-implementations of Design System Components
* **Rule**: Constitution Principle IV & VI strictly dictate: *"Features MUST use these shared components from `lib/core/design_system/widgets/` and MUST NOT re-implement them."*
* **Findings**:
  * `lib/features/quran_groups/view/widgets/state_panel.dart` re-implements `StatePanel` using Flutter's raw `Card`, `theme.colorScheme.primary`, and raw text styles.
  * `lib/features/quran_groups/view/widgets/status_chip.dart` defines its own `enum ReadingStatus` and renders Material `Chip` with `AppRadius.smBR` instead of the design-system `StatusChip` (`AssignmentStatus` + `StadiumBorder`).
  * `lib/features/quran_groups/view/widgets/app_section_header.dart` duplicates the shared `AppSectionHeader`.
  * `lib/features/quran_groups/view/widgets/offline_stale_banner.dart` and `validation_banner.dart` duplicate inline banner functionality instead of adopting the shared `OfflineBanner` and `AppBanner`.
* **Fix**: Delete all duplicate widgets in `lib/features/quran_groups/view/widgets/` and import canonical components from `package:quran_daily/core/design_system/widgets/widgets.dart`.

### G-02: Icon Family Inconsistency (Missing Rounded Family)
* **Rule**: `ui-craft.md` requires: *"Material Symbols Rounded / Icons.*_rounded or outlined, ONE family across the app."*
* **Findings**:
  * Unrounded icons are still used across several screens:
    * `Icons.wifi_off` in `home_screen.dart:62` and `offline_stale_banner.dart:14` (should be `Icons.wifi_off_rounded` or `Icons.cloud_off_rounded`).
    * `Icons.groups` in `home_screen.dart:162` (should be `Icons.groups_rounded`).
    * `Icons.error_outline` in `profile_screen.dart:86` (should be `Icons.error_outline_rounded`).
    * `Icons.check` in `edit_profile_screen.dart:300` (should be `Icons.check_rounded`).
    * `Icons.edit_note_outlined` in `edit_profile_screen.dart:289` (should be `Icons.edit_note_rounded`).
* **Fix**: Replace all instances with their `*_rounded` counterparts.

### G-03: Loading State Spinners vs Skeletons
* **Rule**: Constitution Principle VI specifies: *"Loading uses skeleton placeholders shaped like the final content; full-screen spinners are allowed only at app startup."*
* **Findings**:
  * `HomeScreen` (`home_screen.dart:57`) renders `Center(child: CircularProgressIndicator())` on first load instead of skeleton cards (`SkeletonBox`).
* **Fix**: Replace the bare spinner with a skeleton representation of the Wird hero card and group progress.

### G-04: Empty State Branding & Copy Quality
* **Rule**: `owner-rules.md` and `ui-craft.md` require empty states to use the official حلقة logo (`HalaqaLogo`), clear Arabic invitation title, one helpful explanation line, and clear primary/secondary actions.
* **Findings**:
  * `HomeScreen` empty state (`home_screen.dart:161`) has an empty `message: ''` and uses generic `Icons.groups`.
  * `GroupSelectionScreen` empty state (`group_selection_screen.dart:134`) uses strange phrasing `"لا توجد مجموعات مقبولة بعد"` and an orphan subtitle `"مجموعات تحتاج أعضاء"`.
  * `JoinRequestsScreen` has duplicated title and message.
* **Fix**: Migrate all empty states to `StatePanel.empty(...)` with canonical strings from `ArabicStrings`.

---

## 3. Screen-by-Screen Detailed Audit

### 03 & 06: Group Selection & My Groups (`group_selection_screen.dart`)
1. **Header Space Waste**: Inside the tab view, `_GroupHeader` renders a prominent "حلقة" band that wastes vertical space on a screen that already lives inside the authenticated shell.
   * *Fix*: Replace with a standard `AppSectionHeader(title: ArabicStrings.myGroupsTabTitle)`.
2. **Empty State Phrasing**: `"لا توجد مجموعات مقبولة بعد"` sounds odd.
   * *Fix*: Use `StatePanel.empty(title: 'لم تنضم إلى حلقة بعد', message: 'اختر حلقة متاحة أو ابدأ حلقتك الخاصة', actionLabel: 'انضم لأي حلقة', secondaryActionLabel: 'أنشئ حلقة')`.
3. **Card Ripple & Touch Targets**: Group items use manual `InkWell` inside custom containers.
   * *Fix*: Wrap with `AppCard(onTap: ...)`.

### 03b: Discovery Screen (`discovery_screen.dart` & `public_group_card.dart`)
1. **Action Button Weight**: Each public group card renders a heavy secondary button (`AppButtonVariant.secondary`) in a row.
   * *Fix*: Use a compact text button `"طلب انضمام"` or small `AppButton(expanded: false)` aligned to start.
2. **Timezone Representation**: Raw timezone ID strings (`Africa/Cairo`) are parsed locally using an ad-hoc switch statement in `_timezoneCity` rather than localized strings helper.
   * *Fix*: Move city mapping into `lib/core/localization/arabic_formatting.dart`.
3. **Role & Status Badges**: Ad-hoc `_GroupStatusBadge` should be replaced with `AppBadge`.

### 04: Create Group Screen (`create_group_screen.dart`)
1. **Unit Selector Grid**: The 5 portion units are displayed in a 2-column grid leaving an orphan 5th card on the next row.
   * *Fix*: Switch to a clean vertical radio list or selectable card tiles with name + cycle duration (`ختمة كل N يوم`).
2. **Help Hints**: Joining mode and visibility switches lack a one-line explanatory caption beneath their labels.
   * *Fix*: Add `helpText` using `AppTypography.caption`.

### 08 & 09: Group Dashboard & 30-Juz Grid (`group_dashboard_screen.dart` & `juz_grid.dart`)
1. **App Bar Overload (G5)**: The group dashboard app bar contains up to 4 actions plus long titles, causing title truncation.
   * *Fix*: Keep maximum 2 actions (Mushaf reader icon + overflow menu); move members, settings, and history into the overflow popup menu.
2. **Progress Color**: Ensure Khatma progress bar uses primary green (`colors.primary`) in both light and dark modes, not gold.
3. **Tile Semantics & Reader Initial**: Juz tiles (`PartTile`) now support `readerInitials` and `readerDisplayName`. The dashboard grid should ensure reader initials are rendered in completed cells.

### 10 & 25: Home Screen (`home_screen.dart`)
1. **Header Greeting**: Ensure greeting uses first name only at modest size (`AppTypography.title` or `headline`), avoiding oversized display typography.
2. **Home Hero Card Actions**:
   * Prior to completion: Primary action is `"اقرأ الآن"` (`AppButtonVariant.primary`), secondary is `"تمت القراءة"` (`AppButtonVariant.tonal`).
   * After completion: Primary becomes `"اقرأ مرة أخرى"` or none, with `"تراجع"` provided as a subtle text button.
3. **Number Ordering & Isolates (G2)**: Ensure composite strings like `"قرأ اليوم ١ من ٣٠"` and cycle days are wrapped in directional isolates so digits do not scramble in RTL.

### 11 & 12: Members & Join Requests (`members_screen.dart`, `join_requests_screen.dart`)
1. **Member Avatars**: Member rows should use `UserAvatar` displaying the member's chosen illustrated avatar or initials.
2. **Role Indicators**: Replace custom containers with `AppBadge.role(label: 'مشرف', isOwner: false)` or `isOwner: true`.
3. **Empty Join Requests**: Replace duplicated title/message with `StatePanel.empty(title: 'لا توجد طلبات انضمام', message: 'ستظهر هنا طلبات الأعضاء الراغبين بالانضمام إلى حلقتك')`.

### 13 & 13b: Group Settings (`group_settings_screen.dart`)
1. **Multiple Save Buttons**: The page displays two separate save buttons (`"حفظ التذكيرات"` and `"حفظ"`).
   * *Fix*: Split group settings into clear sections with single save or navigate reminders to their own sub-screen (`"تذكيرات المجموعة"`).

### 15a-d: Mushaf Index (`mushaf_index_screen.dart`)
1. **Badge Standardization**: Replace private `_indexBadge` implementation with the shared `AppBadge.count(label: ..., variant: AppBadgeVariant.neutral)`.
2. **Meta Line Scrambling**: Surah meta (`"صفحة ١ · ٧ آيات · مكية"`) must use Unicode directional isolates around Arabic-Indic numbers to prevent flipped order in RTL layout.

### 16 & 17: Bookmarks (`bookmarks_screen.dart`)
1. **Row Information Richness**: Bookmarks list currently shows only `"الصفحة ١"`.
   * *Fix*: Enrich rows with Surah name, Ayah range, date added, and an overflow menu or swipe action to delete.

### 18: Mushaf Licenses (`licenses_screen.dart`)
1. **Visual Presentation**: Convert plain text listing into styled cards with publisher badges, riwayah edition, verified SHA-256 checksum status, and external links.

### 19 & 33: Profile & Settings (`profile_screen.dart`, `settings_screen.dart`, `edit_profile_screen.dart`)
1. **Sign-Out Visibility**: Sign-out is currently hidden inside Settings. Per owner directive, a visible `"تسجيل الخروج"` action with `ConfirmSheet` confirmation must be present at the bottom of the main profile tab (`حسابي`).
2. **Edit Profile Iconography**:
   * Change `Icons.check` to `Icons.check_rounded`.
   * Change `Icons.edit_note_outlined` to `Icons.edit_note_rounded`.
3. **Badges Grid**: Badges in `ProfileBadgesGrid` should utilize `AppCard` and standard `AppRadius.md` tokens with consistent 3-column layout.

---

## 4. Prioritized Action Plan for Remaining Worktrees

| Priority | Feature Area | Key Action |
|---|---|---|
| **P0** | `quran_groups` | Delete duplicate `StatePanel`, `StatusChip`, `AppSectionHeader`, `OfflineBanner` widgets; import core widgets. |
| **P0** | `home` | Replace raw `CircularProgressIndicator` with skeleton loading; fix empty state copy. |
| **P1** | `quran_groups` / `discovery` | Simplify app bar actions (max 2); adopt `AppBadge` for roles and statuses; use compact join button. |
| **P1** | `profile` & `settings` | Ensure sign-out row is visible on `ProfileScreen`; harmonize all icons to `*_rounded`. |
| **P2** | `mushaf` (orchestrator) | Use `AppBadge.count` in index lists; audit RTL numeral isolates in metadata lines. |
