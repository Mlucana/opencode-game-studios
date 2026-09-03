---
name: feedback-performance-ac-methodology
description: NOVENA's validated performance-AC pattern (P0-P5 style) — deterministic forced triggers, dual P99 (global + localized), and separate prerequisite ACs for particle/audio budgets before trusting a frame-time gate.
metadata:
  type: feedback
---

This pattern was built up over two adversarial review passes of
`design/gdd/combate-parry-absorcion.md` (system 1/21) and confirmed by
`qa-lead`/`godot-specialist`/`creative-director` without pushback — treat it as
the house style for performance ACs on this project, not just a one-off fix.

**Rule 1 — never gate on RNG-dependent reproduction.** A performance AC that
relies on "play until the worst case happens naturally" is not a gate — the
original P1 required the coincidence of two visual events to occur "in live
play," which depended on enemy-AI RNG that didn't even exist yet. Fixed by
requiring a **deterministic QA-only debug trigger** that forces the
worst-case event coincidence on demand, N times per session (3-5), across all
relevant hardware/power profiles.

**Rule 2 — a global P99 hides localized stalls.** When the risk is a handful
of frames around a specific forced event (particle burst + audio layering at a
hitstop boundary), measure P99 **twice**: once over the full session, once
over a narrow window (±5 frames) around each forced trigger. The global P99
will pass even when every forced trigger spikes, because the spikes are a tiny
fraction of total frames.

**Rule 3 — separate the "is the budget even known" question from the
frame-time gate.** Before trusting a frame-time AC that depends on
particle/audio cost, add a prerequisite AC (P0 for particles, P5 for audio
voices) that measures the actual resource cost against the real category
budget (see [[feedback-vfx-budget-comparison]]) and has its own numeric
condition of failure. If the prerequisite fails, it explicitly invalidates the
downstream frame-time AC rather than letting it pass on unverified assumptions.

**Rule 4 — sustained/thermal degradation is a different failure mode than
instantaneous spikes, and needs its own AC.** A frame-time AC built around a
few minutes of forced-trigger testing will not catch throttling that only
shows up after 10-15+ minutes of continuous play. Added as P4: ≥20 min
continuous battery-mode play, checking for monotonic frame-time trend
degradation across the session, not just instant peaks.

**How to apply**: When authoring or reviewing performance ACs for any other
NOVENA system GDD, check whether these four failure modes apply, and use this
same structure (deterministic trigger / dual P99 / prerequisite budget AC /
sustained-session AC) rather than reinventing it per-system.
