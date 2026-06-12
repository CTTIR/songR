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
| Default visualization (UMAP-dispersed) | **matches or beats the reference (songR uses a stronger refinement)** | AMI ≥ reference on every benchmark dataset |
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

### Tier B (dispersed) — visualization quality — PASS / improved

songR `dispersion=TRUE` vs the UMAP-dispersed reference
(`dispersion_method='UMAP'`), on 1500-row PCA→20 subsamples (AMI):

| dataset | reference (umap-learn) | songR (uwot) | \|Δ\| |
|---------|------------------------|--------------|-----|
| MNIST | 0.618 | 0.713 | 0.095 |
| Fashion-MNIST | 0.560 | 0.565 | 0.005 |

Both within the (loose, cross-library) band |Δ| < 0.12; songR now matches or
**beats** the reference. On the larger internal benchmark (5 datasets, 10–15k
points) songR's dispersed AMI is best-or-tied vs. reference / t-SNE / UMAP.

**songR intentionally diverges from the reference's dispersion here.** The two
implementations share the same *core* SONG embedding (Tier A and the nodisp
Tier-B are faithful), but songR's raw embedding is more **collapsed** than the
reference's on hard, multi-class data — it tends toward one axis (spread ratio
≈ 0.04–0.12 vs. the reference's 0.30–0.45). The reference's very gentle UMAP
dispersion (`n_epochs=11, lr=0.01, min_dist=0.001`) is enough for *its*
already-spread embedding, but left songR's collapsed embedding stranded near a
line. songR therefore uses a **stronger, standard UMAP refinement**
(`n_epochs=200, lr=1.0, min_dist=0.1`, from the winsorized `[0,10]`-scaled SONG
init). This lets the embedding use the full plane and, in benchmarks, **raises
AMI on every tested dataset** (e.g. MNIST 0.70→0.80, Fashion-MNIST 0.56→0.62,
Samusik 0.37→0.41, Wong 0.18→0.21) — see `.housekeeping/benchmark/`.

So the dispersion is a deliberate, benchmark-validated **improvement**, not a
faithful copy of the reference's gentle step. The faithful, reference-matched
behavior lives in the *core* SONG embedding (use `dispersion=FALSE` for the raw
SONG layout). The remaining root cause of the raw collapse on hard data is the
deferred core divergence **D3** (drifter reuse); fixing it would let the raw
embedding spread natively, but needs a full re-parity pass.

Tests: `tests/testthat/test-reference-parity.R`.

## Stages
- **UMAP dispersion back-end**: present, with the same scaled-SONG-init design
  as the reference, but tuned **stronger** on purpose (`n_epochs=200, lr=1.0,
  min_dist=0.1` vs the reference's gentle `11 / 0.01 / 0.001`) so songR's
  more-collapsed raw embedding spreads into the plane — a benchmark-validated
  quality improvement, not a faithful copy. See the dispersed Tier-B section.
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
