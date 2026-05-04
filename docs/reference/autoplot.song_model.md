# Autoplot Method for SONG Models

Creates a `ggplot2` plot of a `"song_model"` object. Requires `ggplot2`
to be installed.

## Usage

``` r
autoplot.song_model(
  object,
  type = c("embedding", "codebook", "graph"),
  color_by = NULL,
  ...
)
```

## Arguments

- object:

  A `"song_model"` object.

- type:

  Character. One of `"embedding"`, `"codebook"`, or `"graph"`.

- color_by:

  Optional vector for coloring points.

- ...:

  Ignored.

## Value

A `ggplot` object.

## References

Senanayake, D. A., Wang, W., Naik, S. H., & Halgamuge, S. (2021).
Self-Organizing Nebulous Growths for Robust and Incremental Data
Visualization. *IEEE Transactions on Neural Networks and Learning
Systems*, 32(10), 4588–4602.
[doi:10.1109/TNNLS.2020.3023941](https://doi.org/10.1109/TNNLS.2020.3023941)

## Examples

``` r
# \donttest{
if (requireNamespace("ggplot2", quietly = TRUE)) {
  model <- song(as.matrix(iris[, 1:4]), epochs = 5L, seed = 42)
  # Use songR::autoplot.song_model(model, color_by = iris$Species)
  # or ensure songR is loaded with library(songR) for dispatch
}
#> Epoch 1/5 | CVs: 3 | QE: 1.5296 | so_lr: 1.0000 | lr: 1.0000
#> Epoch 2/5 | CVs: 5 | QE: 0.8414 | so_lr: 0.8187 | lr: 0.8000
#> Epoch 3/5 | CVs: 9 | QE: 0.5435 | so_lr: 0.4493 | lr: 0.6000
#> Epoch 4/5 | CVs: 16 | QE: 0.4550 | so_lr: 0.1653 | lr: 0.4000
#> Epoch 5/5 | CVs: 26 | QE: 0.3896 | so_lr: 0.0408 | lr: 0.2000
#> Running UMAP dispersion step...
# }
```
