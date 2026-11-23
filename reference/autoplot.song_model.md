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

  Optional vector for coloring points; see
  [`plot.song_model`](https://cttir.github.io/songR/reference/plot.song_model.md)
  for the accepted lengths. As in
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html), up to eight
  categories are drawn in the Okabe-Ito palette and numeric vectors on
  the viridis scale; more than eight categories use the default discrete
  `ggplot2` scale. Adding a color scale to the returned plot replaces
  the scale chosen here.

- ...:

  Ignored.

## Value

A `ggplot` object.

## Details

The method is registered for
[`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
when ggplot2 is available, so `ggplot2::autoplot(model)` dispatches to
it once songR is loaded. Models with more than two output dimensions are
drawn in their first two embedding dimensions.

## References

Senanayake, D. A., Wang, W., Naik, S. H., & Halgamuge, S. (2021).
Self-Organizing Nebulous Growths for Robust and Incremental Data
Visualization. *IEEE Transactions on Neural Networks and Learning
Systems*, 32(10), 4588–4602.
[doi:10.1109/TNNLS.2020.3023941](https://doi.org/10.1109/TNNLS.2020.3023941)

## Examples

``` r
model <- song(as.matrix(iris[, 1:4]), epochs = 5L, seed = 42,
              verbose = FALSE)
ggplot2::autoplot(model, color_by = iris$Species)

autoplot.song_model(model, type = "graph", color_by = iris$Species)
```
