---
name: project-novena-gdd-review-process
description: How GDD adversarial review and amendment tracking works for NOVENA (system 1 combate-parry-absorcion and sibling systems)
metadata:
  type: project
---

NOVENA is the game project (Godot 4.7). GDDs live in `design/gdd/`, one file per
system (21 systems total per `design/gdd/systems-index.md`). Each GDD has a
companion review log at `design/gdd/reviews/[system-slug]-review-log.md` — one
dated entry per `/design-review` pass, tagged with a Verdict and a
Blocking/Recommended count, using the severity vocabulary **blocking /
recommended / nice-to-have** (not the S1-S4 bug taxonomy — that's reserved for
runtime bugs, not design-doc findings).

**Why this matters**: when asked to review a GDD, always read its review log in
full before reviewing the doc — it contains the history of prior specialist
findings, which ACs were added/renumbered and why, and explicitly named
"residual" defects the doc's own authors flagged as not-yet-closed. Don't
re-litigate items the log already marked closed-and-reverified unless you have
new evidence.

**Recurring process lesson (seen 3x in system-1's history, as of 2026-08-04)**:
amendments that fix one instance of a bug class ("Regla X was quantified over
subset S instead of the full set") reliably miss sibling locations quantified
the same way, even when the amendment explicitly does a text sweep and claims
"N occurrences found and fixed." Each pass finds new misses the prior pass's
sweep didn't catch, because grepping for a literal string (e.g. "Golpe") misses
locations that use paraphrased prose, edge-case tables, or formula prose that
never say the trigger word at all. **Practical implication for qa-lead**: when
verifying an amendment's coverage, don't trust "we found N occurrences" — do an
independent fresh sweep starting from *behavioral scope* (what does this rule
actually claim happens for ALL cases X, and does every X really share that
behavior per the rest of the doc), not from *lexical* search.

**Cross-system dependency pattern**: GDDs regularly declare ACs as `bloqueado`
(blocked) when they require a stub/system that doesn't exist yet (e.g. C12b,
D10 in system 1, waiting on system 20's boss-AI patterns and system 9's
relic system respectively). This is an accepted, established convention in
this codebase, not an anomaly — but it means "0 open blockers" at GDD-approval
time can still hide untested core guarantees until those stub systems land.
Worth flagging explicitly at each such block: what's the actual ship risk if a
vertical slice implements the *dependent* mechanic (e.g. combos) before the
blocking stub exists.

See also [[feedback-qa-lead-adversarial-review-style]] for how thorough these
reviews are expected to be.
