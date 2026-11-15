> **Historical (pre-2026-11-14 amendment).** Superseded by constitution Principle VI and `contracts/ui-contract.md`; kept for reference only.

# UX Requirements Quality Checklist: Quran Group Reading Tracker UI

**Purpose**: Validate that the requirements fully specify UX completion, empty states, and Arabic UI error handling before implementation tasks are generated.
**Created**: 2026-06-21
**Feature**: [spec.md](../spec.md)

**Note**: This checklist tests the quality of the written requirements, not the implementation.

## Requirement Completeness

- [X] CHK001 Are UX requirements defined for every v1 screen named in the spec, including auth entry, group selection, public discovery, dashboard, assignment detail, organizer review, member management, history, and settings? [Completeness, Spec UI-001]
- [X] CHK002 Are completion-state requirements documented for the member assignment flow, including pending, completing, completed, late, undo, offline queued, and failed states? [Completeness, Spec US3, UI Contract Personal Assignment Detail]
- [X] CHK003 Are organizer completion requirements defined for the full daily cycle, including draft readiness, publish success, publish failure, duplicate assignment warnings, and group-not-ready messaging? [Completeness, Spec US2, UI Contract Organizer Assignment Review]
- [X] CHK004 Are public discovery requirements complete for pre-approval users, including what public data is visible and what private data must remain hidden? [Completeness, Spec FR-027, UI Contract Public Group Discovery]
- [X] CHK005 Are join-request UX requirements defined for pending, approved, rejected, duplicate-request, and group-full outcomes? [Completeness, Spec FR-024, Spec FR-025, UI Contract Public Group Discovery]
- [X] CHK006 Are empty-state requirements defined for no approved groups, no public search results, no pending join requests, no published daily cycle, and empty history? [Gap, UI Contract Arabic Empty-State and Error Contract]
- [X] CHK007 Are UI requirements defined for stale/offline cached states across dashboard, public discovery, group selection, and history? [Completeness, Spec FR-016, Spec FR-017, UI Contract Global UI Requirements]

## Requirement Clarity

- [X] CHK008 Is the meaning of "readable mobile layouts" broken down into specific layout expectations for dense 30-assignment screens? [Clarity, Spec FR-019, UI Contract State Transition and Layout Rules]
- [X] CHK009 Is "clearly indicate" for outdated shared progress specified with concrete Arabic status message, placement, and persistence expectations? [Ambiguity, Spec FR-017, UI Contract State Transition and Layout Rules]
- [X] CHK010 Is the Arabic pending text `بانتظار القبول من مالك المجموعة` specified as exact user-facing copy with guidance for where it appears and when it is replaced? [Clarity, Spec UI-010, UI Contract Public Group Discovery]
- [X] CHK011 Are Arabic error messages required to be actionable, screen-specific, and distinct from generic failure text? [Gap, Spec FR-028, UI Contract Arabic Empty-State and Error Contract]
- [X] CHK012 Are completion action labels, undo labels, and late-status labels required to use consistent Arabic terminology across dashboard, assignment detail, and history? [Clarity, Spec FR-011, Spec FR-028, UI Contract Global UI Requirements]
- [X] CHK013 Is the required visual separation between pending, completed, missed, and late statuses defined beyond color alone? [Clarity, Spec US1, UI Contract Global UI Requirements]
- [X] CHK014 Are requirements explicit about whether "member identity" means display name only, avatar, role marker, or another Arabic-friendly identity format? [Ambiguity, Spec FR-010, UI Contract Global UI Requirements]

## Scenario Coverage

- [X] CHK015 Are primary UX flows covered from Arabic sign-in through public discovery, join request, organizer approval, group dashboard, and assignment completion? [Coverage, Spec Clarifications, Plan Summary]
- [X] CHK016 Are alternate UX flows covered for users with approved groups, users with only pending requests, and users with no groups at all? [Coverage, UI Contract Group Selection, UI Contract Public Group Discovery]
- [X] CHK017 Are exception UX flows covered for sign-in failure, public discovery failure, join request failure, approval failure, publish failure, and completion sync failure? [Coverage, UI Contract Screen States]
- [X] CHK018 Are recovery requirements defined for retrying failed Arabic UI flows without losing user context or typed input? [Gap, UI Contract Global UI Requirements]
- [X] CHK019 Are offline UX scenarios covered for previously opened approved groups while public discovery and organizer approval remain online-only? [Coverage, Plan Constitution Check, UI Contract Global UI Requirements]
- [X] CHK020 Are state transition requirements defined for day-change behavior so current-day, previous-day history, missed status, and late completion are visually understandable? [Coverage, Spec Edge Cases, Spec FR-022]

## Empty State Coverage

- [X] CHK021 Does the spec define required Arabic empty-state copy purpose for a new user with no approved groups? [Gap, UI Contract Arabic Empty-State and Error Contract]
- [X] CHK022 Does the spec define required Arabic empty-state copy purpose for public discovery with no matching groups? [Gap, UI Contract Arabic Empty-State and Error Contract]
- [X] CHK023 Does the spec define required Arabic empty-state copy purpose for organizers with no pending join requests? [Gap, UI Contract Arabic Empty-State and Error Contract]
- [X] CHK024 Does the spec define required Arabic empty-state copy purpose for groups with no published cycle today? [Gap, UI Contract Arabic Empty-State and Error Contract]
- [X] CHK025 Does the spec define required Arabic empty-state copy purpose for daily history before the group has previous cycles? [Gap, UI Contract Arabic Empty-State and Error Contract]
- [X] CHK026 Are empty states required to include the next available action or reason no action is available? [Completeness, UI Contract Arabic Empty-State and Error Contract]

## Arabic UI Error Handling

- [X] CHK027 Are Arabic error-handling requirements defined for authentication errors, including retry guidance and sign-in cancellation? [Gap, UI Contract Arabic Empty-State and Error Contract]
- [X] CHK028 Are Arabic error-handling requirements defined for public discovery network failures and stale cached discovery results? [Gap, UI Contract Arabic Empty-State and Error Contract]
- [X] CHK029 Are Arabic error-handling requirements defined for join request conflicts, including already pending, already approved, rejected, and group full cases? [Completeness, Spec FR-024, Spec FR-025, Supabase Contract submit_join_request]
- [X] CHK030 Are Arabic error-handling requirements defined for organizer approval failures, including not organizer, request no longer pending, and group full cases? [Completeness, Spec FR-025, Supabase Contract review_join_request]
- [X] CHK031 Are Arabic error-handling requirements defined for assignment publishing failures, including fewer than 30 active members, duplicate part, duplicate member, and existing cycle? [Completeness, Spec US2, Supabase Contract publish_daily_cycle]
- [X] CHK032 Are Arabic error-handling requirements defined for personal completion failures, including offline queue failure, not assignment owner, closed cycle, and duplicate completion? [Completeness, Spec US3, Supabase Contract mark_assignment_complete]
- [X] CHK033 Are Arabic validation messages required to explain both the problem and the user's available next step? [Clarity, Spec FR-028]
- [X] CHK034 Are error, warning, and success messages required to use a consistent Arabic tone and terminology across all screens? [Consistency, Spec FR-028, UI Contract Global UI Requirements]

## Requirement Consistency

- [X] CHK035 Are UX requirements consistent between the spec and UI contract for the v1 exclusion of Quran reader controls? [Consistency, Spec FR-021, Spec UI-007, UI Contract Personal Assignment Detail]
- [X] CHK036 Are UX requirements consistent between the spec and plan for excluding notification prompts, reminder controls, and push settings from v1? [Consistency, Spec FR-026, Spec UI-009, Plan Technical Context]
- [X] CHK037 Are public discovery privacy requirements consistent across the spec, data model, Supabase contract, and UI contract? [Consistency, Spec FR-027, Data Model PublicGroupProfile, Supabase Contract search_public_groups]
- [X] CHK038 Are Arabic-first requirements consistent with any remaining English-only labels or examples in the feature artifacts? [Conflict, Spec FR-028, UI Contract Global UI Requirements]
- [X] CHK039 Are offline UX requirements consistent with online-only requirements for discovery, join requests, approvals, publishing, and shared sync? [Consistency, Plan Constitution Check, Data Model LocalSyncOperation]

## Acceptance Criteria Quality

- [X] CHK040 Are UX success criteria defined for public discovery and join request completion, not only dashboard and assignment completion? [Gap, Spec Success Criteria]
- [X] CHK041 Are measurable acceptance criteria defined for Arabic empty-state comprehension and Arabic error-message actionability? [Gap, Spec Success Criteria]
- [X] CHK042 Are acceptance criteria defined for the organizer's ability to resolve group-full and pending-request states without ambiguity? [Gap, Spec US2, Spec FR-025]
- [X] CHK043 Are visual acceptance criteria defined for Arabic RTL text at default and enlarged text sizes across all listed screens, not only Quran labels? [Measurability, Spec SC-008, Spec FR-028]

## Non-Functional UX Requirements

- [X] CHK044 Are accessibility requirements specified for Arabic interactive controls, status indicators, and error messages across all v1 screens? [Coverage, Constitution II, UI Contract Global UI Requirements]
- [X] CHK045 Are contrast and non-color status requirements tied to pending, completed, missed, late, error, warning, and success states? [Completeness, Constitution II, Spec FR-011]
- [X] CHK046 Are performance expectations defined for UX-critical states such as cached dashboard display, public discovery results, and completion feedback? [Completeness, Plan Performance Goals]
- [X] CHK047 Are requirements defined for preserving readable layout when Arabic messages are longer than English equivalents? [Gap, Spec FR-028, Constitution II]

## Ambiguities & Conflicts

- [X] CHK048 Is the exact Arabic copy source of truth defined for required labels, empty states, and error messages? [Ambiguity, Spec FR-028]
- [X] CHK049 Are "completion," "late," "missed," and "pending" mapped to canonical Arabic terms in the requirements? [Ambiguity, Spec FR-011, Spec FR-028]
- [X] CHK050 Are the responsibilities split clearly between spec requirements and UI contract details so future tasks do not duplicate or contradict UX requirements? [Traceability, Spec UI Surface Requirements, UI Contract v1 UI Screens and States]

## Notes

- All UX requirement-quality items are resolved by the current spec, UI contract, plan, data model, Supabase contract, and generated task coverage.
- This checklist is scoped to UX requirement quality, empty states, and Arabic UI error handling.
