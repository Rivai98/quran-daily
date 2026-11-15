# Design review — integration build (2026-11-15)

Source: screenshot tour (`integration_test/screenshot_tour_test.dart`), 30 screens,
light + dark, Android emulator 1080x2400. Binding rules: constitution Principle VI,
`docs/design/design-system-mock.html`, `docs/design/reference-notes-2026-11-15.md`
(owner's reference app: inspiration only, group-first, calmer and better).

## Global issues (fix everywhere)

- G1 **Gold misuse**: gold is used for the selected start-juz chip and for progress
  bars. Rule: gold only for ornament. Selection and progress use the primary green
  (dark mode: the primary-container mint).
- G2 **Percent and number ordering in RTL**: "٠٪" renders as "·/." and strings like
  "١ الصفحة · ٧" / "اليوم · من ٣٠ · أنجز · ١ من ٣٠" are scrambled. Build these strings
  with proper Arabic templates (e.g. "صفحة ١ · ٧ آيات", "أُنجز ١ من ٣٠") and use the
  Arabic percent sign "٪" via the existing numerals helper; wrap mixed runs with
  Unicode isolates where needed.
- G3 **Chips that wrap to two lines** ("الجزء يوميًا / ختمة يوميًا" inside one pill) look
  broken. Use one-line chips with short copy ("جزء يوميًا"), or a single meta line
  with icons ("٣٠ عضوًا · جزء يوميًا · ختمة كل يوم").
- G4 **Brand**: the auth header and empty states still use a generic open-book icon.
  Use the حلقة logo (ring of 30 dots around an open Mushaf, `assets/branding/`) as a
  widget (CustomPaint or SVG) in the auth header, splash and empty states.
- G5 **App bar overload**: group screens show 4 icons + a truncated title
  ("جولة 1794…"). Keep at most 2 actions (Mushaf/read + overflow menu); move history,
  members, settings into the overflow menu; title may wrap to 2 lines or shrink.
- G6 **Raw technical values** shown to users: timezone "Africa/Cairo", invite code
  placeholder "--------". Show human Arabic labels (city name, "إظهار الرمز").
- G7 **Duplicated empty-state copy** (title and subtitle identical, e.g. join
  requests). Title = short invitation, subtitle = one helpful line.
- G8 **Group avatar missing** on group cards, discovery cards, dashboard header. Use
  the generated group avatar (initials over ornament) from spec 007.
- G9 **Spacing rhythm**: several screens have cramped cards and inconsistent gaps; use
  the spacing tokens (16 side gutter, 12/16 between cards, 24 between sections).

## Per screen

| # | Screen | Problems | Fix |
|---|--------|----------|-----|
| 01/02 | Auth | Generic icon; tagline "من شاشة عربية واضحة" reads oddly; Google button below the fold on create account | حلقة logo; tagline "ختمة القرآن مع حلقتك، وردٌ كل يوم"; reduce header height so Google button is visible |
| 03 | Groups empty | "لا توجد مجموعات مقبولة بعد" (odd), orphan label "مجموعات تحتاج أعضاء" | "لم تنضم إلى حلقة بعد"; keep one primary (انضم لأي حلقة) + secondary actions; remove orphan label |
| 03b | Discovery | Cards: raw timezone, stacked wrapping chips, no avatar, heavy button per card | Compact card: avatar, name, one meta line (members · unit · city), status chip, small "طلب انضمام" text button |
| 03d | Join any | Title says "الانضمام برمز دعوة" (wrong); shows generic error "حدث خطأ غير متوقع" | Correct title "انضم لأي حلقة"; investigate the error (likely a failure mapping) and show the real reason |
| 04 | Create group | 5 unit cards in a 2-column grid with an orphan; join-mode segment has no label/explanation | Unit as a vertical radio list (name + "ختمة كل N يوم"); labels and one-line hints for visibility and join mode |
| 05 | Group list card | Chips stacked vertically, no avatar, progress bar unlabeled | Avatar + name + meta line + labeled progress "١ من ٣٠ عضوًا" |
| 06 | Dashboard (forming) | Header numbers "٠ ناقص ٢٩ / ١ / ٣٠" confusing; app bar overload | "عضو واحد من ٣٠ · ينقص ٢٩"; G5 |
| 07 | Start sheet | Gold selected chip; 30 tiny chips | Green selection; larger tap targets (48dp) |
| 08 | Dashboard (active) | Portion title shows "١" instead of "الجزء الأول"; floating unit chip top-right; scrambled summary line; gold progress; 30-tile grid cramped | Use portionName(unit,index) as the title; move unit into header meta; fix line (G2); green progress; tiles with clearer status triplets and the reader initials (007) |
| 09 | Personal assignment | OK; primary/secondary balance fine | Keep; align to new wird card style (start/end ayah + page rows like the reference) |
| 10 | History | "٠٪" glyph; sparse | G2; day rows with status triplets |
| 11 | Members | No avatars; flat list | Avatars, role badges, seat; tap → member profile (007) |
| 12 | Join requests empty | Duplicated copy | G7 |
| 13/13b | Group settings | Two save buttons on one page ("حفظ التذكيرات" and "حفظ"); long single page | Split into sections with one save per section or auto-save; reminders section as its own screen "تذكيرات المجموعة" |
| 14 | Mushaf reader | Works and the KFGQPC text renders well; header line tiny; banner pale; no surah title ornament; floating bookmark icon | Mushaf-like page: surah title band with ornament for surah starts, centered basmala per source, page number footer, juz/hizb in a slim header; banner shows portion name + "صفحة ١ من ١٠" |
| 15a-d | Mushaf index | Very plain lists; scrambled meta (G2) | Rows with number badge, name, meta (صفحة ١ · ٧ آيات · مكية/مدنية if available from metadata), dividers, chevron; juz/hizb rows show start surah and page |
| 16/17 | Bookmarks | Dialog fine; list shows only "الصفحة ١" | List row: surah + ayah, page, note, date; swipe or menu to delete |
| 18 | Licenses | Plain text | Card with source names, versions and links (from SOURCE.md) |
| 19 | Settings | Bare: font size, reminders switch, sign out | Group into sections (القراءة، التذكيرات، الحساب، حول التطبيق); reminders expanded controls when on; admin entry for admins |

## Not covered by this tour (review after merge)

Spec 005 (tabs, Home hero/compact cards, حسابي profile, log), spec 007 (reader
attribution, member profile, group info, group photo), admin console (needs an admin
account), reminders with switches on, member/supervisor views.
