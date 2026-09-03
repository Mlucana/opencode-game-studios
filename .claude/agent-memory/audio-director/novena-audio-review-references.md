---
name: novena-audio-review-references
description: Where NOVENA's per-system GDD review history lives, and the authoring status of the not-yet-written audio system (sistema 16)
metadata:
  type: reference
---

- Each GDD's review history lives at `design/gdd/reviews/[system-slug]-review-log.md` (e.g. `design/gdd/reviews/combate-parry-absorcion-review-log.md`). Read the log before re-reviewing a system — it records what was already flagged, resolved, rejected, or deliberately left open, and who adjudicated discrepancies between specialists.
- Sistema 16, "Feedback Sonoro del Parry" (`design/gdd/feedback-sonoro-parry.md`), **has not been authored yet**. It is referenced repeatedly by sistema 1 (Combate de Parry-Absorción) as the future owner of audio mix/bus/ducking/priority architecture for combat. Several constraint handoffs and Open Questions in sistema 1 target it directly.
- `design/registry/entities.yaml` holds canonical constants/formulas shared across GDDs (e.g. `ventana_castigo`, `gracia_salida_castigo`, tick-based knobs). Check it for the current canonical value of a shared symbol rather than trusting a single GDD's copy — the registry has been the source of truth that resolved at least one cross-document contradiction (the `restantes(T)` inclusive/exclusive counting dispute between sistema 1 and sistema 2).

How to apply: before reviewing or authoring any audio-relevant NOVENA GDD, check the relevant review-log first, and confirm whether sistema 16 exists yet before assuming any mix/ducking/priority decisions have already been made elsewhere.
