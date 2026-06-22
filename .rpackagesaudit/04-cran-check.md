---
id: 04-cran-check
title: R CMD check --as-cran (fix & iterate loop)
depends_on: [02-document, 03-test]
idempotent: true
---

## Objective
Drive `R CMD check --as-cran` to 0 errors and 0 warnings (ideally 0 notes), fixing root causes and re-running until clean.

## Preconditions
- 02-document and 03-test are done.
- DESCRIPTION audit basics are in place (see Steps 1–2; these are checked and fixed here).

## Steps
1. **DESCRIPTION audit.** Verify and fix in place:
   - `Title:` Title Case, no trailing period, ≤ 65 chars. `Description:` ≥ 2 sentences, ends with a period, does not start with the package name / "A package".
   - `Authors@R:` uses `person()` with a `cre` email and ORCID where known.
   - `License:` matches the files present (`MIT + file LICENSE` ⇒ both `LICENSE` and `LICENSE.md` exist).
   - `URL:`/`BugReports:` point to the real `<org>/<repo>` from STATE.md. `Encoding: UTF-8`.
   - Remove `LazyData: true` if there is no `data/` directory.
2. **Dependency cross-check.** Every `Imports:` package is used (`grep -rn "<pkg>::" R/` returns a hit) — remove orphans. Every `pkg::fun()` in `R/` is declared in `Imports`/`Suggests` — add missing. **Bioconductor packages go in `Suggests` only** (unless this package itself targets Bioconductor) and every call site is guarded by `requireNamespace(..., quietly = TRUE)`.
3. **Code-quality sweep** across `R/` (fix every hit): no `library()`/`require()`; no bare `T`/`F`; no `:::`; no `cat()`/`print()` for user messaging (use `cli`); no `setwd()`; no hardcoded paths; `options()`/`par()` wrapped with `on.exit()`; `seq_along()`/`seq_len()` not `1:length()`; `inherits()` not `class(x) ==`; `vapply()` not `sapply()`. Add `#' @importFrom rlang .data` and use `.data$col` in dplyr/tidyr pipes to clear "no visible binding" notes.
4. Run the check (prefer the canonical script if present):
   ```bash
   if [ -f _build.R ]; then Rscript _build.R; else \
     Rscript -e 'devtools::document(); devtools::check(args = c("--as-cran","--no-manual"))'; fi
   ```
5. **The loop.** Read every ERROR/WARNING/NOTE, fix the root cause, run `devtools::document()`, re-run step 4.
   - errors > 0 OR warnings > 0 → fix and repeat.
   - notes > 0 AND fixable → fix and repeat.
   - notes > 0 AND only "New submission" → accept; record in `cran-comments.md` (handled in 09).
6. Never wrap `check()` in `suppressWarnings()`. Never add a file to `.Rbuildignore` to hide a real content problem — only to exclude genuine dev-only files.

## Validation
- Final `devtools::check()` line reads `0 errors | 0 warnings | N notes`, where any remaining note is `New submission` only.
- Record the final result line in `STATE.md`.

## Outputs
- A CRAN-clean package state; result line in `STATE.md`.
- Possibly modified `DESCRIPTION`, `R/*.R`, `.Rbuildignore`.

## On failure
- If a note/warning is genuinely environment-bound (e.g. a system lib that cannot be installed here), document it verbatim in `STATE.md` and the final report rather than masking it.
- If the loop does not converge after repeated passes, surface the persistent item to the user with the exact check output.

## Next
- orchestrator decides (05-tidyverse-align, 06-codecov, 07-pkgdown, 08-ci all become runnable)
