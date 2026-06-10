# Reference environment for golden fixtures

The fixtures in this directory are generated from the vendored reference
implementation at `.archive/SONG-master/SONG-master/song/` (`song.py`,
`util.py`) — Senanayake et al., BSD-3-Clause.

## Generators

| Script | Interpreter | Produces |
|--------|-------------|----------|
| `gen_spread.py` | miniforge **base** (numpy/scipy only) | `tierA_spread_tightness.csv`, `tierA_scalars.json` |
| `gen_fixtures.py` | conda env **`songref`** (numba/umap/sklearn) | `tierA_{A,B,sqdist,argmin}.csv`, `tierB_blobs_*.csv/.json` |

Run from the package root:

```bash
"<miniforge>/python.exe"                tests/testthat/fixtures/reference/gen_spread.py
"<miniforge>/envs/songref/python.exe"   tests/testthat/fixtures/reference/gen_fixtures.py
```

## Package versions

**`songref` env** (numba-backed kernels + end-to-end SONG):
- python 3.11.15
- numpy 2.4.6, scipy 1.17.1
- scikit-learn 1.9.0
- numba 0.65.1, llvmlite 0.47.0
- umap-learn 0.5.12, pynndescent 0.5.13

**base env** (`find_spread_tightness` / scalars only):
- numpy 2.3.5, scipy 1.17.1

## Determinism & environment caveats (Windows)

- `random_seed=1` for SONG; `np.random.seed(0)` for the Tier-A sample matrices.
- `NUMBA_NUM_THREADS=1`, `THREADING_LAYER='workqueue'`, `OMP/MKL_NUM_THREADS=1`,
  and `KMP_DUPLICATE_LIB_OK=TRUE` are set to suppress intermittent native
  (exit-127) crashes from duplicate OpenMP runtimes.
- The `songref` env's OpenBLAS/LAPACK is broken in this setup: `scipy.curve_fit`,
  `sklearn` PCA/KMeans, and `umap-learn` all abort. Workarounds used:
  - Tier-A scipy oracles are generated in the **base** env.
  - The Tier-B reference is run with `reduction=None` (LAPACK-free, raw-space
    SONG — the apples-to-apples match for songR `dispersion=FALSE`); its
    nearest-CV mapping is done directly via `get_closest_for_inputs` to avoid
    `SONG.transform()`'s dense-input `.toarray()` bug.
  - AMI is computed in **R** (`aricode`), not `sklearn`.
  - **UMAP-dispersed** reference embeddings could not be generated (umap-learn
    aborts here); the nodisp path is the rigorous SONG-fidelity comparison.
