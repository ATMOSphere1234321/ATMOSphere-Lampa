# CLAUDE.md — ATMOSphere Lampa fork

ATMOSphere's platform-signed fork of `lampa-app/LAMPA` — the Kotlin
Android client/wrapper for the Lampa media-library JS frontend. The
shipped variant is `top.rootu.lampa` (applicationId kept identical to
upstream so existing user data / sources / preferences survive the
ATMOSphere rebrand). Built from source by parent `scripts/build.sh`
`step_build_lampa` between Nova-Player and MPV builds (Step 2.12).

## Project Overview

- **Package** (release): `top.rootu.lampa`
- **LOCAL_MODULE**: `atmosphere-lampa` (parent's `prebuilt_apps/Android.mk`)
- **LOCAL_CERTIFICATE**: `platform` — AOSP re-signs at image-assembly time
- **Repo**: `git@github.com:ATMOSphere1234321/ATMOSphere-Lampa.git`
- **Parent path**: `device/rockchip/atmosphere/lampa`
- **Upstream**: `lampa-app/LAMPA` (Kotlin, ~570⭐, AGPL-style)

## Build (from parent)

```bash
bash scripts/build.sh --skip-pull --skip-tests --skip-ota
```

`step_build_lampa` picks Java 17 first (gradle 7.5.1 in the fork rejects
Java 21's class file major version 65), auto-creates the standard Android
debug keystore + sets the `KEYSTORE_FILE` / `KEYSTORE_PASSWORD` /
`RELEASE_SIGN_KEY_*` env vars (the upstream `signingConfigs.release` falls
back to env vars when `app/keystore/keystore_config` is missing), runs
`./gradlew :app:assembleRelease`, and copies the resulting APK to
`device/rockchip/rk3588/prebuilt_apps/atmosphere-lampa.apk`. AOSP then
strips the debug signature and re-signs with the platform key.

## ATMOSphere integration points

- **Role**: media-library frontend. Lampa renders its UI in a WebView,
  resolves stream URLs via JS plugins from configured "sources" (TMDB
  + various external CDN-aggregator endpoints), and hands off playback
  to external Android players (Kodi / VLC / MPV / Nova / TorrServe).
  Lampa itself doesn't decode video — the chosen external player does,
  so Fix #88 / Fix #102 secondary-display routing applies via the
  downstream player's MediaCodec path.
- **TorrServe handoff**: configurable in Lampa Settings → "Torrent
  Service URL" — points at `http://127.0.0.1:8090` (the shipped
  ATMOSphere-TorrServe instance). Validated by post-flash
  `test_lampa.sh` Section TorrServe-Handoff.
- **Subtitles**: rendered by the chosen external player. No subtitle
  forwarder needed in Lampa itself.

## Pre-build / post-flash coverage

- Pre-build gate Section: `CN-LAMPA` — submodule presence,
  Android.mk entry, device.mk PRODUCT_PACKAGES, build helper +x,
  step_build_lampa wiring, applicationId, JDK pick, mutation count.
- Meta-test mutations: `CM-LAMPA1..CM-LAMPA9` paired with each gate.
- Post-flash test: `test_lampa.sh` — package installed + APK present
  in `/system/app/atmosphere-lampa/`, launch smoke (cold start ≥ 5 s,
  no crash), main-activity dumpsys, WebView load assert, TorrServe
  handoff probe (HTTP :8090 readable), Presenter integration
  (VideoPlaybackDetector recognises lampa for Tier-2 task-move).

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

## MANDATORY §12 HOST-SESSION SAFETY — INCIDENT #2 ANCHOR (2026-04-28)

**Second forensic incident:** on 2026-04-28 18:36:35 MSK the user's
`user@1000.service` was again SIGKILLed (`status=9/KILL`), this time
WITHOUT a kernel OOM kill (systemd-oomd inactive, `MemoryMax=infinity`)
— a different vector than Incident #1. Cascade killed `claude`,
`tmux`, the in-flight ATMOSphere build, and 20+ npm MCP server
processes. Likely cumulative cgroup pressure + external watchdog.

**Mandatory safeguards effective 2026-04-28** (full text in parent
[`docs/guides/ATMOSPHERE_CONSTITUTION.md`](../../../../docs/guides/ATMOSPHERE_CONSTITUTION.md)
§12 Incident #2):

1. `scripts/build.sh` MUST source `lib/host_session_safety.sh` and
   call `host_check_safety` BEFORE any heavy step.
2. `host_check_safety` has 7 distress detectors including conmon
   cgroup-events warnings (#6) and current-boot session-kill events
   (#7).
3. Containers MUST be clean-slate destroyed + rebuilt after any
   suspected §12 incident. `mem_limit` is per-container, not
   per-user-slice — operator MUST cap Σ `mem_limit` ≤ physical RAM
   − user-session overhead.
4. 20+ npm-spawned MCP server processes are a known memory multiplier;
   stop non-essential MCPs before heavy ATMOSphere work.
5. **Investigation: Docker/Podman as session-loss vector.** Per-container
   cgroups don't prevent cumulative user-slice pressure; conmon
   `Failed to open cgroups file: /sys/fs/cgroup/memory.events`
   warnings preceded the 18:36:35 SIGKILL by 6 min — likely correlated.

This directive applies to every owned ATMOSphere repo and every
HelixQA dependency. Non-compliance is a Constitution §12 violation.



## MANDATORY §12.6 MEMORY-BUDGET CEILING — 60% MAXIMUM (User mandate, 2026-04-30)

**Forensic anchor — direct user mandate (verbatim):**

> "We had to restart this session 3rd time in a row! The system of
> the host stays with no RAM memory for some reason! First make sure
> that whatever we do through our procedures related to this project
> MUST NOT use more than 60% of total system memory! All processes
> MUST be able to function normally!"

**The mandate.** Project procedures MUST NOT use more than **60%
of total system RAM** (`HOST_SAFETY_MAX_MEM_PCT`). The remaining
40% is reserved for the operator's other workloads so the host can
keep serving them while project work proceeds.

**Three consecutive session-loss SIGKILLs on 2026-04-30** during
1.1.5-dev — every one happened while `scripts/build.sh` was running
`m -j5` AOSP. Each Soong/Ninja job peaks at ~5–8 GiB RSS;
collective RSS overran the 60% envelope and the kernel OOM-killer
escalated, taking down `user@1000.service`. **§12.1's pre-flight
check (refusing to start if host already distressed) was not enough**
— the missing piece was an active CONSTRAINT on heavy work itself.

**Mandatory protections (rock-solid):**

1. `HOST_SAFETY_MAX_MEM_PCT` defaults to 60 in
   `scripts/lib/host_session_safety.sh`.
2. `HOST_SAFETY_BUDGET_GB` is computed at source-time from
   `MemTotal × MAX_PCT/100`.
3. `bounded_run` clamps `MemoryMax` down to the budget if the
   caller asks for more (cgroup-level enforcement via
   `systemd-run --user --scope -p MemoryMax=…`).
4. `host_safe_parallel_jobs` and `host_safe_build_jobs` return
   the safe `-j` count given an estimated per-job RSS, capped at
   `nproc`.
5. `scripts/build.sh` wraps `m -j` in `bounded_run`. If the
   build's collective RSS exceeds the budget, only the scope is
   OOM-killed; `user@<uid>.service` stays alive.

**Captured-evidence enforcement.** Pre-build gate
`CM-MEMBUDGET-METATEST` locks all 7 invariants and fires every
pre-build run.

**No escape hatch.** §12.6 has NO operator-facing override flag.
The cap exists for the operator's own protection; bypassing it is
the bluff the §11.4 covenant specifically prohibits. Operators who
need more headroom should reduce parallelism, close other
workloads, or add RAM — NOT raise the percentage.

**Canonical authority:** parent
[`docs/guides/ATMOSPHERE_CONSTITUTION.md`](../../docs/guides/ATMOSPHERE_CONSTITUTION.md)
§12.6.

Non-compliance is a release blocker regardless of context.
