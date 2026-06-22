---
id: 09-release-prep
title: Release preparation (NEWS, cran-comments, spell, size gate)
depends_on: [04-cran-check, 05-tidyverse-align, 06-codecov, 07-pkgdown, 08-ci]
idempotent: true
---

## Objective
Finalize release artifacts and pass the final gates: NEWS, cran-comments, spell check, and tarball size < 5 MB.

## Preconditions
- All upstream processes (04–08) are done.
- Package is CRAN-clean from 04 and unchanged by 05/06 re-checks.

## Steps
1. **NEWS.md.** Ensure an entry exists for the current `VERSION`. For a first release, list each exported function with a one-line description, grouped by category. Create with `usethis::use_news_md()` if missing.
2. **cran-comments.md.** Create/update with the final check result, test environments (local + GitHub Actions OSes), and "This is a new submission." for a first release. Ensure it is build-ignored (`^cran-comments\.md$`).
3. **Spell check.** `Rscript -e 'spelling::spell_check_package()'`. Fix genuine typos in roxygen/vignettes/README/DESCRIPTION; add valid domain terms to `inst/WORDLIST` (one per line, sorted). Re-run until only intended terms remain.
4. **`.Rbuildignore` sweep.** Confirm dev-only files are excluded: `^_build\.R$`, `^\.claude$`, `^CLAUDE.*\.md$`, `^README\.Rmd$`, `^cran-comments\.md$`, `^_pkgdown\.ya?ml$`, `^docs$`, `^pkgdown$`, `^\.github$`, `^codecov\.yml$`, `^.*\.svg$`, `^\.archive$`, `^LICENSE\.md$`. Add any missing.
5. **Build & size gate:**
   ```bash
   Rscript -e 'p <- devtools::build(); sz <- file.info(p)$size/1e6; cat(sprintf("TARBALL=%s SIZE=%.2fMB\n", basename(p), sz)); if (sz >= 5) quit(status = 1)'
   ```
   If ≥ 5 MB: shrink `inst/extdata/`, `tools::resaveRdaFiles("data", compress="xz")`, remove stray binaries; rebuild.
6. **Final check on the built tarball:** re-run 04's check command one last time; confirm `0 errors | 0 warnings`. Update `cran-comments.md` with the exact result line.

## Validation
- `NEWS.md` has a current-version entry; `cran-comments.md` reflects the final check.
- `spelling::spell_check_package()` returns only intended/WORDLIST terms.
- Tarball builds at < 5 MB; final check is `0 errors | 0 warnings | N notes` (N = New submission only, if any).
- Record `TARBALL`, `SIZE`, and final result in `STATE.md`.

## Outputs
- `NEWS.md`, `cran-comments.md`, `inst/WORDLIST`, the built `*.tar.gz`.

## On failure
- If the size gate cannot be met without removing functionally-required data, surface the largest offenders (`du -ah inst | sort -rh | head`) and ask the user how to proceed.

## Next
- orchestrator decides (all done → stop)
