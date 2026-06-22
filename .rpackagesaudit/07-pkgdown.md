---
id: 07-pkgdown
title: Build pkgdown site
depends_on: [04-cran-check]
idempotent: true
---

## Objective
Build the pkgdown documentation site cleanly, with logo wired in and every exported function in the reference index.

## Preconditions
- 04-cran-check is done (docs/examples are valid).
- `_pkgdown.yml` exists or will be scaffolded.

## Steps
1. Scaffold config if missing: `test -f _pkgdown.yml || Rscript -e 'usethis::use_pkgdown()'`.
2. Ensure `_pkgdown.yml` has `url:` set to the GitHub Pages URL (`https://<org-as-user>.github.io/<repo>/`), a `template:` section, a `reference:` section grouping functions by category, and an `articles:` section listing vignettes.
3. **Logo.** If a `*.svg` exists at repo root: copy (do not move) to `man/figures/logo.svg`; convert to `man/figures/logo.png` (height ~240px, transparent) trying in order `rsvg-convert`, `cairosvg`, `inkscape --export-type=png`, then `magick::image_read_svg()` in R; wire `<img src="man/figures/logo.png" align="right" height="139" alt="PKGNAME logo" />` into README; add the root SVG to `.Rbuildignore` (`^.*\.svg$`). If no converter is available, keep the SVG and note it.
4. Build the site:
   ```bash
   Rscript -e 'pkgdown::build_site(preview = FALSE)'
   ```
5. Verify no exported function is missing from the reference index:
   ```bash
   Rscript -e 'pkgdown::check_pkgdown()'
   ```
6. Ensure `docs/` is git-ignored and build-ignored (the gh-pages deploy in 08 builds it in CI, not from a committed `docs/`).

## Validation
- `pkgdown::build_site()` completes without error.
- `pkgdown::check_pkgdown()` reports all topics covered (no orphaned exports).
- Logo renders in the built `docs/index.html` header.

## Outputs
- Built `docs/` (local preview), `_pkgdown.yml`, `man/figures/logo.*`.

## On failure
- If `check_pkgdown()` lists missing topics, add them to the `reference:` section and rebuild.
- If a vignette fails to knit during site build, that is the same root cause 04 would catch — route the fix back through 02/04.

## Next
- orchestrator decides
