# Feature Specification: In-App Mushaf

**Feature Branch**: `003-in-app-mushaf`
**Created**: 2026-11-15
**Status**: Clarified (2026-11-15)
**Depends on**: specs 001 (reserved "اقرأ الآن" entry point, FR-036), 002, 004 (portion units)
**Input**: Owner: read the Quran inside the app, open my daily portion directly,
browse the whole Mushaf, keep my place, and show the khatm dua.

## Clarifications

### Session 2026-11-15

- Q: How is the Mushaf displayed? → A: Uthmani text (riwayah Hafs 'an 'Asim)
  rendered with the King Fahd Complex (KFGQPC) Uthmanic Hafs font, split into
  the 604 pages of the Madinah Mushaf. Works fully offline, supports dark mode
  and text size. Not page images.
- Q: Which features are in v1? → A: (1) "اقرأ الآن" opens the user's portion
  directly and offers "تمت القراءة" at its end, (2) browse the whole Mushaf by
  surah / juz / hizb / page, (3) last position + bookmarks, (4) the khatm dua
  after the end of the Quran.
- Q: Audio recitation? → A: Out of scope (a later spec after 007).
- Q: Which exact source files? → A: The official KFGQPC "QPC Hafs" Unicode text
  (ayah by ayah) and its matching "QPC Hafs" font, obtained from the Quranic
  Universal Library because the KFGQPC download site is not available yet.
  Tanzil `quran-data.xml` stays as the cross-check for pages, juz and quarters.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Read my portion now (Priority: P1)

From the assignment card (dashboard, personal assignment, and later the Home
tab of spec 005) the user taps "اقرأ الآن". The Mushaf opens on the first page
of their portion with the start ayah highlighted. A slim header shows the
portion name (e.g. "الحزب ١٢") and progress through it ("صفحة ٢ من ١٠"). On the
portion's last page a "تمت القراءة" action marks the assignment complete with
the spec 001 rules (grace, offline queue, undo).

**Why this priority**: The main daily action becomes: open the app, tap
"اقرأ الآن", read, tap "تمت القراءة", with no paper Mushaf or other app.

**Independent Test**: A member with hizb 12 today taps "اقرأ الآن", lands on
the hizb's first page with its first ayah highlighted, pages to the end, taps
"تمت القراءة", and the dashboard shows the portion completed.

**Acceptance Scenarios**:

1. **Given** an assignment for any unit (juz, half juz, hizb, quarter, page),
   **When** the user taps "اقرأ الآن", **Then** the Mushaf opens on the page
   containing the portion's start ayah, which is highlighted.
2. **Given** the user reaches the page containing the portion's end ayah,
   **When** it shows, **Then** the end ayah is marked and "تمت القراءة" is
   offered.
3. **Given** the portion is already completed, **When** the user opens it,
   **Then** it reads normally and shows the completed state instead of the action.
4. **Given** no network, **When** the user taps "اقرأ الآن", **Then** the Mushaf
   opens (all text is on the device) and completion queues offline.
5. **Given** a rest day (spec 004), **Then** "اقرأ الآن" is hidden.

---

### User Story 2 - Browse the whole Mushaf (Priority: P1)

A "المصحف" entry opens the Mushaf at the last position. An index lists the 114
surahs (name, ayah count, Meccan/Medinan, start page), the 30 juz and the 60
hizb, and a page jump (1-604). Pages turn by horizontal swipe in RTL order
(swipe right-to-left goes forward, like a printed Mushaf). Each page shows its
surah name, juz and page number from the source data, surah headers and the
basmala as they appear in the source.

**Independent Test**: Open "سورة الكهف" from the index, land on its first page,
swipe forward and back, jump to page 604, and return to the index.

**Acceptance Scenarios**:

1. **Given** the index, **When** a surah, juz, hizb or page is chosen, **Then**
   the reader opens on the correct page.
2. **Given** a page, **When** the user swipes, **Then** the next or previous page
   shows in Mushaf order (RTL).
3. **Given** dark mode or a larger text size, **When** a page renders, **Then**
   the text stays legible and the page scrolls vertically if it no longer fits,
   without changing which ayahs belong to the page.

---

### User Story 3 - Last position and bookmarks (Priority: P2)

The app remembers the last page read (separately from portion reading). The user
can bookmark an ayah or a page with an optional note and open bookmarks from
the index. Stored on the device; synced to the account so it survives reinstall.

**Acceptance Scenarios**:

1. **Given** the user reads page 250 and leaves, **When** they open "المصحف",
   **Then** it resumes at page 250.
2. **Given** a long-press on an ayah, **When** "إضافة علامة" is chosen, **Then**
   the bookmark appears in the bookmarks list and opens that ayah.

---

### User Story 4 - Khatm dua (Priority: P3)

After the last page of the Mushaf, and when a group's khatma completes, the app
offers "دعاء ختم القرآن" in a calm sheet. The dua text comes from a source the
owner approves (it is not Quran text, but it is religious text and is never
written by an agent).

**Acceptance Scenarios**:

1. **Given** the user swipes past page 604, **Then** the khatm dua shows.
2. **Given** the owner has not provided an approved dua text yet, **Then** the
   feature stays hidden (no placeholder text).

### Edge Cases

- A portion starts mid-page: the page opens with the start ayah highlighted and
  scrolled into view.
- A portion spans a page boundary at its end: "تمت القراءة" appears on the page
  with the end ayah.
- Text size at 200%: pages scroll vertically; ayah-to-page mapping never changes.
- The source files fail their checksum at startup: the Mushaf is disabled with
  an error state; nothing partial is shown (constitution VII).
- A group changes its portion unit (spec 004): "اقرأ الآن" uses the unit of the
  assignment itself.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Quran text MUST come only from an approved source named in the
  plan (KFGQPC or Tanzil Uthmani, Hafs), shipped byte-for-byte with a recorded
  checksum and license; no agent or human may type or alter any Quran text.
- **FR-002**: The font MUST be the KFGQPC Uthmanic Hafs font, used under its
  published license, with checksum.
- **FR-003**: Page, juz, hizb, surah and ayah boundaries MUST come from the
  source metadata (existing `quran-data.xml` and the source text), never typed.
- **FR-004**: "اقرأ الآن" MUST open the page containing the assignment's start
  ayah for every portion unit and highlight the portion's start and end ayahs.
- **FR-005**: The reader MUST offer "تمت القراءة" on the page containing the
  portion's end ayah, using spec 001 completion rules.
- **FR-006**: The Mushaf MUST provide an index by surah, juz, hizb and page,
  and RTL page swiping in Mushaf order.
- **FR-007**: The app MUST remember the last read page and support ayah/page
  bookmarks with optional notes, synced to the user's account.
- **FR-008**: The khatm dua MUST show only from an owner-approved source file;
  hidden if absent.
- **FR-009**: The Mushaf MUST work fully offline; no Quran text is fetched at
  runtime.
- **FR-010**: Reader chrome (header, actions, index) follows constitution
  Principles II and VI (RTL, Cairo for UI, dark mode, 200% text, 320dp); the
  Quran text itself uses only the KFGQPC font and is never restyled into
  another font.
- **FR-011**: Integrity checks MUST verify the text and font checksums before
  first display; on mismatch the Mushaf is disabled with an Arabic error.

### Key Entities

- **MushafPage**: number 1-604, ordered ayah references, surah/juz/hizb labels.
- **AyahRef**: surah (1-114), ayah number; text read from the source only.
- **ReadingPosition**: user, last page, updated at.
- **Bookmark**: user, ayah ref or page, note, created at.

## Success Criteria *(mandatory)*

- **SC-001**: From app open, a member reaches the first ayah of today's portion
  in at most 2 taps.
- **SC-002**: Any page opens in under 300 ms on a mid-range phone, offline.
- **SC-003**: Automated checks confirm, for every portion of all 5 units, that
  "اقرأ الآن" opens the page of its start ayah (100% match with the metadata).
- **SC-004**: Zero Quran characters exist in the repository outside the
  checksummed source files (enforced by a test).

## Assumptions

- Source candidates (exact edition fixed in the plan, owner approves):
  Tanzil "Uthmani" text (cc-by, verified) or the KFGQPC Hafs text that ships
  with its font; page mapping from `quran-data.xml` `<page>` entries.
- The project owner downloads or approves downloading the source files; agents
  never edit them.
- The khatm dua text and its source are provided by the owner (owner-provided
  asset).
- Bookmarks/last position sync uses a small table in the existing backend.
- Audio, tafsir and translation are out of scope.
