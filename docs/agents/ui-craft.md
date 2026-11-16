# UI craft rules for every design task (owner request: icons + polished cards)

Apply these on top of constitution Principle VI and docs/design/design-system-mock.html.
If your agent environment has UI/design skills (e.g. building-native-ui, design-an-interface,
web-design-guidelines), consult them for principles; this app is Flutter, so translate.

## Icons
- Every card row, meta item, action and status gets a meaningful icon (Material Symbols
  Rounded / Icons.*_rounded or outlined, ONE family across the app). Size 18-20 in meta
  lines, 24 in actions, 20-22 in list leading slots.
- Icon color = the text color of its row/button (never hard-coded black/white). Check dark.
- Suggested mapping: group = groups_rounded, members = people_alt_rounded, unit/portion =
  menu_book_rounded, today/day = today_rounded, streak = local_fire_department_rounded,
  completed = check_circle_rounded, pending = schedule_rounded, late = history_rounded,
  missed = cancel_rounded (owner/supervisor only), available/volunteer =
  volunteer_activism_rounded, city/timezone = location_on_rounded, private = lock_rounded,
  public = public_rounded, invite = link_rounded, settings = tune_rounded, read =
  auto_stories_rounded, bookmark = bookmark_rounded, reminders = notifications_rounded.

## Cards
- One elevation style (tonal surface, 16-20 radius, 1px hairline border in dark), 16 padding,
  12 gap between cards, whole card tappable with ripple; no stray chevrons unless the row is
  a list navigation row.
- Hierarchy: leading avatar/icon (40-48) → title (titleMedium, 1 line, ellipsis) →
  one meta line with small icons separated by " · " → optional progress (6-8px rounded
  green bar + label) → actions row aligned to the start, primary first.
- Status as a small tonal badge (icon + 1-2 words) placed next to the title, never a
  full-width pill.

## Buttons
- Primary: filled, 48-52 high, icon + label, high contrast in both themes.
- Secondary: tonal or outlined with readable contrast in dark mode.
- Text buttons for tertiary actions (undo, details).

## States
- Loading: keep previous content, inline small progress; skeletons only on first load.
- Empty: ornament/logo + short title + one line + one primary action.
- Errors: snackbar/banner with the real reason in Arabic; never giant blocks inside cards.

## Typography and spacing
- Cairo for UI, KFGQPC only for Quran text; numbers in Arabic-Indic digits; mixed
  number/text strings built with the shared Arabic formatting helper (isolates).
- 16 side gutter, 8-pt spacing scale, 24 between sections, comfortable line height.
