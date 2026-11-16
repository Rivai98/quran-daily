# Owner's standing rules for حلقة (collected from his phone reviews, 2026-11-15)

Every agent MUST satisfy all of these on every screen it touches. The owner tests on a real
Samsung phone in DARK mode; light mode must also be perfect.

## Look and feel
- Calm, spiritual, polished. Islamic geometric ornament must be refined and subtle (never a
  busy tile grid). Gold only for ornament. Deep green primary, cream/charcoal surfaces.
- Cards: one consistent style (ui-craft.md). Status = small badge next to the title, never a
  full-width pill that looks like a button.
- Icons everywhere they help (meta lines, actions, statuses), one rounded icon family, and
  icon color ALWAYS follows its text/button foreground (no black icons in dark mode).
- Buttons: one clear primary per card/screen, readable secondary in dark mode, 48dp+.
- No layout jumps, shaking or flicker when switching tabs or refreshing (keep content on
  screen, refresh quietly).
- Text never clipped or overflowing (titles ellipsize or fit; bands/badges scale).

## Arabic and RTL
- Everything Arabic, RTL. Chevrons/back arrows point the RTL way (forward = left).
- Mixed numbers + words built with the shared Arabic formatting helper (isolates) so they
  never scramble; Arabic-Indic digits.
- Greeting uses the FIRST name only, modest size.

## Behavior and copy
- Errors: the real reason in calm Arabic (e.g. 2-group limit, not "check connection"),
  shown as snackbar/banner, never giant blocks inside cards.
- Search: debounced, keeps results visible, never reloads the page on each tap.
- Each user has max 2 groups: explain gently where joining/creating is blocked.
- Sign-out visible in حسابي (with confirm). Illustrated avatars (man with kufi, woman with
  hijab, ornament) chosen in edit profile and shown everywhere.

## Mushaf (owner's top priority)
- Pages identical to the printed Madinah Mushaf (KFGQPC V2, 604 pages, 15 lines, same line
  breaks, same calligraphy). Never alter Quran text/glyphs (constitution VII).
- Full screen, distraction-free; tap toggles the slim chrome; screen stays awake.
- Page turning in Arabic order: next page on the LEFT.
- Portion mode shows only the portion's pages, never wraps, ends with a calm completion
  page ("أتممت قراءة وردك") and the تمت القراءة action.
- Surah title band and basmala never clipped; dark mode legible.
