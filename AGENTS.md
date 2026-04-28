# AGENTS.md — ATMOSphere Lampa fork

This submodule inherits all parent ATMOSphere project AGENTS.md +
Constitution invariants. The full canonical authority is parent
`docs/guides/ATMOSPHERE_CONSTITUTION.md`. Read that first.

This file holds Lampa-specific agent guidance.

## Mandatory build/commit/push constraints

1. **Build via parent** `bash scripts/build.sh --skip-pull --skip-tests --skip-ota`
   only. The parent's `step_build_lampa` is the canonical entrypoint;
   never invoke this fork's gradle directly outside that helper.
2. **Commit / push** via parent `bash scripts/commit_all.sh "message"`
   only. Never `git commit` / `git push` directly inside this submodule
   for source changes — the parent's deepest-first cascade catches the
   pointer change.
3. **Tags** cascade: every parent tag is mirrored on this submodule
   at HEAD via parent `scripts/testing/release_tag.sh`. Owned-submodule
   set is now 10 (was 9 — Lampa added 1.1.5-dev).

## Lampa-specific guidance

- **applicationId stays `top.rootu.lampa`** — kept identical to upstream
  so existing user data / sources / preferences survive the rebrand.
  Renaming triggers PackageManager uninstall+reinstall and wipes
  `/data/data/<pkg>/` (Fix #118 + Fix #124 same rationale).
- **Gradle 7.5.1 needs Java 17, not 21** — the build helper picks JDK 17
  first. Java 21 (class file version 65) is rejected with
  "Unsupported class file major version 65".
- **Don't rebase** the fork against a much-newer upstream without
  diffing AndroidManifest, build.gradle, and signingConfigs first —
  upstream may have switched to AGP 8.x / gradle 8.x which would
  reopen the JDK pick logic.
- **WebView playback path**: Lampa renders UI in a WebView and hands
  off media playback to external Android players (Kodi / VLC / MPV /
  Nova / TorrServe). Fix #88 / Fix #102 secondary-display routing
  applies via the chosen player's MediaCodec — Lampa itself doesn't
  decode video. No subtitle forwarder needed inside Lampa.
- **Test coverage**: Lampa is fully covered by parent
  `pre_build_verification.sh` Section CN-LAMPA gates +
  `meta_test_false_positive_proof.sh` CM-LAMPA mutations + post-flash
  `test_lampa.sh`.

## MANDATORY ANTI-BLUFF COVENANT — END-USER QUALITY GUARANTEE (User mandate, 2026-04-28)

**Forensic anchor — direct user mandate (verbatim):**

> "We had been in position that all tests do execute with success and all Challenges as well, but in reality the most of the features does not work and can't be used! This MUST NOT be the case and execution of tests and Challenges MUST guarantee the quality, the completion and full usability by end users of the product!"

This is the historical origin of the project's anti-bluff covenant.
Every test, every Challenge, every gate, every mutation pair exists
to make the failure mode (PASS on broken-for-end-user feature)
mechanically impossible.

**Operative rule:** the bar for shipping is **not** "tests pass"
but **"users can use the feature."** Every PASS in this codebase
MUST carry positive evidence captured during execution that the
feature works for the end user. Metadata-only PASS, configuration-
only PASS, "absence-of-error" PASS, and grep-based PASS without
runtime evidence are all critical defects regardless of how green
the summary line looks.

**Tests AND Challenges (HelixQA) are bound equally** — a Challenge
that scores PASS on a non-functional feature is the same class of
defect as a unit test that does. Both must produce positive end-
user evidence; both are subject to the §8.1 five-constraint rule
and §11 captured-evidence requirement.

**Canonical authority:** parent
[`docs/guides/ATMOSPHERE_CONSTITUTION.md`](../../../../docs/guides/ATMOSPHERE_CONSTITUTION.md)
§8.1 (positive-evidence-only validation) + §11 (bleeding-edge
ultra-perfection quality bar) + §11.3 (the "no bluff" CLAUDE.md /
AGENTS.md mandate) + **§11.4 (this end-user-quality-guarantee
forensic anchor — propagation requirement enforced by pre-build
gate `CM-COVENANT-PROPAGATION`)**.

Non-compliance is a release blocker regardless of context.
