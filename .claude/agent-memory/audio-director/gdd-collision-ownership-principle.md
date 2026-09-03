---
name: gdd-collision-ownership-principle
description: NOVENA GDD review heuristic — the document whose own rules guarantee two effects will coincide must declare the arbitration rule, even when it doesn't own the mixing/implementation system
metadata:
  type: feedback
---

Recurring pattern in NOVENA design reviews (seen clearly across `design/gdd/combate-parry-absorcion.md`, sistema 1): if a GDD's own formulas/rules **structurally guarantee** two effects will coincide — not "might," but always, by construction — that GDD must write the precedence/arbitration rule itself, even though the actual mixing or implementation lives in a downstream system.

Examples where this was applied:
- The "Regla de precedencia armónica" (evento 4 Parry Justo vs. evento 8 combo-close): Fórmula 1 scores Parry Justo on the *last* parry of a combo, so the two always land on the same hit. Sistema 1 wrote the precedence rule (timbral variant, not layering) and cited it as "the sonic equivalent of AC V1 for particles" — even though sistema 16 (not yet authored) owns the actual mix.
- The combo length range `3 ≤ N ≤ 5`: sistema 20 owns attack-pattern composition, but sistema 1 fixed the legal range itself because two of its own invariants (Fórmula 7's floor, the audio cue's ceiling) would break otherwise.

**Why this matters**: deferring an arbitration rule to a downstream system for a collision that the upstream system itself guarantees produces a contract nobody downstream can satisfy — the downstream author has no way to know from their own document that the collision is structural rather than incidental.

**How to apply** (as audio-director): when two audio-relevant events are forced to coincide by a GDD's own math (not just "could overlap under bad luck"), push back if that GDD defers "which sound wins" entirely to sistema 16 / mix architecture. Ask for the precedence rule to live in the source document, mirroring the treatment [[combate-parry-absorcion-audio-status|evento 4/8 already got]]. Conversely, don't demand this for collisions that are merely probabilistic (general voice-budget overflow, unlucky timing) — those legitimately belong to sistema 16's mix/ducking architecture, not the source GDD.
