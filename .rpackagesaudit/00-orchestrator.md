---
id: 00-orchestrator
title: Orchestrator — drive the package lifecycle to release-ready
depends_on: []
idempotent: true
---

## Objective
Drive an R package from a fresh checkout to CRAN-release-ready by running the workflow processes in dependency order, tracking status in `STATE.md`, resuming wherever it left off.

## Dependency graph
```
01-env-setup
   └─> 02-document
          └─> 03-test
                 ├─> 04-cran-check ──┬─> 05-tidyverse-align ─┐
                 │                    ├─> 07-pkgdown ─────────┤
                 │                    └─> 08-ci ──────────────┤
                 └─> 06-codecov ──────────────────────────────┤
                                                               └─> 09-release-prep ─> DONE
```
Runnable-from-04 set: {05, 07, 08}. 06 depends only on 03. 09 depends on {04, 05, 06, 07, 08}.

## Entry conditions
- Invoked at the root of an R package (`DESCRIPTION` present). If not, stop and report.
- This is the **only** file the user invokes. It is safe to re-run; it resumes from `STATE.md`.

## State file
- Maintain `.claude/workflows/STATE.md`. If absent, create it with every process set to `pending`, plus empty `## Identity`, `## Design profile`, and `## Results` sections.
- Status values per process: `pending` | `running` | `done` | `failed` | `blocked`.
- **Never** overwrite STATE.md wholesale — update the relevant line/section in place. Append a timestamped note to `## Results` on each transition.

### STATE.md template (create only if missing)
```markdown
# Workflow state

Updated: <iso8601>

## Processes
- [ ] 01-env-setup — pending
- [ ] 02-document — pending
- [ ] 03-test — pending
- [ ] 04-cran-check — pending
- [ ] 05-tidyverse-align — pending
- [ ] 06-codecov — pending
- [ ] 07-pkgdown — pending
- [ ] 08-ci — pending
- [ ] 09-release-prep — pending

## Identity
<!-- PKGNAME, VERSION, LICENSE, org/repo, branch, bioc target -->

## Design profile
<!-- prefix, data structure, S3 classes, verbs -->

## Results
<!-- timestamped log of each process outcome + final check line -->
```

## Loop
1. Read `STATE.md`. If missing, create from the template above.
2. Compute the runnable set: processes whose status is `pending` and whose every `depends_on` is `done`.
3. If the runnable set is empty:
   - all `done` → go to global stop (success).
   - some `failed`/`blocked` with no runnable work → go to global stop (blocked).
4. Pick the lowest-numbered runnable process (deterministic order: 01,02,03,04,06,05,07,08,09).
5. Mark it `running` in STATE.md. Open `.claude/workflows/NN-<slug>.md` and execute its Steps exactly.
6. Run that process's Validation block.
   - pass → mark `done`, append result to `## Results`, go to 1.
   - fail → apply the process's "On failure"; **retry automatically up to 2 times** for transient issues (network, flaky install). If still failing, mark `failed`, record the exact error, and escalate (see below).
7. Repeat until stop.

## Global stop conditions
- **Success:** all nine processes `done`. Print the final report (below).
- **Blocked:** no runnable process remains and at least one is `failed`/`blocked`. Print what is blocked and why.
- **Hard stop (escalate immediately, do not retry):** not at a package root; `load_all` parse error (01); a system-dependency install failure; a CRAN check error that requires a human design decision (e.g. a public API rename with downstream users).

## Escalate to the user vs. retry automatically
- **Retry automatically (≤2×):** transient dependency/network failures; re-runnable doc/test fixes the agent can make itself.
- **Escalate:** anything in Hard stop; size gate (09) unsatisfiable without dropping required data; a check note that is genuinely environment-bound and cannot be fixed here; any change that would break a documented public API.

## Final report (print on success or block)
```
═══════════════════════════════════════════════
  <PKGNAME> — Lifecycle run
═══════════════════════════════════════════════
Identity      : <pkg> <version> | <license> | <org>/<repo> @ <branch>
Processes     : <done>/9 done, <failed> failed, <blocked> blocked
R CMD check   : <final result line>
Tests         : <pass/skip/fail>   Coverage: <pct or n/a>
Tarball       : <name> <size MB>
Escalations   : <list, or none>
Files touched : <summary>
═══════════════════════════════════════════════
```

## Validation
- Every process ends `done`, or the run terminates at a clearly-reported block/escalation with `STATE.md` reflecting reality.

## Outputs
- Updated `.claude/workflows/STATE.md`; the final report.

## On failure
- If the orchestrator itself cannot proceed (e.g. STATE.md corrupted), back up STATE.md to `STATE.md.bak`, regenerate from template preserving any recoverable status, and report the recovery.

## Next
- Re-invoke to resume. Terminates when all processes are `done`.
