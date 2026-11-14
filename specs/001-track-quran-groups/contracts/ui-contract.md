# Contract: UI Screens and States (amended 2026-11-14)

Visual rules come only from constitution Principle VI and `docs/design/design-system-mock.html`. This contract defines screens, states, actions, and copy keys; it never defines colors, sizes, or new components.

## Global Rules

- Arabic only, RTL root, Arabic-Indic numerals via `ArabicNumerals.format`.
- Every screen implements loading (skeleton), content, empty, error (`StatePanel` with next action), and offline/stale (`OfflineBanner` with last-synced time).
- At most one `AppButton.primary` per screen; destructive actions go through `ConfirmSheet`.
- Statuses always use `StatusChip`/`PartTile` (color + icon + label): completed تمت القراءة, pending لم يُقرأ بعد, missed فائت, late قُرئ متأخرًا, available متاح, unread لم يقرأه أحد.
- Juz label = ordinal name from `ArabicStrings.juzName(n)` (`quranLabel` style); range = "من سورة {sura} آية {n} إلى سورة {sura} آية {m}" from `QuranMetadataRepository`.
- Member identity = display name + role marker (المالك / مشرف). No emails or phone numbers.
- All copy lives in `lib/core/localization/arabic_strings.dart`; error codes map to copy that names the next action.
- Navigation: `NavigationBar` inside a selected group with destinations اليوم، السجل، الأعضاء، الإعدادات.

## Screens

### S1 Group Selection (`/groups`)
- Content: my groups list (name, status, my role, today's juz + status if active), "مجموعات تحتاج أعضاء" entry.
- Empty (no groups): `StatePanel` + actions: "انضم لأي مجموعة ناقصة" (primary), "ابحث عن مجموعة", "أنشئ مجموعة", "عندي رابط دعوة".
- Pending requests shown as rows with chip "بانتظار القبول من مالك المجموعة" and "إلغاء الطلب".

### S2 Discovery (`/discover`)
- Search field + list of `PublicGroupCard` (name, description, "N / ٣٠", timezone, forming/active chip).
- Card action: "انضم" (auto-accept) / "اطلب الانضمام" (approval); pending → pending chip; full → disabled + reason.

### S3 Invite Join (`/join/:code` and manual code entry)
- Code field (LTR, 8 chars) → preview card → join action. Errors: invalid code, archived, full.

### S4 Create Group (`/groups/new`)
- Fields: name, description, timezone (device default + searchable list), day start time, visibility (عامة/خاصة), join mode (قبول تلقائي/بموافقة المالك).
- Primary: "أنشئ المجموعة". Limit error explains the 3-group cap.

### S5 Group Dashboard (`/g/:id`)
- Active: optional `OfflineBanner`; **my juz card** (juz name, range, status, primary "سجّل إتمام الجزء" or completed state, juz 30 note "يُقرأ معه دعاء الختم"), `ProgressHeader` (`١٢ / ٣٠`, %, ends at), 30-cell `PartTile` grid, available juz list with "أتطوع بقراءته", full khatma banner when complete.
- My volunteered/overridden juz appear as additional cards under my juz.
- Forming: "N / ٣٠ · ناقص X", seat list, invite code + "شارك الدعوة", owner primary "ابدأ الختمة" (sheet to choose seat-1 starting juz).
- Grace state (yesterday not closed): banner "يمكنك تسجيل جزء الأمس متأخرًا حتى {time}" with action.
- My juz card and its primary action must be visible without scrolling at 360×640.

### S6 Personal Assignment (`/g/:id/assignment/:aid`)
- Juz name, range, status chip, date, day end time, group name.
- Primary: complete; completed → "التراجع عن الإتمام" (danger-outline) → `ConfirmSheet`.
- Queued offline state: "سيُرسل إتمامك عند عودة الاتصال"; failed sync: reason + retry.
- Reserved "اقرأ الآن" slot, hidden until spec 003 (feature flag constant).

### S7 Members & Seats (`/g/:id/members`)
- 30 seat rows (member or "مقعد شاغر"), role markers.
- Owner/supervisor: move seat (pick target seat), owner: set supervisor, remove member (confirm), transfer ownership (confirm). Member: "مغادرة المجموعة" (confirm); owner sees "انقل الملكية أولًا".
- Entry to join requests with count.

### S8 Join Requests (`/g/:id/requests`)
- Rows: display name, requested time, source; actions اقبل (primary per row allowed as tonal) / ارفض (confirm). Group full → disabled approve + reason. Empty state.

### S9 Group Settings (`/g/:id/settings`)
- Edit fields from S4 (owner), note that timezone/start time apply from tomorrow, invite code + "شارك الدعوة" (all active members), regenerate (owner, confirm), archive (owner, confirm). Supervisors/members see the other settings read-only.

### S10 History (`/g/:id/history`)
- Day cards: date, `ProgressHeader` bar, chips for completed/late/missed/unread counts, "ختمة كاملة" chip.
- Day detail: members see summary + own result; owner/supervisor see per-juz rows (seat, reader, status).

### S11 App Settings (`/settings`)
- Quran text size slider (0.85-1.6) with live preview of a juz label; sign-out (confirm, spec 002).

## Routing Guards

- Signed out → Auth Entry (spec 002). Signed in with no selected group → S1. Selected group → S5.
- Non-member opening `/g/:id` → S1 with error "لست عضوًا في هذه المجموعة".
- Deep link `qurandaily://join/<code>` → S3 (after sign-in if needed).

## Accessibility Tests (per screen)

RTL traversal order, 200% text scale (no overflow), dark theme, 320 dp width, semantic labels on icon buttons and `PartTile` ("الجزء ٥، لم يُقرأ بعد، جزؤك").
