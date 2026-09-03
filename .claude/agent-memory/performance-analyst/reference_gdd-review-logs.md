---
name: reference-gdd-review-logs
description: Per-GDD adversarial review history lives in design/gdd/reviews/[slug]-review-log.md, with root causes tracked as project-wide invariant IDs (R1, R2...) that can span multiple documents.
metadata:
  type: reference
---

Each GDD in NOVENA (e.g. `design/gdd/combate-parry-absorcion.md`) has a
companion review log at `design/gdd/reviews/[slug]-review-log.md`. It contains
the full history of `/design-review` passes: blocking items found, how they
were resolved, discrepancies between specialists (recorded even when
rejected), and amendments forced by *other* systems' reviews (cross-document
root causes are tagged with shared IDs like R1-R8, R2, R5 etc. and can live
partially in one doc and partially in another).

**Why this matters for performance review**: before doing an adversarial pass
on any system's performance ACs, read that system's review log in full — it
usually contains the exact reasoning (and self-corrections) behind why a
particular budget number or AC methodology was chosen, and flags what was
*not yet* re-verified after a later amendment. Findings that look novel may
already be logged as open items (check before re-reporting).

Also check `design/registry/entities.yaml` — shared constants/formulas used
across GDDs are canonicalized there, and past reviews have found the registry
itself out of sync with the GDD it's supposed to mirror (inverted formulas,
stale literals). Don't assume the registry is correct just because a GDD is.
