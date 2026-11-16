# Tasks: Reader Visibility, Member Profiles, and Group Info

**Plan**: [plan.md](./plan.md). Test-first.

## Phase 1: Backend
- [x] T001 [P] pgTAP `supabase/tests/007_reader_visibility_test.sql`: reader fields on dashboard/history; member viewer sees readers of completed portions but NOT names on others' missed/unread; owner/supervisor see all; self always sees own; never email
- [x] T002 Migration `supabase/migrations/20261115120001_reader_attribution.sql`: additive reader fields with the visibility rule in `get_dashboard`, `get_history_day`
- [x] T003 [P] pgTAP `supabase/tests/007_profiles_group_info_test.sql`: get_member_profile co-member only, non-member refused, no email; get_group_info stats/members, invite only for owner/supervisor; update_my_profile limits; owner-only group details/photo
- [x] T004 Migration `20261115120002_profiles_group_info.sql`: `profiles.bio`, `groups.photo_path`, RPCs
- [x] T005 Migration `20261115120003_group_photos_storage.sql`: private bucket `group-photos`, size/type limits, storage policies (members read, owner write/delete)
- [x] T006 pgTAP for storage policies (storage.objects with member/non-member/owner roles)
- [x] T007 Apply to DEV; run ALL pgTAP files: 0 failed

## Phase 2: Readers and profiles (app agent A)
- [x] T008 [P] Entity/parsing tests for reader fields, profile, group info
- [x] T009 Data layer: entities + repository methods (cache with dashboard/history)
- [x] T010 Dashboard tiles and history rows show reader avatar + name + time/status tag (on time / late / تطوع / مُسند)
- [x] T011 Portion detail sheet (tap a tile/row): reader, status, time, kind, open profile
- [x] T012 MemberProfileScreen (co-members only) + MemberProfileCubit
- [x] T013 "ملفي الشخصي": edit display name (2-50) and bio (≤120) from حسابي/settings
- [x] T014 [P] Widget tests (RTL, dark, 320dp, 200%), privacy cases (member cannot see missed names)

## Phase 3: Group info (app agent B)
- [x] T015 [P] GroupInfoCubit tests
- [x] T016 GroupInfoScreen: tap dashboard header → photo/ornament avatar, name, description, unit, created, member count, khatma count, invite link (owner/supervisor), member list → profile
- [x] T017 Group photo: pick (gallery/camera), square crop, compress ≤512px, upload to `group-photos`, `set_group_photo`; remove photo; cached display
- [x] T018 Group details edit (owner): name, description
- [x] T019 Generated group avatar (initials over geometric ornament) used everywhere a photo is missing
- [x] T020 [P] Widget tests + Android/iOS photo permissions config

## Phase 4: Validation
- [ ] T021 (pending: photo upload not device-validated) Emulator: member vs owner visibility, open profile, group info, upload photo
- [ ] T022 (pending: final re-run stopped by owner) analyze 0, all tests green, pgTAP 0 failed; validation log; merge to main

## Validation log

### 2026-11-16 (qa)
- T021 on emulator-5554 (`spec_validation_test.dart` @ 28c435e): owner sees the «فائت» status, member does not; group info opens from the dashboard header; a member profile opens with no email; invite link hidden for a member. Missed reader names need a past group day: covered by pgTAP `007_reader_visibility_test.sql` (31 passed). Group photo upload NOT validated on device: it goes through the system photo picker, which the Flutter integration driver cannot operate; covered only by widget tests.
- Fixed on the way: the dashboard kept «لم يُقرأ بعد» after completing in the Mushaf reader (745f152).
- Gates on qa @ 4a49987: `flutter analyze` No issues; `flutter test` 595 passed, 0 failed.
- pgTAP (hosted DEV, `scripts/run_remote_pgtap.py`, every file in `supabase/tests`): 24 files, 593 passed, 0 failed.
- Integration tests on emulator-5554 (Android, swiftshader) @ 4a49987: group_flow, home_flow, mushaf_flow, offline_completion, portion_flow all passed.
- `integration_test/spec_validation_test.dart` passed in full @ 28c435e (log below). Its re-run in the final pass, and the screenshot tour re-run, were stopped by the owner's publish request, so they were not repeated after 92564cd/fab9d47/745f152.
