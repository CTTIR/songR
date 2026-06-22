---
id: 02-document
title: Regenerate documentation (roxygen2)
depends_on: [01-env-setup]
idempotent: true
---

## Objective
Regenerate `NAMESPACE` and `man/*.Rd` from roxygen blocks with zero warnings.

## Preconditions
- 01-env-setup is done (`devtools::load_all()` succeeds).
- `DESCRIPTION` contains `Roxygen: list(markdown = TRUE)` (add it if missing — this is a safe, idempotent edit).

## Steps
1. Ensure markdown roxygen is enabled:
   ```bash
   grep -q 'Roxygen: list(markdown = TRUE)' DESCRIPTION || \
     Rscript -e 'usethis::use_roxygen_md()'
   ```
2. Regenerate docs, capturing warnings as errors so nothing is silently swallowed:
   ```bash
   Rscript -e 'options(warn = 1); devtools::document(quiet = FALSE)'
   ```
3. If warnings appear (missing `@param`, mismatched usage, undocumented S3 method), fix the roxygen block at the **source** in `R/`, then re-run step 2. Do NOT hand-edit `NAMESPACE` or `man/*.Rd` — they are generated.
4. Confirm every exported function in `NAMESPACE` has a corresponding `man/*.Rd`:
   ```bash
   Rscript -e 'exp <- getNamespaceExports(devtools::as.package(".")$package); cat("exports:", length(exp), "\n")'
   ```

## Validation
- `devtools::document()` completes with **zero warnings**.
- `git status` shows `NAMESPACE` / `man/` regenerated cleanly (no leftover stale `.Rd`).

## Outputs
- Updated `NAMESPACE`, `man/*.Rd`.

## On failure
- Surface each roxygen warning with the originating `R/` file. These are nearly always fixable in-place; only escalate if a warning implies a missing dependency (then route back to 01).

## Next
- 03-test
