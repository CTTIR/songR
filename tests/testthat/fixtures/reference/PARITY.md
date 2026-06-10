# Reference-parity audit summary

songR audited against the vendored reference (`.archive/SONG-master`,
Senanayake et al.). Parity is judged on a fidelity ladder, not bit-identity
(the reference is float32 + numba `fastmath` + dual PRNG streams).

## Results

### Tier A — deterministic (target ≤ 1e-5) — PASS
| Component | Result |
|-----------|--------|
| `sq_eucl_opt` distance matrix | max abs err 7.6e-08 (float32 vs double) |
| nearest-coding-vector `argmin` | identical |
| `find_spread_tightness(1, 0.1)` → `(a, b)` | rel err a 3.6e-5, b 6.8e-5 (songR ships rounded 1.577 / 0.895) |
| `thresh_g`, `prototypes`, `min_strength`, `im_neix` | exact |

### Tier B — statistical equivalence — PASS
Shared 800×20 blobs, raw-space SONG (no UMAP), reference-matched params
(`epsilon=0.99, k=3, epochs=100, a=1.577, b=0.895, seed=1`):

| | reference (nodisp) | songR (`dispersion=FALSE`) |
|--|--------------------|----------------------------|
| AMI (k-means, 5 seeds) | 0.949 | 0.949 |
| coding vectors | 93 | 86 |

Tests: `tests/testthat/test-reference-parity.R`.

## Stages
- **UMAP dispersion back-end**: present and faithful in songR (matches the
  reference's scaled-init UMAP, `n_epochs=11, lr=0.01, min_dist=0.001`).
- **PCA front-end**: absent from songR. Negligible — the reference only uses
  PCA for distances when `D > 100`, and for `D ≤ 100` it is an orthonormal,
  distance-preserving rotation. Confirmed empirically: COIL-20 (`D=300`, where
  it would engage) still scores AMI 0.92 in songR.

## Intentional divergences (documented, NOT bugs)

- **D1 — online vs chunk-batched distances.** The reference precomputes the
  distance matrix once per `chunk_size`-sample chunk and then updates `W`
  sample-by-sample, so later samples in a chunk use *stale* distances. songR
  recomputes distances fresh for every sample (online). Measured effect on the
  Tier-B blobs: **none** (ΔAMI 0.000). songR keeps the online semantics as a
  cleaner, equivalent choice.
- **D3 — no drifter-slot reuse; `E_q` not zeroed after fit.** The reference
  recycles disconnected ("drifter") node slots and resets `E_q` at the end of
  `fit`. songR appends new coding vectors and carries `E_q` into `update()`.
  Effect: small coding-vector-count difference (93 vs 86), no AMI effect.
- **D4 — coincident-vector guard.** songR clamps `ldist_sq ≥ 1e-10` before the
  rational-quadratic kernel; the reference does not, so `pow(0, β−1)=∞` is
  reachable at coincident/self vectors. songR's guard is strictly more robust.

These are the reasons exact bitwise reproduction is neither targeted nor
achievable; the algorithm is faithful at Tier A/B.
