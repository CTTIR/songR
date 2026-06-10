# Reference environment for golden fixtures

The fixtures in this directory are generated from the vendored reference
implementation at `.archive/SONG-master/SONG-master/song/` (`song.py`,
`util.py`) — Senanayake et al., BSD-3-Clause.

## Single pinned environment

All fixtures are generated from **one** conda env, `songref`, pinned in
[`data-raw/reproduction/environment.yml`](../../../../data-raw/reproduction/environment.yml).

```bash
conda env create -f data-raw/reproduction/environment.yml      # or: conda env update
"<miniforge>/envs/songref/python.exe" tests/testthat/fixtures/reference/smoke_test.py    # must print SMOKE_OK
"<miniforge>/envs/songref/python.exe" tests/testthat/fixtures/reference/gen_fixtures.py  # regenerates every fixture
```

Key versions: python 3.11, numpy 2.4.6, scipy 1.17.1, scikit-learn 1.9.0,
numba 0.65.1, llvmlite 0.47.0, umap-learn 0.5.12, pynndescent 0.5.13, all on
**OpenBLAS** (`libopenblas 0.3.33`, `libblas/liblapack 3.11.0 *_openblas`).

## BLAS root cause and fix

The first build of `songref` aborted (`exit 127`, no traceback) on every
LAPACK call — `scipy.optimize.curve_fit`, `sklearn` PCA/KMeans, and
`umap-learn`. Root cause: a **mixed BLAS** env — `numpy`/`scikit-learn`/`numba`
were conda-forge builds linked against **MKL** (`libblas 3.11.0 *_mkl`,
`mkl 2026.0.0`), while `scipy` was a **pip** wheel bundling its own **OpenBLAS**.
Two BLAS runtimes (MKL + OpenBLAS) loaded into one process abort on the first
LAPACK entry.

Fix: recreate the env from conda-forge only with the BLAS variant pinned to
OpenBLAS (`libblas=*=*openblas`), so numpy/scipy/scikit-learn all resolve to a
single OpenBLAS. The `smoke_test.py` gate (curve_fit + PCA + KMeans + UMAP)
must pass before generating fixtures.

## Determinism

- `random_seed=1` for SONG; `np.random.seed(0)` for the Tier-A sample matrices.
- `NUMBA_NUM_THREADS=1`, `THREADING_LAYER='workqueue'`, `OMP/MKL_NUM_THREADS=1`,
  `KMP_DUPLICATE_LIB_OK=TRUE` to keep the numba paths deterministic and suppress
  any residual duplicate-OpenMP aborts on Windows.

## What each fixture is

- `tierA_*` — `find_spread_tightness` (scipy), the `thresh_g/prototypes/...`
  scalars, and the numba `sq_eucl_opt` / `get_closest` kernels.
- `tierB_blobs_*` — raw-space SONG (`reduction=None`, no UMAP) on an 800×20
  blobs set; the apples-to-apples match for songR `dispersion=FALSE`. Nearest-CV
  mapping is done directly via `get_closest_for_inputs` to avoid
  `SONG.transform()`'s dense-input `.toarray()` bug.
- `tierB_{mnist,fmnist}_*` — UMAP-dispersed reference embeddings
  (`dispersion_method='UMAP'`, `um_epochs=11, um_lr=0.01, um_min_dist=0.001`) on
  1500-row PCA→20 subsamples (exported from R). AMI is computed in R (`aricode`)
  for both reference and songR so the metric is identical on both sides.
