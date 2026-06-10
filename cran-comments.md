## R CMD check results

0 errors | 0 warnings | 0 notes

On some offline/sandboxed local runs an additional NOTE may appear,
"checking for future file timestamps ... unable to verify current time".
This is environment-only (the check cannot reach the time-verification
service) and does not occur on CRAN or CI with network access.

## Test environments

- local Windows 11 x64, R 4.5.2
- GitHub Actions (ubuntu-latest, macOS-latest, windows-latest)

## Downstream dependencies

This is a new package with no downstream dependencies.
