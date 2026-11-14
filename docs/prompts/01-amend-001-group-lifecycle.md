# Prompt: amend spec 001 (group lifecycle, rotation, vacant seats)

Run in Spec Kit / Codex while on the `001-track-quran-groups` feature:

```
/speckit-specify
```

Paste everything inside the block below as the input.

---

```text
UPDATE the existing specification at specs/001-track-quran-groups/spec.md
(do not create a new feature). Read .specify/memory/constitution.md first;
it is binding. Keep everything in the current spec that is not contradicted
below, keep the existing Clarifications history, and add a new
"Session 2026-11-14" clarification block recording these decisions.

CONTEXT - how the real group works today (WhatsApp):
A group has numbered seats 1..30. Every day the organizer posts the day's
list: seat -> member -> juz. Each member replies "تم" when finished. The next
day every seat moves to the next juz (juz 30 wraps to juz 1), so every member
finishes a full personal khatma every 30 days and the group finishes one
collective khatma every day. Some seats are empty and the group still runs.
Juz 30 is read together with دعاء الختم.

DECISIONS (replace any conflicting requirement):

1. Who creates groups
   - Any signed-in user can create a group and becomes its Owner (مالك المجموعة).
   - One account can own at most 3 groups.
   - Group organizer/owner roles are separate from the global application
     administrator defined in spec 002.

2. Group creation form
   - Name, short description, group timezone, daily start time (the moment
     the group's day rolls over, default 00:00 in the group timezone).
   - Visibility: public (listed in discovery) or private (hidden; joinable
     only by invite link or invite code).
   - Join mode: auto-accept, or owner approval.

3. Seats
   - A group has exactly 30 seats numbered 1..30. Each active member occupies
     one seat. Seats can be empty.
   - The owner can reorder members across seats while the group is forming,
     and can move a member to an empty seat at any time (takes effect next day).

4. Group lifecycle
   - Forming (قيد التكوين): shows "N / 30" and "ناقص X". No daily cycle yet.
   - Active (نشطة): the owner taps "ابدأ الختمة" at any time, with any number
     of members >= 1. The 30-member requirement for publishing is REMOVED.
   - Archived: owner can archive; no new cycles, no joins.

5. Automatic daily rotation (replaces daily manual publishing)
   - When the group starts, the owner sets the starting juz for seat 1
     (default juz 1); seat k starts at ((start + k - 2) mod 30) + 1.
   - Each new group day, every seat advances by one juz (30 -> 1).
   - Cycles are generated automatically by the backend at the group's day
     rollover; the owner does NOT publish daily. Remove the daily
     review-and-publish flow and daily swap requirement.
   - The owner may still override today's assignment for a seat
     (e.g. reassign to another member) before the day ends.

6. Vacant seats and volunteering
   - A juz whose seat is empty today is shown as "متاح" on the dashboard.
   - Any active member may tap "أتطوع بقراءته" to take that juz for today
     only. First volunteer wins; others see it as taken.
   - If nobody reads it, history records it as "لم يُقرأ" (unassigned), which
     is distinct from "فائت" (assigned member did not read).

7. Joining
   - Discovery lists public groups that need members ("مجموعات تحتاج أعضاء"),
     sorted by fewest empty seats first, showing name, short description,
     "N / 30", timezone, and status (forming/active). Member lists and
     progress stay hidden from non-members.
   - "انضم لأي مجموعة ناقصة": one tap places the user in the best public
     auto-accept group (fewest empty seats, matching device timezone first).
   - Invite link / invite code for private (and public) groups; the owner can
     regenerate it to revoke the old one.
   - Owner-approval groups keep the pending state
     "بانتظار القبول من مالك المجموعة".
   - A member joining an active group takes an empty seat and gets that seat's
     juz for today immediately.
   - A member who leaves frees their seat; the rest of the rotation is unchanged.

8. Roles
   - Owner: edit settings, approve/reject requests, remove members, arrange
     seats, start/archive the group, appoint/remove supervisors, override
     today's assignment.
   - Supervisor (مشرف), optional, appointed by the owner: approve/reject
     requests and arrange seats. Cannot archive the group, change ownership,
     or appoint supervisors.
   - Member: read, mark "تم", undo with confirmation, volunteer for vacant juz.

9. Statuses (canonical Arabic labels from the constitution)
   completed تمت القراءة, pending لم يُقرأ بعد, missed فائت,
   late قُرئ متأخرًا, plus new: available (vacant seat, today) متاح and
   unread-unassigned (history) لم يُقرأ.

10. Quran content
   - The "in-app Quran reader is out of scope" statement is now superseded:
     the Mushaf is delivered by a separate feature (spec 003). This feature
     only needs an "اقرأ الآن" entry point on the member's assignment that the
     Mushaf feature will connect to; until then it may be hidden.
   - Juz labels and reading ranges MUST come from verified Quran metadata
     (constitution Principle VII), never hand-written.

Update user stories, acceptance scenarios, edge cases, functional
requirements, UI surface requirements, key entities (add Seat, InviteLink,
Volunteer assignment; update Group, Membership, DailyReadingCycle,
Assignment), success criteria, assumptions, and out-of-scope accordingly.
Mark anything still ambiguous with [NEEDS CLARIFICATION] (max 3).
```

---

## After this prompt

1. `/speckit-clarify` - answer its questions.
2. `/speckit-plan` - regenerates plan, data model, contracts for 001.
3. `/speckit-tasks` - regenerates tasks. Note: Phase 1 setup tasks already done
   in the repo should stay marked `[X]`.
4. `/speckit-analyze` - consistency check before implementing.
