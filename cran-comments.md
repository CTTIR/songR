## Submission

This is a new submission (songR 1.0.0).

## Test environments

- local macOS (aarch64-apple-darwin), R 4.6.1:
  `R CMD check --as-cran --no-manual` on the built tarball. The PDF manual
  was built locally with TinyTeX (TeX Live 2026) via `R CMD Rd2pdf` without
  errors; the check run itself used `--no-manual`.
- GitHub Actions (r-lib/actions v2, `--as-cran`):
  - macos-latest (R release)
  - windows-latest (R release)
  - ubuntu-latest (R devel, release, oldrel-1)

## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE
  Maintainer: 'R. Heller <raban.heller@uni-ulm.de>'
  New submission

  This is the first submission of this package.

## Additional notes

* The package contains C++ code (via 'Rcpp' and 'RcppArmadillo') that
  re-implements the SONG algorithm of Senanayake et al. (2021). The original
  algorithm author is listed with role "cph"; the upstream BSD-3-Clause
  notice is reproduced in `inst/COPYRIGHTS`.
* Examples, tests and vignettes use small data and run single-threaded.
  Reference-parity tests against larger fixtures are skipped on CRAN.
* The interactive 'shiny' application is only launched inside
  `if (interactive())`.

## Downstream dependencies

There are currently no downstream dependencies for this package.
