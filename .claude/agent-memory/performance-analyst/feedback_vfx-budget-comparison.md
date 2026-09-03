---
name: feedback-vfx-budget-comparison
description: Never validate a VFX/particle performance AC against the global draw-call ceiling — check the art bible's per-category breakdown for the real combat VFX allowance first.
metadata:
  type: feedback
---

When reviewing a particle/VFX performance AC (draw calls, emitter counts, etc.),
do not compare the measured cost against the project-wide draw-call ceiling in
`technical-preferences.md` (NOVENA: <1000/scene). That ceiling is a generous
whole-scene budget, not what VFX actually gets to spend.

**Why**: In the `combate-parry-absorcion` GDD (system 1/21), P0 originally
contrasted particle emitter draw-call cost against the global <1000 ceiling and
always passed trivially — even a 45-draw-call cost would have passed a check
against 1000, while quietly blowing the real combat VFX budget. I caught this on
myself in a later pass (self-correction logged in
`design/gdd/reviews/combate-parry-absorcion-review-log.md`, 2026-08-01 re-review,
finding #2): the art bible (section 8.6) fixes the **combat peak at 40-80 draw
calls total**, with a per-category breakdown (protagonist 3-5, boss 2 +1/coro,
arena 5-10, UI 1-3, "VFX = resto"). In the worst-case combat composition that
leaves only **~20 draw calls** for all combat VFX combined — roughly 30-50x
tighter than the global ceiling.

**How to apply**: Before writing any P0-style particle/VFX performance AC or
evaluating one, read the art bible's draw-call/particle/texture section
(`design/art/art-bible.md`, section ~8.6-8.7 as of this writing — verify the
section number still matches, art bible may be renumbered) and use the
**per-category remainder for VFX**, not the scene-wide ceiling, as the
pass/fail threshold. Always give the performance AC an explicit numeric
condition of failure — a prerequisite that only "documents a number" without a
pass/fail line is a gate that always passes.
