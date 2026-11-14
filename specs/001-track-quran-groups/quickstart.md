# Quickstart: Validate Quran Group Reading Tracker (amended 2026-11-14)

Validation/run guide only; implementation lives in `tasks.md`.

## Prerequisites

- Flutter stable (Dart `^3.10.4`), Android emulator (API 26+), iOS simulator (iOS 15+, macOS only).
- Docker + Supabase CLI for local backend (`supabase start`).
- Owner-provided assets (agents must not create them):
  - `assets/fonts/` Cairo (400/500/600/700) and Amiri (400/700) TTF files (OFL, from Google Fonts).
  - `assets/quran/quran-data.xml` (Tanzil metadata), `assets/quran/SOURCE.md`, `assets/quran/checksums.sha256`.
- `.env`/`--dart-define`: `SUPABASE_URL`, `SUPABASE_ANON_KEY` (publishable key only; never the service key).

## Commands

```bash
supabase start
supabase db reset          # applies supabase/migrations
supabase test db           # pgTAP: rotation, RLS, joins, volunteering, history
flutter pub get
flutter analyze
flutter test
flutter test integration_test -d <emulator-id>
```

All must be green before a story is marked done.

## Scenarios

1. **Create & start** (US2 + US4 invite join; before US4 lands, add the second member with `supabase/tests/helpers/seed_members.sql`): Sign up (spec 002) → S1 empty → "أنشئ مجموعة" → group forming, you are seat 1 → second test user joins via invite code → owner "ابدأ الختمة" with juz 1. Expect: seat 1 juz 1, seat 2 juz 2, 28 juz "متاح".
2. **Rotation** (US2, SC-005): advance the DB clock / call `generate_due_group_days()` for the next date. Expect seat 1 juz 2, seat 2 juz 3; with start juz 30 seat 1 wraps to juz 1 next day. Every day has 30 distinct juz.
3. **Dashboard** (US1): my juz card visible without scrolling at 360×640; counts and percentage correct; juz 30 shows دعاء الختم note.
4. **Complete / undo / offline** (US3): complete → count +1; undo with confirm → −1; airplane mode → complete → own status updates, banner shown → reconnect → server shows completed.
5. **Late & close** (US3): move to grace → pending shows فائت; complete → قُرئ متأخرًا; after close → completion rejected with explanation.
6. **Join paths** (US4): auto-accept join immediate; approval join shows "بانتظار القبول من مالك المجموعة"; "انضم لأي مجموعة ناقصة" picks per rule; full group blocked; private group hidden from discovery but joinable by code.
7. **Volunteer race** (US5, SC-006): two clients volunteer for the same available juz → exactly one succeeds; next day volunteer row not carried.
8. **Manage** (US6): approve/reject, group full on approve, move seat (effective next day), supervisor permissions limited, remove member → seat available, owner leave blocked until transfer, regenerate invite invalidates old code, removed user rejoin → pending.
9. **History** (US7): 7 seeded days; members see summaries + own result only; owner/supervisor see per-seat misses; full khatma with late reads marked.
10. **Privacy** (SC-010): non-member cannot read members/progress via any RPC or table select.
11. **Design/a11y** (SC-011): every screen passes widget tests in RTL, 200% text, dark theme; no raw colors/sizes in `lib/features` (lint test).
12. **Quran metadata** (Principle VII): `SOURCE.md` matches plan.md "Quran Content Source"; checksum test passes; altering one byte of `quran-data.xml` fails the test.
