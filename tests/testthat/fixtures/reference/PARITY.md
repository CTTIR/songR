# Reference-parity audit summary

songR audited against the vendored reference (`.archive/SONG-master`,
Senanayake et al.). Parity is judged on a fidelity ladder, not bit-identity
(the reference is float32 + numba `fastmath` + dual PRNG streams).

## How faithfully does songR reproduce the Python reference?

Layer by layer, against the same inputs (see
`data-raw/reproduction/repro_procrustes.R`):

| Layer | Reproduction | Evidence |
|-------|--------------|----------|
| Deterministic kernels (distances, argmin, `(a, b)`, scalars) | **near bit-identical** | &le; 7.6e-08 / exact (float32-vs-double floor) |
| Clustering (AMI) | **statistically identical** | nodisp 0.949 = 0.949 |
| Default visualization (UMAP-dispersed) | **close in global structure, not identical in absolute layout** | Procrustes R&sup2; &asymp; 0.79–0.85 |
| Raw embedding coordinates (pre-dispersion) | **same structure, different layout** | blobs Procrustes R&sup2; &asymp; 0.22 |

![Reference vs songR overlay](../../../vignettes/articles/reference_parity_overlay.png)

**Why bit-identity of the embeddings is impossible — and not the goal.**
The reference computes in `float32` with numba `fastmath` (which licenses
non-IEEE reassociation/FMA) and draws randomness from **two** independent PRNG
streams (numpy MT19937 for initialization/permutations and a custom XORShift
for negative sampling). songR is `double`-precision with R's RNG, and carries
three deliberate, documented divergences (D1 online vs chunk-stale distances,
D3 drifter-slot reuse, D4 coincident-vector guard; see below). The embedding is
a stochastic SGD result, so two faithful implementations land on the *same
manifold structure* in *different absolute coordinates*. Accordingly, songR
claims near-bit-identity only for the **deterministic** layer; the embeddings
reproduce the reference's structure and clustering, not its exact coordinates.

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

### Tier B (dispersed) — end-to-end pipeline (uwot ↔ umap-learn) — PASS
UMAP-dispersed reference (`dispersion_method='UMAP'`, `um_epochs=11, um_lr=0.01,
um_min_dist=0.001`) vs songR `dispersion=TRUE`, on 1500-row PCA→20 subsamples:

| dataset | reference (umap-learn) | songR (uwot) | \|Δ\| |
|---------|------------------------|--------------|-----|
| MNIST | 0.618 | 0.596 | 0.022 |
| Fashion-MNIST | 0.560 | 0.551 | 0.009 |

This is a **pipeline** check, not a SONG-numerics check: it crosses two
different UMAP libraries (different SGD/RNG/NN), so the band (|Δ| < 0.12) is
deliberately looser than the nodisp test.

**Dispersion parameter parity.** Every argument of songR's `uwot::umap` call
matches the reference `umap.UMAP` call (`song.py:334`) and umap-learn's
defaults — verified, not assumed:

| Parameter | Reference (umap-learn) | songR (uwot) | Match |
|-----------|------------------------|--------------|-------|
| `n_components` | 2 | 2 | ✓ |
| `n_epochs` | 11 | 11 (honored: "optimization for 11 epochs") | ✓ |
| `learning_rate` | 0.01 (`um_lr`) | 0.01 | ✓ |
| `min_dist` | 0.001 (`um_min_dist`) | 0.001 | ✓ |
| effective `a`, `b` | 1.929073, 0.791505 (fit for min_dist=0.001) | 1.929073, 0.791505 (uwot fits identically) | ✓ |
| `init` | `[0,10]`-scaled SONG embedding | same (`init_sdev = NULL`, no rescale) | ✓ |
| `n_neighbors` | 15 (default) | 15 (default) | ✓ |
| `negative_sample_rate` | 5 | 5 | ✓ |
| `set_op_mix_ratio` | 1.0 | 1.0 | ✓ |
| `local_connectivity` | 1.0 | 1.0 | ✓ |
| `repulsion_strength` | 1.0 | 1.0 | ✓ |
| `metric` | euclidean | euclidean | ✓ |
| SGD determinism | seeded | `n_sgd_threads = 1` (reproducible) | ✓ |

There is **no wiring mismatch**. The only songR-specific deviation is the
*winsorized* init (clip to the 2nd–98th percentile before the `[0,10]`
scaling): songR's pre-dispersion embedding carries a drifter coding vector
(the reference recycles drifters — divergence D3 — so its embedding has none),
and a plain min-max scaling would let that single outlier dominate the init.

The residual layout difference (Procrustes R² ≈ 0.79 FMNIST, 0.85 MNIST) has
**two components**:

1. **Irreducible — cross-library SGD/RNG.** uwot and umap-learn implement the
   same objective with different stochastic optimizers and random streams;
   their outputs cannot coincide coordinate-for-coordinate.
2. **Reducible but deferred — D3 (drifter reuse) in the frozen core.** With
   `lr = 0.01` and 11 epochs, UMAP barely moves from its init, so each
   library's output mirrors its own pre-dispersion SONG embedding — and
   songR's differs from the reference's by the documented divergence D3
   (ΔAMI = 0.000). Implementing drifter reuse would require a core change and
   full re-parity, and is deferred; see "Intentional divergences" below.

Raising the epoch count makes FMNIST's layout match more closely but MNIST's
*less* closely (and diverges from the reference's `um_epochs = 11`), so it is
not a fix. AMI parity remains the quantitative fidelity measure; the layout
figure is illustrative.

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
  Effect: small coding-vector-count difference (93 vs 86), **ΔAMI = 0.000**.
  *Tracked as a possible future enhancement:* implementing drifter reuse is
  the honest path to a natively reference-matching pre-dispersion embedding
  (and hence dispersed layout), but it changes the frozen core and therefore
  requires a full re-parity pass. Deferred by the current positioning contract
  (songR is a SONG-inspired tool, statistically equivalent, not a bit-faithful
  port).
- **D4 — coincident-vector guard.** songR clamps `ldist_sq ≥ 1e-10` before the
  rational-quadratic kernel; the reference does not, so `pow(0, β−1)=∞` is
  reachable at coincident/self vectors. songR's guard is strictly more robust.

These are the reasons exact bitwise reproduction is neither targeted nor
achievable; the algorithm is faithful at Tier A/B.
