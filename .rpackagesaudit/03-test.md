---
id: 03-test
title: Run test suite & read coverage
depends_on: [02-document]
idempotent: true
---

## Objective
Run the full testthat suite to a clean pass and record the coverage percentage.

## Preconditions
- 02-document is done.
- `tests/testthat.R` and `tests/testthat/` exist. If they do not, scaffold with `usethis::use_testthat(3)` and surface that the suite is empty — an empty suite is a gap, not a pass.

## Steps
1. Run the suite:
   ```bash
   Rscript -e 'devtools::test(stop_on_failure = TRUE)'
   ```
2. If any test fails, fix the **code** first (tests are authoritative); only change a test when it encodes a wrong expectation. Re-run step 1.
3. Confirm testthat edition 3: `grep -q 'Config/testthat/edition: 3' DESCRIPTION || Rscript -e 'usethis::use_testthat(3)'`.
4. Read coverage (non-blocking — record the number, do not gate on it here):
   ```bash
   Rscript -e 'cov <- covr::package_coverage(quiet = TRUE); cat(sprintf("COVERAGE=%.1f%%\n", covr::percent_coverage(cov)))'
   ```
   Record `COVERAGE` in `STATE.md`. Target for core functions is >60%; flag if below but do not fail.

## Validation
- `devtools::test()` exits with all tests passing, 0 failures.
- A `COVERAGE=` value is recorded in `STATE.md` (or `covr unavailable` noted).

## Outputs
- Test pass record + coverage percentage in `STATE.md`.

## On failure
- Surface the failing test name, file, and expectation diff. If failure is environmental (missing Suggests package used unconditionally in a test), that is a real bug — the test should `skip_if_not_installed()`; flag it.

## Next
- 04-cran-check
