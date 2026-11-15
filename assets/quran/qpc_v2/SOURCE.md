# Printed Madinah Mushaf layout (constitution Principle VII)

Exact page/line rendering of the KFGQPC Madinah Mushaf (1421H print, 604 pages, 15 lines).
All files are stored byte-for-byte as downloaded by the project owner on 2026-11-15. Never edit.

| File | Content | Source |
|------|---------|--------|
| `qpc-v2-15-lines.db` (241,664 bytes) | SQLite `pages(page_number, line_number, line_type, is_centered, first_word_id, last_word_id, surah_number)` 9,046 rows; `info` (QCF V2 1421H print, 604 pages, 15 lines) | QUL "KFGQPC V2 layout (1421H print)" https://qul.tarteel.ai/resources/mushaf-layout/10 (zip sha256 697cbc7f16db1f56…) |
| `qpc-v2.db` (2,437,120 bytes) | SQLite `words(id, location, surah, ayah, word, text)` 83,668 rows, QPC V2 glyph codes per word | QUL "QPC V2 Glyph - Word by Word" https://qul.tarteel.ai/resources/quran-script/61 (zip sha256 a766a033cad47b36…) |
| `qpc_v2_fonts_manifest.json` | SHA-256 + size of each of the 604 page fonts p1.ttf..p604.ttf (208,121,760 bytes total) | QUL "QPC V2 Font" (page by page) https://qul.tarteel.ai/resources/font/249 (zip sha256 9ead3836904f2232…) |

Fonts are NOT bundled (too large). They are uploaded unchanged to the Supabase Storage public
bucket `mushaf-fonts` under `v2/p<page>.ttf`; the app downloads a page font on demand,
verifies its SHA-256 against the manifest before use, and caches it on the device. A
setting downloads all 604 pages for offline reading.

Publisher: King Fahd Glorious Quran Printing Complex (KFGQPC). Distributor: Quranic Universal
Library (Tarteel). QUL lists no license text; OWNER ACTION before store release: confirm the
KFGQPC terms of use and add attribution in the licenses page.
