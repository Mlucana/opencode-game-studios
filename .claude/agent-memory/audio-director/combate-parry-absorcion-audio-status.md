---
name: combate-parry-absorcion-audio-status
description: Audio-relevant open items in design/gdd/combate-parry-absorcion.md (sistema 1) as of the 2026-08-04 adversarial review (3rd pass, approval retirada)
metadata:
  type: project
---

Snapshot as of the 2026-08-04 review of `design/gdd/combate-parry-absorcion.md` (sistema 1/21, Foundation layer). Verify against the live file before trusting specifics — this doc has been amended repeatedly.

- `design/gdd/feedback-sonoro-parry.md` (sistema 16, "Feedback Sonoro del Parry") **does not exist yet**. Sistema 1 only specifies audio *requirements* and cross-system contracts; sistema 16 owns actual mix/bus/ducking/priority implementation.
- **P5** (voice-count budget prerequisite, "4-6 capas simultáneas" at the events-4/8/11 collision) exists in Acceptance Criteria but is still unmeasured on Steam Deck — open question, target owner `technical-director`/`audio-director`.
- The feedback table (events 1-13) was **never updated** to cover Ventana Especial (introduced 2026-08-03, enmienda 2ª pasada) or the lethal/non-lethal Golpe de Castigo split (enmienda G, 2026-08-04) — both are mechanically real, both are audio-silent in the table.
- The event vocabulary sistema 16 actually consumes per Dependencies is just generic **"parry exitoso"/"parry fallido"** — it does not carry the Golpe-vs-Ventana-Especial distinction that Regla 4 creates. Sistema 16 cannot pick a different sound per window type without separately inspecting the Postura/Repliegue side-effects.
- Priority column (Alta/Media) has no defined semantics and is nearly flat (12 of 14 event rows tagged "Alta"). Flagged in all 3 review passes so far; kept at Recommended severity each time on the grounds that "no budget exists to arbitrate against" — that rationale is now moot since **P5 states an explicit number**, created in the same pass that kept the finding at Recommended.
- Still-open Open Question: does evento 5's "golpe sordo" also play when a combo breaks mid-chain (evento 9)? Regla 9 says the aborted combo's final hit "conecta" — same trigger condition as evento 5 — so the Vida-damage sound arguably should play by the GDD's own rules, but the table only specs the crystal-dissolve audio for evento 9. Owner listed as sistema 16, but the underlying mechanic is owned by sistema 1.
- Regla 2 (hitstop/time authority, 4 normative sub-rules) classifies "jugador, ángel, VFX, cámara" as diegetic-4% and "HUD/UI" as real-time, but **never classifies audio/SFX playback into either bucket**. Whether impact SFX should pitch/time-stretch during the 5-tick hitstop is unanswered by the document.

How to apply: use as a starting point for the next review or for authoring sistema 16, but re-read the live file first — amendments to this doc have landed on nearly every pass.
