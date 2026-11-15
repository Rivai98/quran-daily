# Design direction from the owner's reference app (2026-11-15)

The owner shared screenshots of an existing personal khatma app as **inspiration
only**. حلقة must do better, keep its own identity (constitution Principle VI:
deep green, cream, gold only for ornament, Cairo UI, KFGQPC font only for Quran
text), and stay group-first. Do not copy its colors, icons, layout or copy.

## What to learn from it

| Pattern in the reference | How حلقة does it (better) | Spec |
|---|---|---|
| A big "today's wird" card: first words, start/end ayah, start/end page, two actions (read, done) | Wird card with the group name, portion name (unit-aware), start/end ayah and page from metadata, the opening words read from the source file, "اقرأ الآن" (primary) + "تمت القراءة" (secondary) | 003 (card + reader), 005 (home) |
| Khatma progress bar with "behind by N days" | Group progress: who read today (١٨ من ٣٠), cycle day (اليوم ٢ من ٨), personal streak; calm wording, no shaming | 005, 007 |
| Mushaf index by surah/juz with start page | Index tabs: السور / الأجزاء / الأحزاب / الصفحات + search, bookmarks | 003 |
| Bottom tabs | الرئيسية / مجموعاتي / المصحف / السجل (pending owner confirmation of the 4th tab) | 005 |
| "More" list: bookmark, Quranic sunan (Kahf, Mulk), daily reminder, settings | Settings + bookmarks + reminders; Friday Kahf reminder can be a 006 option | 003, 006 |
| Prayer times, azkar | Prayer times feed 006 reminders; azkar would be a new spec (008) only if the owner asks | 006 / 008 |

## Where حلقة must be better

- Group-first: every wird card shows the group and the members' progress.
- Calmer visuals: cream surfaces, one primary action per screen, Islamic
  geometric ornament instead of loud colored tiles.
- Full RTL polish, Arabic numerals, dark mode, 200% text.
