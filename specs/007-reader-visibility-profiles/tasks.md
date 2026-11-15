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
- [ ] T021 Emulator: member vs owner visibility, open profile, group info, upload photo
- [ ] T022 analyze 0, all tests green, pgTAP 0 failed; validation log; merge to main

## Validation log
_(filled at T022)_
