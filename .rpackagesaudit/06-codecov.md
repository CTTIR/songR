---
id: 06-codecov
title: Wire Codecov test coverage
depends_on: [03-test]
idempotent: true
---

## Objective
Add Codecov coverage tracking: workflow, config, badge, `.Rbuildignore` and DESCRIPTION entries — without touching source in `R/`.

## Preconditions
- 03-test is done (suite passes; `covr::package_coverage()` runs locally).
- `<org>/<repo>` and `<branch>` known from STATE.md (01-env-setup).

## Steps
1. **Workflow.** If `.github/workflows/test-coverage.yaml` does not exist, create it from the standard `r-lib/actions` template (checkout → setup-r → setup-r-dependencies with `any::covr, any::xml2` → `covr::package_coverage()` + `covr::to_cobertura()` → `codecov/codecov-action@v4` with `files: ./cobertura.xml`, `fail_ci_if_error: false`). If it exists and is functional, leave it and note so.
2. **Config.** Create `codecov.yml` at repo root with `comment: false`, `informational: true`, `threshold: 1%`, and `ignore:` of `tests`, `vignettes`, `inst`, `R/RcppExports.R`.
3. **`.Rbuildignore`.** Append `^codecov\.yml$` and ensure `^\.github$` is present (idempotent — check before appending).
4. **DESCRIPTION.** Add `covr` to `Suggests:` (alphabetical), never to `Imports:`. Use `usethis::use_package("covr", "Suggests")` or edit directly.
5. **Badge.** In the `<!-- badges: start -->` / `<!-- badges: end -->` block of `README.Rmd` (preferred) or `README.md`, ensure a Codecov badge:
   `[![Codecov test coverage](https://codecov.io/gh/<org>/<repo>/branch/<branch>/graph/badge.svg)](https://app.codecov.io/gh/<org>/<repo>?branch=<branch>)`
   Substitute real values from STATE.md. Preserve other badges. If you edited `README.Rmd`, rebuild: `Rscript -e 'devtools::build_readme()'`.
6. Re-run `devtools::check(args = c("--as-cran","--no-manual"))` to confirm these infra changes introduce no new note (e.g. `codecov.yml` must be build-ignored).

## Validation
- `.github/workflows/test-coverage.yaml` and `codecov.yml` exist.
- `covr` is in `Suggests`; `^codecov\.yml$` in `.Rbuildignore`; Codecov badge present in README.
- `devtools::check()` shows no new error/warning/note vs. 04's result.

## Outputs
- `test-coverage.yaml`, `codecov.yml`, updated `DESCRIPTION`, `.Rbuildignore`, `README.*`.

## On failure
- If `covr::package_coverage()` fails locally, report the error but do not block — Codecov runs in CI. Note it in STATE.md.

## Next
- orchestrator decides
