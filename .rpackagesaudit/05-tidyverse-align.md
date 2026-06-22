---
id: 05-tidyverse-align
title: Tidyverse design alignment
depends_on: [04-cran-check]
idempotent: true
---

## Objective
Refactor the public API for tidyverse design quality — naming, type stability, cli/rlang errors, S3 design — without breaking compliance.

## Preconditions
- 04-cran-check is done (package is CRAN-clean). This pass runs **after** check passes, per design-guide convention.
- A clean git working tree (commit or stash first) so refactors are reviewable.

## Steps
1. **Derive the design profile** from `R/`: function prefix (e.g. `mp_`), primary data structure (tibble / S3 class), verb vocabulary, S3 classes and their methods. Record it in `STATE.md` under `## Design profile`.
2. **Naming.** Every exported function is `PREFIX_verb_noun()` / `PREFIX_noun()`: standard tidyverse verbs (`read`/`write`/`build`/`filter`/`plot`/`validate`/`run`), singular nouns, snake_case, consistent prefix. Rename only with a deprecation path: keep the old name as a thin wrapper emitting `lifecycle::deprecate_warn()`; add `lifecycle` to `Imports`; update internal calls, tests, vignettes, README. Never silently rename.
3. **Type stability.** Each exported function returns the same type regardless of input — return a 0-row tibble (correct columns), never `NULL`, for empty results; no scalar-vs-vector or list-vs-tibble branching. Document the exact return type/columns in `@return`.
4. **Error handling.** Migrate user-facing messaging to `cli::cli_abort()` / `cli_warn()` / `cli_inform()` (never base `stop`/`warning`/`message`/`cat`). Add top-of-function input validation; thread `call = rlang::caller_env()` so errors point at the user's call. Add small internal `.check_*` helpers where validation repeats.
5. **S3 design.** For each class: low-level `new_<class>()` (internal), `validate_<class>()`, user-facing helper/constructor; implement at minimum `print`, `format`, `summary`, and `as_tibble`/`autoplot` where the class wraps tabular/plottable data. `print` returns `invisible(x)`.
6. **Plots.** Plot functions return a ggplot object (never render in place), use `.data$col` in `aes()`, colorblind-safe palettes, and set `labs()`.
7. Re-document and re-check after refactors: `Rscript -e 'devtools::document(); devtools::test()'` then re-run 04's check command. Refactors must not introduce new warnings/notes.

## Validation
- `devtools::check(args = c("--as-cran","--no-manual"))` still reads `0 errors | 0 warnings`.
- `devtools::test()` passes; snapshot tests (if added) capture stable error messages.
- Design profile recorded in `STATE.md`.

## Outputs
- Refactored `R/`, possibly new `R/utils-checks.R`, deprecation wrappers; updated tests/vignettes.

## On failure
- If a rename would break a documented public API with downstream users, surface it and the proposed deprecation plan rather than forcing the change.

## Next
- orchestrator decides
