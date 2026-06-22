---
id: 01-env-setup
title: Environment setup & package identity
depends_on: []
idempotent: true
---

## Objective
Detect the package identity from DESCRIPTION and git, install development dependencies, and confirm the package loads.

## Preconditions
- Current working directory is the root of an R package (a `DESCRIPTION` file exists).
- `R`, `Rscript`, and `git` are on PATH.
- Internet access is available for dependency installation (or a populated `renv`/library already exists).

## Steps
1. Confirm you are at a package root: `test -f DESCRIPTION || { echo "No DESCRIPTION at $(pwd) — not a package root"; exit 1; }`.
2. Derive identity (never hardcode — read at runtime):
   ```bash
   Rscript -e 'd <- read.dcf("DESCRIPTION"); cat(
     "PKG=", d[,"Package"], "\n",
     "VERSION=", d[,"Version"], "\n",
     "LICENSE=", d[,"License"], "\n",
     "URL=", if ("URL" %in% colnames(d)) d[,"URL"] else "<none>", "\n",
     "BIOC=", if ("biocViews" %in% colnames(d)) "yes" else "no", "\n", sep="")'
   git rev-parse --abbrev-ref HEAD
   ```
   Record `PKGNAME`, `VERSION`, `LICENSE`, `<org>/<repo>` (parsed from URL), default `<branch>`, and whether this is a Bioconductor target. Write these to `.claude/workflows/STATE.md` under an `## Identity` section if not already present.
3. If `_build.R` exists, note it as the canonical build script for later steps. Do not run it yet.
4. Install dev tooling and package dependencies:
   ```bash
   Rscript -e 'if (!requireNamespace("pak", quietly=TRUE)) install.packages("pak", repos="https://cloud.r-project.org")'
   Rscript -e 'pak::pak(c("devtools","roxygen2","testthat","pkgdown","covr","withr","cli","rlang","lifecycle","spelling"))'
   Rscript -e 'pak::local_install_deps(dependencies = TRUE)'
   ```
   If `pak` is unavailable, fall back to `devtools::install_dev_deps(".")`.
5. Smoke-load the package: `Rscript -e 'devtools::load_all(".", quiet = TRUE); cat("load_all OK\n")'`.

## Validation
- `devtools::load_all(".")` returns without error (`load_all OK` printed).
- `PKGNAME` and default `<branch>` are recorded in `STATE.md`.

## Outputs
- Installed dependency library.
- `## Identity` block in `.claude/workflows/STATE.md`.

## On failure
- If a dependency fails to install, surface the exact failing package and its system-dependency error (e.g. missing `libxml2`, `libcurl`). Do NOT proceed; report to the user — this usually needs a system package install outside R.
- If `load_all` fails on a syntax/parse error, report the file and line; this blocks every downstream step.

## Next
- 02-document
