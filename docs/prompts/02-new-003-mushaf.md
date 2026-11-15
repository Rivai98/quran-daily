# Prompt: new spec 003 (in-app Mushaf)

Run in Spec Kit / Codex:

```
/speckit-specify
```

Paste everything inside the block below as the input. Spec Kit will create
`specs/003-in-app-mushaf/`.

---

```text
Feature: In-app Mushaf that opens directly on the member's daily wird.

Read .specify/memory/constitution.md first; it is binding. Principle VII
(Quran Content Integrity) is NON-NEGOTIABLE: no Quranic text, surah name,
ayah number, or juz boundary may be written by hand or generated. All of it
comes from a verified source shipped unmodified under assets/quran/ with
SOURCE.md and SHA-256 checksums verified by a test.

Context: members of a Quran group (spec 001) are each assigned one juz per
day that rotates daily. Today they read it in a printed or separate Mushaf
app and then mark "تم". We want the Mushaf inside the app.

Requirements:
1. From the dashboard and the personal assignment screen, "اقرأ الآن" opens
   the Mushaf exactly at the first ayah of today's assigned juz (or a
   volunteered juz).
2. The reader shows clear juz boundaries: where today's wird starts and ends,
   and progress inside the juz (e.g. page X of Y in this juz).
3. Reaching the end of the juz shows a completion prompt with the primary
   action "سجّل إتمام الجزء" that uses the existing completion flow
   (including offline queueing from spec 001).
4. Juz 30 is followed by دعاء الختم, shown clearly as du'a, not Quran
   (different style, no Mushaf font, no ayah markers). The du'a text is
   provided and approved by the project owner.
5. The member can also browse freely: by surah, by juz, by page.
6. The app remembers the last read position per member per day so they can
   resume.
7. The whole Mushaf works fully offline (bundled, no download at runtime).
8. Text size is adjustable via the existing Quran text-size setting;
   light/dark/sepia-friendly reading backgrounds follow the design system.
9. Screen stays awake while reading (optional toggle in settings).
10. Arabic UI, RTL; page navigation direction matches a printed Arabic
    Mushaf (the next page is on the left).

[NEEDS CLARIFICATION] Mushaf display mode:
  A) Reflowable text: Tanzil verified Uthmani text + KFGQPC Uthmanic Hafs
     font. Small size (~2-5 MB), text scales freely, accessible to screen
     readers. Page layout differs from the printed Mushaf.
  B) Printed Madani page layout (604 pages) using KFGQPC/QCF per-page glyph
     fonts or page images. Looks exactly like the printed Mushaf, but large
     (roughly 50-200 MB) and text size only zooms.
  Recommendation: A for v1 (text-size and accessibility rules in the
  constitution), B possible later as an optional mode.

Out of scope: audio recitation, tafsir, translation, bookmarks beyond
last-position, search inside Quran text, memorization tools.
```

---

## After this prompt

1. `/speckit-clarify` - decide the display mode (A or B).
2. `/speckit-plan` - the plan MUST name the exact Quran source, edition,
   riwayah (Hafs), version, and license, and where the files come from.
   You (the project owner) download the source files yourself from the
   official site and review them; the agent must not fabricate them.
3. `/speckit-tasks`, then `/speckit-analyze`.
