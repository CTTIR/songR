# Fit a SONG Model for Dimensionality Reduction

Performs nonlinear dimensionality reduction using the Self-Organizing
Nebulous Growths (SONG) algorithm. SONG builds a codebook of coding
vectors connected by a topology-preserving graph, then maps the graph
into a low-dimensional embedding space. Unlike t-SNE and UMAP, the
resulting model supports incremental updates with new data via
[`update.song_model`](https://r-heller.github.io/songR/reference/update.song_model.md).

## Usage

``` r
song(
  X,
  d = 2L,
  k = 3L,
  epsilon = 0.9,
  epochs = 50L,
  alpha = 1,
  a = 1.577,
  b = 0.895,
  spread_factor = 0.5,
  neg_sample_rate = 5L,
  max_age = 3L,
  e_min = NULL,
  max_prototypes = NULL,
  lr_sigma = 5,
  dispersion = TRUE,
  seed = NULL,
  verbose = TRUE
)
```

## Arguments

- X:

  Numeric matrix of input data (`n x D`), or a data.frame with all
  numeric columns (will be coerced to matrix).

- d:

  Integer. Output dimensionality (default: 2).

- k:

  Integer. Neighborhood size for the coding-vector graph. Corresponds to
  `dim + n_neighbors` in the Python reference. Must be `>= d + 1`
  (default: 3, which matches Python's `n_neighbors = 1` with `dim = 2`).

- epsilon:

  Numeric. Edge decay rate, in `(0, 1)` (default: 0.9). Lower values
  produce sparser, faster-pruning graphs.

- epochs:

  Integer. Number of self-organisation iterations (default: 50, matching
  Python's `so_steps`).

- alpha:

  Numeric. Initial SO learning rate (default: 1.0).

- a:

  Numeric. Rational-quadratic kernel parameter (default: 1.577, from
  `find_spread_tightness(spread=1, min_dist=0.1)`).

- b:

  Numeric. Rational-quadratic kernel parameter (default: 0.895).

- spread_factor:

  Numeric. Controls growth threshold \\\theta = -\ln(D) \cdot
  \ln(\mathrm{sf})\\; higher values produce more coding vectors. In
  `(0, 1)` (default: 0.5).

- neg_sample_rate:

  Integer. Number of negative samples per positive edge during repulsion
  (default: 5).

- max_age:

  Integer. Controls automatic edge pruning: edges weaker than
  `epsilon^(d + max_age)` are removed (default: 3).

- e_min:

  Numeric or `NULL`. Minimum edge strength below which edges are pruned.
  `NULL` (default) auto-computes as `epsilon^(d + max_age)`, matching
  the Python reference.

- max_prototypes:

  Integer or `NULL`. Maximum number of coding vectors. `NULL` (default)
  auto-computes as `floor(exp(log(n) / 1.5))`, matching the Python
  reference.

- lr_sigma:

  Numeric. Decay constant for the SO learning-rate schedule:
  `so_lr = alpha * exp(-lr_sigma * (epoch/epochs)^2)`. Default: 5.0
  (matches Python).

- dispersion:

  Logical. If `TRUE` (default) and uwot is available, runs a short UMAP
  refinement step initialised from the SONG embedding. This matches the
  Python reference implementation's
  [`transform()`](https://rdrr.io/r/base/transform.html) method and
  dramatically improves visual cluster separation.

- seed:

  Integer or `NULL`. Random seed for reproducibility.

- verbose:

  Logical. Whether to print progress per epoch (default: TRUE).

## Value

An S3 object of class `"song_model"` containing:

- Y:

  Embedding coordinates of coding vectors (`n_coding x d`).

- C:

  Coding vectors (`n_coding x D`).

- E:

  Directed adjacency matrix (`n_coding x n_coding`).

- E_s:

  Symmetric adjacency matrix.

- assignments:

  Integer vector of length `n`: nearest CV index.

- embedding:

  Embedding coordinates for all input points (`n x d`).

- parameters:

  List of all hyperparameters used.

- n_epochs:

  Number of epochs actually run.

## References

Senanayake, D. A., Wang, W., Naik, S. H., & Halgamuge, S. (2021).
Self-Organizing Nebulous Growths for Robust and Incremental Data
Visualization. *IEEE Transactions on Neural Networks and Learning
Systems*, 32(10), 4588–4602.
[doi:10.1109/TNNLS.2020.3023941](https://doi.org/10.1109/TNNLS.2020.3023941)

## See also

[`update.song_model`](https://r-heller.github.io/songR/reference/update.song_model.md),
[`predict.song_model`](https://r-heller.github.io/songR/reference/predict.song_model.md),
[`plot.song_model`](https://r-heller.github.io/songR/reference/plot.song_model.md)

## Examples

``` r
model <- song(as.matrix(iris[, 1:4]), epochs = 5L, seed = 42)
#> Epoch 1/5 | CVs: 3 | QE: 1.5296 | so_lr: 1.0000 | lr: 1.0000
#> Epoch 2/5 | CVs: 5 | QE: 0.8414 | so_lr: 0.8187 | lr: 0.8000
#> Epoch 3/5 | CVs: 9 | QE: 0.5435 | so_lr: 0.4493 | lr: 0.6000
#> Epoch 4/5 | CVs: 16 | QE: 0.4550 | so_lr: 0.1653 | lr: 0.4000
#> Epoch 5/5 | CVs: 26 | QE: 0.3896 | so_lr: 0.0408 | lr: 0.2000
#> Running UMAP dispersion step...
plot(model, color_by = iris$Species)

```
