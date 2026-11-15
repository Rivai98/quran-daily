# Implementation Plan: Reader Visibility, Member Profiles, and Group Info

**Branch**: `007-reader-visibility-profiles` | **Date**: 2026-11-15 | **Spec**: [spec.md](./spec.md)
**Constitution**: v2.4.0 (binding) | **Builds on**: 001, 004, 005

## Summary

Show who read each portion (name, initials avatar, time, on time/late/
volunteered/override) on the dashboard and history; a detail sheet per portion;
member profiles visible only to co-members; a WhatsApp-style group info screen
(tap the dashboard header) with group photo, description, stats and members.
Missed/unread member names are visible only to owner and supervisors.

## Technical Context

Flutter, MVVM + Cubit, get_it, sqflite, hosted Supabase (Storage bucket for
group photos). New packages: `image_picker`, `image_cropper` (square crop),
`flutter_image_compress` (≤ 512px, JPEG q80). Migration range `2026111512NNNN`.

## Constitution Check

| Principle | Compliance |
|-----------|------------|
| I Offline core | Reader info rides in the cached dashboard/history payloads; photos cached |
| II Arabic/RTL | Copy in ArabicStrings; Arabic numerals; RTL lists |
| III Test-first | pgTAP for visibility rules and profile access; cubit/widget tests |
| IV MVVM + Cubit | GroupInfoCubit, MemberProfileCubit, PortionDetail sheet state |
| V Simplicity | Extend existing RPC payloads additively; one new profile RPC |
| VI Design system | Avatars (initials over tokens), status triplets, ornament avatar for groups |
| VII Quran integrity | Portion names via metadata only |
| Privacy | Emails never returned; profiles only for co-members; missed names only to owner/supervisor |

Gate: PASS.

## Data and RPCs

- `profiles.bio text <= 120`; `groups.photo_path text`, `groups.description` (exists?) reused.
- Storage bucket `group-photos` (private): object path `<group_id>/<uuid>.jpg`;
  policies: read = active members of that group; write/delete = owner only;
  max 1 MB, image/jpeg|png|webp.
- `get_dashboard` / `get_history_day`: each assignment gains
  `reader: {user_id, display_name, initials}` and `completed_at`, `kind`;
  for viewers who are not owner/supervisor, rows with status missed/unread of
  OTHER members return `reader: null` and a neutral status.
- `get_group_info(p_group_id)`: name, description, photo_path, unit, created_at,
  member_count, khatma_count, invite (owner/supervisor only), members
  [{user_id, display_name, initials, role, seat_number}].
- `get_member_profile(p_user_id, p_group_id)`: co-member check; display_name,
  initials, bio, role and seat in this group, member_since, streak, portions
  read in this group, recent activity (last 7 days, own group only, missed
  hidden unless caller is owner/supervisor or self). Never email.
- `update_my_profile(p_display_name, p_bio)`; `set_group_photo(p_group_id, p_path)`, `update_group_details(...)` (owner).

## Work split

| Agent | Scope |
|-------|-------|
| backend agent | T001-T007 |
| app agent A | T008-T014 (reader attribution on dashboard/history, portion detail sheet, member profile, edit my profile) |
| app agent B | T015-T020 (group info screen, photo pick/crop/upload, group details edit, avatars) |
