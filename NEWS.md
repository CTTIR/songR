# songR 1.0.0

First stable release and first CRAN submission.

## Model lineage and feature contracts

* Record projection revisions, parent lineage and explicit reprojection policy
  on incremental updates. Clarify update-batch outputs and frozen prediction.
* Add an explicit optional update seed for reproducible retraining; the default
  continues to use the current random stream.
* Bind named training features and optional declared measurement metadata to
  models; prediction and updates reject incompatible feature order or
  metadata. Unnamed and legacy models retain positional compatibility.

## Performance

* Faster core training: the per-sample k-nearest-coding-vector search now
  reuses the distances already computed for the quantisation step instead of
  recomputing them and copying the active codebook on every sample. Embeddings
  are unchanged (bit-identical).
* `predict()` and the codebook-graph plotting paths (`plot()` / `autoplot()`)
  are vectorised.
* Mapping point labels to coding vectors (codebook and graph plots) and the
  centroid step after dispersion group the points in a single pass instead of
  scanning all points once per coding vector.

## Printing

* `print()` names the class in its header line (`<song_model> SONG model`), as
  the other packages of the suite do.

## Plots

* `plot()` draws a legend at the plot corner or edge where it covers the
  fewest points, in one or two columns: the levels of a categorical `color_by`
  with at most 12 levels, or a key of five evenly spaced values for a numeric
  `color_by`. Use `legend = FALSE` to omit it.
* `plot()` forwards graphical arguments such as `main`, `xlab`, `ylab`, `pch`
  and `cex` through `...`; they override the defaults of the method. These
  previously failed as duplicated arguments.
* `plot()` and `autoplot()` draw up to eight categories in the Okabe-Ito
  palette, which stays distinguishable under the common forms of colour vision
  deficiency, instead of pastel hues (`plot()`) and the default `ggplot2` hues
  (`autoplot()`). More than eight categories keep evenly spaced hues.
* `autoplot()` draws a numeric `color_by` on the viridis scale and missing
  values in grey, as `plot()` does. Adding a colour scale to the returned plot
  still replaces the scale; `ggplot2` now reports the replacement with a
  message because the plot always carries a scale.
* The edges of `plot(type = "graph")` and the eighth category colour follow the
  foreground colour of the graphics device (`par("fg")`), so they stay visible
  on a dark background, for example in the dark mode of the comparison app.
  On a white background the edges look as before.

## Comparison app

* The app loads the Bootstrap styles that its layout relies on: the settings
  and the SONG, t-SNE and UMAP panels now sit side by side instead of below
  each other, and the inputs are styled as intended.
* The comparison plots draw larger points and legend text, and in dark mode
  they leave out the dark end of the plasma scale, which was invisible on the
  dark panel.

## Bug fixes

* Validate scalar, finite hyperparameters before native training. Fractional
  integer controls, non-positive update epochs/learning rates and damaged saved
  model dimensions now fail with an R error rather than being truncated or
  passed to C++.
* Accept a single new observation in `predict()` and reject zero-column inputs.
* Keep cumulative training counts finite when updates exceed R's integer range.
* Exclude native coverage instrumentation files from source archives.
* Map codebook colours from the current update batch rather than cumulative
  training labels; handle prototypes with only missing labels. Correct the
  README to distinguish frozen projection from model retraining.
* `autoplot()` no longer errors for `type = "codebook"` or `type = "graph"`
  when `color_by` has input-point length; like `plot()`, it now maps the
  labels to coding vectors.
* The UMAP dispersion step now winsorises the embedding before building the
  UMAP init, so a single drifted coding vector can no longer dominate the
  min-max scaling and strand its points as a far outlier. This removes
  occasional outliers and improves cluster separation (e.g. Fashion-MNIST
  reproduction AMI 0.50 -> 0.55). Only the `dispersion = TRUE` path is affected;
  the core SONG embedding is unchanged.
* The UMAP dispersion now uses a stronger refinement (200 epochs, learning rate
  1.0, `min_dist = 0.1`) instead of the reference's very gentle 11-epoch step.
  songR's raw embedding is more collapsed than the reference's on hard,
  multi-class data, and the gentle step left it stranded near one axis; the
  stronger refinement makes the embedding use the full plane and, in
  benchmarks, improves AMI on every tested dataset (MNIST, Fashion-MNIST,
  COIL-20, Samusik, Wong). Only the `dispersion = TRUE` visualisation changes;
  the core SONG embedding stays frozen.
* The Shiny comparison app no longer claims SONG stops training early, and its
  documented `k` and `epochs` defaults match the implementation.
* `plot()` maps a numeric `color_by` linearly onto the sequential viridis
  palette and treats logical vectors as categories. Numeric values used to be
  passed to the graphics device as colour numbers, so negative values raised an
  error and values below 1 drew invisible points. As a consequence,
  whole-number labels supplied as numbers are now drawn on the sequential
  palette instead of the session palette; pass a factor for categorical
  colours. Missing labels are drawn in grey instead of being left out.
* With `dispersion = TRUE`, coding vectors without assigned points are placed
  inside the refined layout (at the edge-weighted mean of their occupied graph
  neighbours, or at the occupied coding vector nearest in input space) instead
  of keeping raw SONG coordinates from a different coordinate system. Codebook
  and graph plots now share the scale of the embedding and `predict()` stays
  inside the layout. `model$embedding` is unchanged; `model$Y` and the model
  identifier change for models that contain such coding vectors.
* Codebook and graph plots summarise numeric point values by their mean per
  coding vector and keep a continuous colour scale. They used to reduce numeric
  values to the most frequent one and draw it as a category.
* `autoplot()` reports a one-dimensional embedding with the same error as
  `plot()` instead of "subscript out of bounds".
* `print()` and `summary()` accept models saved before the `converged` field
  existed.
* The comparison app no longer passes a reactive as the plot background, which
  raised a warning on every render.
* The documentation of the comparison app (`run_songR_app()`, README and
  article) describes the implemented features. RDS upload, an incremental mode
  and export buttons were documented but are not part of the app; the article
  shows the equivalent code.

## Robustness

* `song()` validates `max_age` and `max_prototypes`.
* `plot()` and `autoplot()` reject a `color_by` that is a list or a data frame
  with an informative error instead of an internal sorting error.
* `song(verbose = TRUE)` reports when the dispersion step is skipped because
  'uwot' is not installed.
* Diverging training, caused by a large learning rate `alpha` or by features
  on an extreme scale, is reported by `song()` and `update()` as an error of
  class `song_error_diverged` with advice, instead of the native message
  "sort_index(): detected NaN". The error is raised when coding vectors become
  nonfinite or end more than 1000 times farther from zero than the data; such
  fits used to be returned as valid models. Values of `alpha` above 1
  overshoot and can be unstable without triggering the error, and the
  documentation of `alpha` says so.
* All user-facing messages now use `cli`, with errors signalled at the calling
  function for clearer tracebacks. Messages and behaviour are otherwise unchanged.

## Documentation

* `song()` documents every field of the model object, the effect of `seed` on
  the random number stream of the session, the memory needed for
  `max_prototypes` and how the dispersed layout is built. `update()` documents
  that it does not repeat the dispersion step.
* The `autoplot()` example now draws a plot, and `plot()` shows continuous
  colouring and the codebook graph.
* The README lists installation from GitHub and the CTTIR R-universe, its quick
  start runs as written, and the CRAN badges and the CRAN installation line
  are omitted until the package is on CRAN.
* The vignettes describe updates as continued training in which prototypes may
  move and use colour-blind-safe colours. Every figure in the vignettes and
  articles carries alternative text.
* The documentation is written in British English (`Language: en-GB`): help
  pages, README, vignettes and the entries for this version use "colour",
  "behaviour", "neighbourhood", "visualisation" and similar spellings. Function
  and argument names such as `color_by`, the labels of the Shiny app and the
  name of the Self-Organizing Nebulous Growths algorithm are unchanged.

## Verification

* Added reference-parity tests against the original Python implementation
  (`tests/testthat/test-reference-parity.R`), covering deterministic kernels
  (Tier A, &le; 1e-5) and clustering equivalence (Tier B, AMI).
* Added tests that drive the server of the comparison app and cover its
  branding helpers.

## Branding

* Show the logo in the dimension reduction and visualisation colour of the
  package family (deep teal #146554); `tools/branding/render.R` recolours the
  approved master artwork and keeps its name outlines.
* Standardise the package logo across the README, documentation pages and the
  application header, with matching light and dark artwork.

## Packaging

* Prepared for CRAN: software names quoted in `DESCRIPTION`, canonical GitHub
  URLs, unused `Matrix` suggestion removed, and the version aligned across
  `DESCRIPTION`, `inst/CITATION`, `CITATION.cff`, `.zenodo.json` and the
  README.
* The citation of the package in the README, the text version in
  `inst/CITATION`, `CITATION.cff` and `.zenodo.json` name the author as
  R. Heller.

# songR 0.1.0

## Core Features

* Core SONG algorithm implemented in C++ via RcppArmadillo.
* Incremental data visualization via `update()`.
* Projection of new points via `predict()`.
* Base R `plot()` and optional `ggplot2::autoplot()` methods.
* Supports 2D and 3D output embeddings.
* `print()` and `summary()` methods with codebook and graph statistics.

## Data and Visualization

* Bundled `songR_blobs` dataset: 8-cluster, 20D synthetic data (1600 points).
* Viridis plasma color scale used throughout vignettes and tutorials.
* All paper figures (Senanayake et al., 2021) reproducible via tutorial scripts.

## Interactive App

* Interactive Shiny app (`run_songR_app()`) for comparing SONG, t-SNE, and
  UMAP side-by-side.
* Dark mode toggle with localStorage persistence.
* Upload custom CSV/RDS data or use built-in datasets.
* Full hyperparameter control, incremental update mode, and export options.

## Vignettes and Tutorials

* Two CRAN vignettes: "Introduction to songR" and "Getting Started with songR".
* pkgdown articles: "Reproducing Paper Figures" and "Interactive Shiny App".
* 13 tutorial scripts reproducing all figures and tables from Senanayake et al.
  (2021) on MNIST, Fashion-MNIST, Wong CyTOF (1.27M cells), COIL-20, and
  Samusik datasets.
* Extra benchmarks: static AMI comparison, hyperparameter sensitivity sweeps,
  and runtime scaling analysis.
