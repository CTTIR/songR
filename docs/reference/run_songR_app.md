# Launch Interactive Comparison App

Opens a Shiny application that compares SONG, t-SNE, and UMAP
visualizations side-by-side on user-supplied or example data. The app
features a dark mode toggle (persisted via localStorage), uses the
viridis plasma color scale for all plots, and supports uploading custom
CSV/RDS data, tuning SONG hyperparameters, running incremental updates,
and exporting embeddings.

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
