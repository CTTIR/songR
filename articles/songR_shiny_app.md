# Interactive Visualization with the songR Shiny App

## Overview

songR includes a built-in Shiny application for interactive exploration
of SONG embeddings. The app lets you:

- Upload CSV/RDS data or use built-in datasets
- Adjust SONG hyperparameters (epochs, epsilon, spread_factor, k)
- Run SONG, t-SNE, and UMAP side-by-side
- Incrementally add data and observe embedding stability
- Color points by any variable (discrete or continuous)
- Toggle **dark mode** for comfortable viewing (preference persisted via
  localStorage)
- Export embeddings and plots

All plots use the **viridis plasma** color scale for perceptually
uniform, colorblind-friendly visualization.

## Launching the App

``` r
library(songR)

# Launch with default settings
run_songR_app()
```

The app opens in your default browser.

## Using Built-in Data

The app ships with `songR_blobs`, an 8-cluster synthetic dataset in 20
dimensions. Select it from the “Data” dropdown to get started
immediately.

## Uploading Your Own Data

1.  Click **Upload Data** in the sidebar
2.  Select a CSV file (first columns = features, optional last column =
    labels)
3.  Or upload an RDS file containing a list with `$data` (matrix) and
    optional `$labels` (factor/character)

## Hyperparameter Controls

The sidebar provides sliders for all key SONG parameters:

| Control       | Maps to         | Effect                        |
|---------------|-----------------|-------------------------------|
| Epochs        | `epochs`        | More = better quality, slower |
| Epsilon       | `epsilon`       | Edge decay rate (0-1)         |
| Spread Factor | `spread_factor` | Growth threshold for new CVs  |
| k             | `k`             | Neighborhood size             |
| Dispersion    | `dispersion`    | Toggle UMAP refinement        |

## Incremental Mode

The app supports SONG’s incremental workflow:

1.  Load initial data and click **Run SONG**
2.  Upload additional data via **Add Increment**
3.  Click **Update Model** — the existing embedding is preserved
4.  Compare with **Reinitialize** to see the stability difference

## Dark Mode

Click the moon/sun toggle button in the navbar to switch between light
and dark mode. The preference is saved in your browser’s localStorage
and restored on the next visit.

Dark mode adjusts:

- Background, text, and border colors for all UI panels
- Plot backgrounds and axis label colors
- Sidebar, navbar, and well panel styling

## Exporting Results

- **Download Embedding**: Saves the 2D coordinates as CSV
- **Download Plot**: Exports the current visualization as PNG/PDF
- **Download Model**: Saves the full `song_model` object as RDS

## Example Workflow

``` r
library(songR)

# Programmatic equivalent of the Shiny workflow:

# 1. Load data
data(songR_blobs)
X <- songR_blobs$data
labels <- songR_blobs$labels

# 2. Initial SONG
model <- song(X[1:500, ], epochs = 20L, seed = 42, verbose = FALSE)
plot(model, color_by = labels[1:500])

# 3. Incremental update
model <- update(model, X[501:1000, ], epochs = 20L, verbose = FALSE)
emb <- predict(model, newdata = X[1:1000, ])

# 4. Visualize
plot(emb[, 1], emb[, 2], pch = 16, cex = 0.5,
     col = rainbow(8)[as.integer(labels[1:1000])],
     main = "After Incremental Update",
     xlab = "SONG 1", ylab = "SONG 2", bty = "n")
```

## Session Info

``` r
sessionInfo()
#> R version 4.5.3 (2026-03-11)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.4 LTS
#> 
#> Matrix products: default
#> BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
#> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
#> 
#> locale:
#>  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
#>  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
#>  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
#> [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
#> 
#> time zone: UTC
#> tzcode source: system (glibc)
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> loaded via a namespace (and not attached):
#>  [1] digest_0.6.39     desc_1.4.3        R6_2.6.1          fastmap_1.2.0    
#>  [5] xfun_0.57         cachem_1.1.0      knitr_1.51        htmltools_0.5.9  
#>  [9] rmarkdown_2.31    lifecycle_1.0.5   cli_3.6.6         sass_0.4.10      
#> [13] pkgdown_2.2.0     textshaping_1.0.5 jquerylib_0.1.4   systemfonts_1.3.2
#> [17] compiler_4.5.3    tools_4.5.3       ragg_1.5.2        bslib_0.10.0     
#> [21] evaluate_1.0.5    yaml_2.3.12       otel_0.2.0        jsonlite_2.0.0   
#> [25] rlang_1.2.0       fs_2.0.1
```
