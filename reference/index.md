# Package index

## Core Functions

Fit a SONG model, incrementally update it with new data, and project
unseen points into the learned embedding space.

- [`song()`](https://r-heller.github.io/songR/reference/song.md) : Fit a
  SONG Model for Dimensionality Reduction
- [`update(`*`<song_model>`*`)`](https://r-heller.github.io/songR/reference/update.song_model.md)
  : Incrementally Update a SONG Model with New Data
- [`predict(`*`<song_model>`*`)`](https://r-heller.github.io/songR/reference/predict.song_model.md)
  : Project New Points into a SONG Embedding

## Visualization

Plot SONG embeddings, codebook prototypes, and the learned topology
graph using base R or ggplot2.

- [`plot(`*`<song_model>`*`)`](https://r-heller.github.io/songR/reference/plot.song_model.md)
  : Plot a SONG Model
- [`autoplot.song_model()`](https://r-heller.github.io/songR/reference/autoplot.song_model.md)
  : Autoplot Method for SONG Models

## Model Inspection

Print and summarize SONG model objects, including codebook statistics,
quantization error, and graph connectivity.

- [`print(`*`<song_model>`*`)`](https://r-heller.github.io/songR/reference/print.song_model.md)
  : Print a SONG Model
- [`summary(`*`<song_model>`*`)`](https://r-heller.github.io/songR/reference/summary.song_model.md)
  : Summarize a SONG Model

## Interactive App

Launch a Shiny app to compare SONG, t-SNE, and UMAP side-by-side with
dark mode, custom data upload, and incremental update support.

- [`run_songR_app()`](https://r-heller.github.io/songR/reference/run_songR_app.md)
  : Launch Interactive Comparison App

## Data

Bundled datasets for examples, vignettes, and benchmarking.

- [`songR_blobs`](https://r-heller.github.io/songR/reference/songR_blobs.md)
  : Simulated Gaussian Blobs Dataset

## Package

- [`songR`](https://r-heller.github.io/songR/reference/songR-package.md)
  [`songR-package`](https://r-heller.github.io/songR/reference/songR-package.md)
  : songR: Self-Organizing Nebulous Growths for Dimensionality Reduction
