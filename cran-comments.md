## Submission

This is a new submission (songR 1.0.0).

## Test environments

- local macOS (aarch64-apple-darwin), R 4.6.1:
  `R CMD check --as-cran` on the built tarball on 14 November 2026, with all
  suggested packages available. PDF and HTML manuals, examples and rebuilt
  vignettes passed; TinyTeX and HTML Tidy 5.8.0 were used.
- GitHub Actions baseline (public commit `79762a4`, r-lib/actions v2,
  `--as-cran`):
  - macos-latest (R release)
  - windows-latest (R release)
  - ubuntu-latest (R devel, release, oldrel-1)

Hosted checks on the maintenance candidate must be verified after publication;
the baseline platform results do not qualify the changed source.

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
* The complete non-CRAN test run measured 93.42% coverage. The hosted
  regression floor is 90%; the reference-parity tests also run in that lane.

## Downstream dependencies

The CRAN source index checked on 14 November 2026 contained no songR release
and no reverse dependencies. Development consumers in the phenoloom suite are
qualified separately through their integration checks.
