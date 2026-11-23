# Launch Interactive Comparison App

Opens a Shiny application that compares SONG, t-SNE, and UMAP
visualizations side-by-side on the built-in example data (iris and
[`songR_blobs`](https://cttir.github.io/songR/reference/songR_blobs.md))
or on an uploaded CSV file. The app lets you choose the feature and
label columns of an upload, tune the main SONG hyperparameters (`k`,
`spread_factor`, `epochs`, `epsilon` and the dispersion step) together
with the t-SNE perplexity and the UMAP neighborhood size, and inspect
the fitted SONG codebook graph and model summary. It features a dark
mode toggle (persisted via localStorage) and uses the viridis plasma
color scale for the comparison plots.

## Usage

``` r
run_songR_app(launch.browser = TRUE)
```

## Arguments

- launch.browser:

  Logical. Whether to open the app in the browser (default: `TRUE`).

## Value

Invisible `NULL`. The function is called for its side effect of
launching the Shiny app.

## Details

The app is a viewer: incremental updates, projection of new points and
export of embeddings or models are done in code with
[`update.song_model`](https://cttir.github.io/songR/reference/update.song_model.md),
[`predict.song_model`](https://cttir.github.io/songR/reference/predict.song_model.md)
and [`saveRDS`](https://rdrr.io/r/base/readRDS.html).

The app needs the suggested packages shiny, Rtsne, uwot and viridis; a
missing one is reported with an installation hint.

## References

Senanayake, D. A., Wang, W., Naik, S. H., & Halgamuge, S. (2021).
Self-Organizing Nebulous Growths for Robust and Incremental Data
Visualization. *IEEE Transactions on Neural Networks and Learning
Systems*, 32(10), 4588–4602.
[doi:10.1109/TNNLS.2020.3023941](https://doi.org/10.1109/TNNLS.2020.3023941)

## Examples

``` r
if (interactive()) {
  run_songR_app()
}
```
