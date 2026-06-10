# Changelog

## songR (development version)

### Performance

- Faster core training: the per-sample k-nearest-coding-vector search
  now reuses the distances already computed for the quantization step
  instead of recomputing them and copying the active codebook on every
  sample. Embeddings are unchanged (bit-identical).
- [`predict()`](https://rdrr.io/r/stats/predict.html) and the
  codebook-graph plotting paths
  ([`plot()`](https://rdrr.io/r/graphics/plot.default.html) /
  `autoplot()`) are vectorized.

### Bug fixes

- `autoplot()` no longer errors for `type = "codebook"` or
  `type = "graph"` when `color_by` has input-point length; like
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html), it now maps
  the labels to coding vectors.
- The Shiny comparison app no longer claims SONG stops training early,
  and its documented `k` and `epochs` defaults match the implementation.

### Robustness

- [`song()`](https://cttir.github.io/songR/reference/song.md) validates
  `max_age` and `max_prototypes`.

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
