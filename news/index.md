# Changelog

## songR 1.0.0

First stable release and first CRAN submission.

### Model lineage and feature contracts

- Record projection revisions, parent lineage and explicit reprojection
  policy on incremental updates. Clarify update-batch outputs and frozen
  prediction.
- Add an explicit optional update seed for reproducible retraining; the
  default continues to use the current random stream.
- Bind named training features and optional declared measurement
  metadata to models; prediction and updates reject incompatible feature
  order or metadata. Unnamed and legacy models retain positional
  compatibility.

### Performance

- Faster core training: the per-sample k-nearest-coding-vector search
  now reuses the distances already computed for the quantization step
  instead of recomputing them and copying the active codebook on every
  sample. Embeddings are unchanged (bit-identical).
- [`predict()`](https://rdrr.io/r/stats/predict.html) and the
  codebook-graph plotting paths
  ([`plot()`](https://rdrr.io/r/graphics/plot.default.html) /
  `autoplot()`) are vectorized.
- Mapping point labels to coding vectors (codebook and graph plots) and
  the centroid step after dispersion group the points in a single pass
  instead of scanning all points once per coding vector.

### Printing

- [`print()`](https://rdrr.io/r/base/print.html) names the class in its
  header line (`<song_model> SONG model`), as the other packages of the
  suite do.

### Plots

- [`plot()`](https://rdrr.io/r/graphics/plot.default.html) draws a
  legend at the plot corner or edge where it covers the fewest points,
  in one or two columns: the levels of a categorical `color_by` with at
  most 12 levels, or a key of five evenly spaced values for a numeric
  `color_by`. Use `legend = FALSE` to omit it.
- [`plot()`](https://rdrr.io/r/graphics/plot.default.html) forwards
  graphical arguments such as `main`, `xlab`, `ylab`, `pch` and `cex`
  through `...`; they override the defaults of the method. These
  previously failed as duplicated arguments.
- [`plot()`](https://rdrr.io/r/graphics/plot.default.html) and
  `autoplot()` draw up to eight categories in the Okabe-Ito palette,
  which stays distinguishable under the common forms of color vision
  deficiency, instead of pastel hues
  ([`plot()`](https://rdrr.io/r/graphics/plot.default.html)) and the
  default `ggplot2` hues (`autoplot()`). More than eight categories keep
  evenly spaced hues.
- `autoplot()` draws a numeric `color_by` on the viridis scale and
  missing values in gray, as
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) does. Adding
  a color scale to the returned plot still replaces the scale; `ggplot2`
  now reports the replacement with a message because the plot always
  carries a scale.
- The edges of `plot(type = "graph")` and the eighth category color
  follow the foreground color of the graphics device (`par("fg")`), so
  they stay visible on a dark background, for example in the dark mode
  of the comparison app. On a white background the edges look as before.

### Comparison app

- The app loads the Bootstrap styles that its layout relies on: the
  settings and the SONG, t-SNE and UMAP panels now sit side by side
  instead of below each other, and the inputs are styled as intended.
- The comparison plots draw larger points and legend text, and in dark
  mode they leave out the dark end of the plasma scale, which was
  invisible on the dark panel.

### Bug fixes

- Validate scalar, finite hyperparameters before native training.
  Fractional integer controls, non-positive update epochs/learning rates
  and damaged saved model dimensions now fail with an R error rather
  than being truncated or passed to C++.
- Accept a single new observation in
  [`predict()`](https://rdrr.io/r/stats/predict.html) and reject
  zero-column inputs.
- Keep cumulative training counts finite when updates exceed R’s integer
  range.
- Exclude native coverage instrumentation files from source archives.
- Map codebook colors from the current update batch rather than
  cumulative training labels; handle prototypes with only missing
  labels. Correct the README to distinguish frozen projection from model
  retraining.
- `autoplot()` no longer errors for `type = "codebook"` or
  `type = "graph"` when `color_by` has input-point length; like
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html), it now maps
  the labels to coding vectors.
- The UMAP dispersion step now winsorizes the embedding before building
  the UMAP init, so a single drifted coding vector can no longer
  dominate the min-max scaling and strand its points as a far outlier.
  This removes occasional outliers and improves cluster separation
  (e.g. Fashion-MNIST reproduction AMI 0.50 -\> 0.55). Only the
  `dispersion = TRUE` path is affected; the core SONG embedding is
  unchanged.
- The UMAP dispersion now uses a stronger refinement (200 epochs,
  learning rate 1.0, `min_dist = 0.1`) instead of the reference’s very
  gentle 11-epoch step. songR’s raw embedding is more collapsed than the
  reference’s on hard, multi-class data, and the gentle step left it
  stranded near one axis; the stronger refinement makes the embedding
  use the full plane and, in benchmarks, improves AMI on every tested
  dataset (MNIST, Fashion-MNIST, COIL-20, Samusik, Wong). Only the
  `dispersion = TRUE` visualization changes; the core SONG embedding
  stays frozen.
- The Shiny comparison app no longer claims SONG stops training early,
  and its documented `k` and `epochs` defaults match the implementation.
- [`plot()`](https://rdrr.io/r/graphics/plot.default.html) maps a
  numeric `color_by` linearly onto the sequential viridis palette and
  treats logical vectors as categories. Numeric values used to be passed
  to the graphics device as color numbers, so negative values raised an
  error and values below 1 drew invisible points. As a consequence,
  whole-number labels supplied as numbers are now drawn on the
  sequential palette instead of the session palette; pass a factor for
  categorical colors. Missing labels are drawn in gray instead of being
  left out.
- With `dispersion = TRUE`, coding vectors without assigned points are
  placed inside the refined layout (at the edge-weighted mean of their
  occupied graph neighbors, or at the occupied coding vector nearest in
  input space) instead of keeping raw SONG coordinates from a different
  coordinate system. Codebook and graph plots now share the scale of the
  embedding and [`predict()`](https://rdrr.io/r/stats/predict.html)
  stays inside the layout. `model$embedding` is unchanged; `model$Y` and
  the model identifier change for models that contain such coding
  vectors.
- Codebook and graph plots summarize numeric point values by their mean
  per coding vector and keep a continuous color scale. They used to
  reduce numeric values to the most frequent one and draw it as a
  category.
- `autoplot()` reports a one-dimensional embedding with the same error
  as [`plot()`](https://rdrr.io/r/graphics/plot.default.html) instead of
  “subscript out of bounds”.
- [`print()`](https://rdrr.io/r/base/print.html) and
  [`summary()`](https://rdrr.io/r/base/summary.html) accept models saved
  before the `converged` field existed.
- The comparison app no longer passes a reactive as the plot background,
  which raised a warning on every render.
- The documentation of the comparison app
  ([`run_songR_app()`](https://cttir.github.io/songR/reference/run_songR_app.md),
  README and article) describes the implemented features. RDS upload, an
  incremental mode and export buttons were documented but are not part
  of the app; the article shows the equivalent code.

### Robustness

- [`song()`](https://cttir.github.io/songR/reference/song.md) validates
  `max_age` and `max_prototypes`.
- [`plot()`](https://rdrr.io/r/graphics/plot.default.html) and
  `autoplot()` reject a `color_by` that is a list or a data frame with
  an informative error instead of an internal sorting error.
- `song(verbose = TRUE)` reports when the dispersion step is skipped
  because ‘uwot’ is not installed.
- Diverging training, caused by a large learning rate `alpha` or by
  features on an extreme scale, is reported by
  [`song()`](https://cttir.github.io/songR/reference/song.md) and
  [`update()`](https://rdrr.io/r/stats/update.html) as an error of class
  `song_error_diverged` with advice, instead of the native message
  “sort_index(): detected NaN”. The error is raised when coding vectors
  become nonfinite or end more than 1000 times farther from zero than
  the data; such fits used to be returned as valid models. Values of
  `alpha` above 1 overshoot and can be unstable without triggering the
  error, and the documentation of `alpha` says so.
- All user-facing messages now use `cli`, with errors signaled at the
  calling function for clearer tracebacks. Messages and behavior are
  otherwise unchanged.

### Documentation

- [`song()`](https://cttir.github.io/songR/reference/song.md) documents
  every field of the model object, the effect of `seed` on the random
  number stream of the session, the memory needed for `max_prototypes`
  and how the dispersed layout is built.
  [`update()`](https://rdrr.io/r/stats/update.html) documents that it
  does not repeat the dispersion step.
- The `autoplot()` example now draws a plot, and
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) shows
  continuous coloring and the codebook graph.
- The README lists installation from GitHub and the CTTIR R-universe,
  its quick start runs as written, and the CRAN badges and the CRAN
  installation line are omitted until the package is on CRAN.
- The vignettes describe updates as continued training in which
  prototypes may move and use color-blind-safe colors. Every figure in
  the vignettes and articles carries alternative text.

### Verification

- Added reference-parity tests against the original Python
  implementation (`tests/testthat/test-reference-parity.R`), covering
  deterministic kernels (Tier A, ≤ 1e-5) and clustering equivalence
  (Tier B, AMI).
- Added tests that drive the server of the comparison app and cover its
  branding helpers.

### Branding

- Show the logo in the dimension reduction and visualization color of
  the package family (deep teal
  [\#146554](https://github.com/CTTIR/songR/issues/146554));
  `tools/branding/render.R` recolors the approved master artwork and
  keeps its name outlines.
- Standardize the package logo across the README, documentation pages
  and the application header, with matching light and dark artwork.

### Packaging

- Prepared for CRAN: software names quoted in `DESCRIPTION`, canonical
  GitHub URLs, unused `Matrix` suggestion removed, and the version
  aligned across `DESCRIPTION`, `inst/CITATION`, `CITATION.cff`,
  `.zenodo.json` and the README.

## songR 0.1.0

### Core Features

- Core SONG algorithm implemented in C++ via RcppArmadillo.
- Incremental data visualization via
  [`update()`](https://rdrr.io/r/stats/update.html).
- Projection of new points via
  [`predict()`](https://rdrr.io/r/stats/predict.html).
- Base R [`plot()`](https://rdrr.io/r/graphics/plot.default.html) and
  optional
  [`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  methods.
- Supports 2D and 3D output embeddings.
- [`print()`](https://rdrr.io/r/base/print.html) and
  [`summary()`](https://rdrr.io/r/base/summary.html) methods with
  codebook and graph statistics.

### Data and Visualization

- Bundled `songR_blobs` dataset: 8-cluster, 20D synthetic data (1600
  points).
- Viridis plasma color scale used throughout vignettes and tutorials.
- All paper figures (Senanayake et al., 2021) reproducible via tutorial
  scripts.

### Interactive App

- Interactive Shiny app
  ([`run_songR_app()`](https://cttir.github.io/songR/reference/run_songR_app.md))
  for comparing SONG, t-SNE, and UMAP side-by-side.
- Dark mode toggle with localStorage persistence.
- Upload custom CSV/RDS data or use built-in datasets.
- Full hyperparameter control, incremental update mode, and export
  options.

### Vignettes and Tutorials

- Two CRAN vignettes: “Introduction to songR” and “Getting Started with
  songR”.
- pkgdown articles: “Reproducing Paper Figures” and “Interactive Shiny
  App”.
- 13 tutorial scripts reproducing all figures and tables from Senanayake
  et al.
  2021. on MNIST, Fashion-MNIST, Wong CyTOF (1.27M cells), COIL-20, and
        Samusik datasets.
- Extra benchmarks: static AMI comparison, hyperparameter sensitivity
  sweeps, and runtime scaling analysis.
