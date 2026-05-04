# Introduction to songR

## What is SONG?

The Self-Organizing Nebulous Growths (SONG) algorithm is a parametric
method for nonlinear dimensionality reduction. Unlike t-SNE and UMAP,
SONG supports **incremental visualization**: new data can be added to an
existing embedding without reinitializing or retraining the model. SONG
is also robust to noise and highly mixed clusters.

| Property            | SONG           | t-SNE     | UMAP      |
|---------------------|----------------|-----------|-----------|
| Incremental updates | Yes            | No        | Limited   |
| Parametric model    | Yes (codebook) | No        | Optional  |
| Noise robustness    | High           | Low       | Medium    |
| Speed               | Moderate       | Slow      | Fast      |
| Deterministic       | With seed      | With seed | With seed |

The algorithm is described in:

> Senanayake, D. A., Wang, W., Naik, S. H., & Halgamuge, S. (2021).
> Self-Organizing Nebulous Growths for Robust and Incremental Data
> Visualization. *IEEE TNNLS*, 32(10), 4588–4602.

## Installation

``` r
# Install from GitHub
devtools::install_github("r-heller/songR")
```

## Quick Start with Iris

``` r
library(songR)

model <- song(as.matrix(iris[, 1:4]), seed = 42, epochs = 20L)
#> Epoch 1/20 | CVs: 3 | QE: 1.5296 | so_lr: 1.0000 | lr: 1.0000
#> Epoch 2/20 | CVs: 5 | QE: 0.8782 | so_lr: 0.9876 | lr: 0.9500
#> Epoch 3/20 | CVs: 9 | QE: 0.5992 | so_lr: 0.9512 | lr: 0.9000
#> Epoch 4/20 | CVs: 16 | QE: 0.4691 | so_lr: 0.8936 | lr: 0.8500
#> Epoch 5/20 | CVs: 28 | QE: 0.3987 | so_lr: 0.8187 | lr: 0.8000
#> Epoch 6/20 | CVs: 28 | QE: 0.3756 | so_lr: 0.7316 | lr: 0.7500
#> Epoch 7/20 | CVs: 28 | QE: 0.3640 | so_lr: 0.6376 | lr: 0.7000
#> Epoch 8/20 | CVs: 28 | QE: 0.3623 | so_lr: 0.5420 | lr: 0.6500
#> Epoch 9/20 | CVs: 28 | QE: 0.3596 | so_lr: 0.4493 | lr: 0.6000
#> Epoch 10/20 | CVs: 28 | QE: 0.3543 | so_lr: 0.3633 | lr: 0.5500
#> Epoch 11/20 | CVs: 28 | QE: 0.3480 | so_lr: 0.2865 | lr: 0.5000
#> Epoch 12/20 | CVs: 28 | QE: 0.3408 | so_lr: 0.2204 | lr: 0.4500
#> Epoch 13/20 | CVs: 28 | QE: 0.3269 | so_lr: 0.1653 | lr: 0.4000
#> Epoch 14/20 | CVs: 28 | QE: 0.3193 | so_lr: 0.1209 | lr: 0.3500
#> Epoch 15/20 | CVs: 28 | QE: 0.3178 | so_lr: 0.0863 | lr: 0.3000
#> Epoch 16/20 | CVs: 28 | QE: 0.3145 | so_lr: 0.0601 | lr: 0.2500
#> Epoch 17/20 | CVs: 28 | QE: 0.3117 | so_lr: 0.0408 | lr: 0.2000
#> Epoch 18/20 | CVs: 28 | QE: 0.3097 | so_lr: 0.0270 | lr: 0.1500
#> Epoch 19/20 | CVs: 28 | QE: 0.3084 | so_lr: 0.0174 | lr: 0.1000
#> Epoch 20/20 | CVs: 28 | QE: 0.3078 | so_lr: 0.0110 | lr: 0.0500
#> Running UMAP dispersion step...
plot(model, color_by = iris$Species)
```

![](introduction_files/figure-html/quickstart-1.png)

## Working with the Bundled Dataset

``` r
data(songR_blobs)
model_blobs <- song(songR_blobs$data, seed = 42, epochs = 15L, verbose = FALSE)
plot(model_blobs, color_by = songR_blobs$labels)
```

![](introduction_files/figure-html/blobs-1.png)

## Incremental Visualization

This is SONG’s key feature. We train on the first half of the data, then
incrementally add the second half.

``` r
# Split data
data(songR_blobs)
n <- nrow(songR_blobs$data)
idx1 <- 1:(n / 2)
idx2 <- (n / 2 + 1):n

# Train on first half
model_v1 <- song(songR_blobs$data[idx1, ], seed = 42, epochs = 15L, verbose = FALSE)

# Update with second half
model_v2 <- update(model_v1, songR_blobs$data[idx2, ], epochs = 10L, verbose = FALSE)

par(mfrow = c(1, 2))
plot(model_v1$embedding, pch = 16, cex = 0.5,
     col = rainbow(8)[as.integer(songR_blobs$labels[idx1])],
     main = "Before update", xlab = "SONG 1", ylab = "SONG 2", bty = "n")
plot(model_v2$embedding, pch = 16, cex = 0.5,
     col = rainbow(8)[as.integer(songR_blobs$labels[idx2])],
     main = "After update", xlab = "SONG 1", ylab = "SONG 2", bty = "n")
```

![](introduction_files/figure-html/incremental-1.png)

The codebook grows to accommodate new data while preserving the existing
embedding structure.

## Predicting New Points

``` r
# Train on 90%, predict on 10%
train_idx <- 1:135
test_idx <- 136:150

model <- song(as.matrix(iris[train_idx, 1:4]), epochs = 15L, seed = 42,
              verbose = FALSE)
new_coords <- predict(model, newdata = as.matrix(iris[test_idx, 1:4]))

# Plot training and test points together
plot(model$embedding[, 1], model$embedding[, 2],
     col = "gray70", pch = 16, cex = 0.6,
     xlab = "SONG 1", ylab = "SONG 2", main = "Training (gray) + Predicted (red)")
points(new_coords[, 1], new_coords[, 2], col = "red", pch = 17, cex = 1.2)
```

![](introduction_files/figure-html/predict-1.png)

## Comparison: SONG vs t-SNE vs UMAP

``` r
mat <- as.matrix(iris[, 1:4])

# SONG
song_model <- song(mat, seed = 42, epochs = 20L, verbose = FALSE)

# t-SNE
tsne_result <- Rtsne::Rtsne(mat, dims = 2, perplexity = 30,
                              verbose = FALSE, check_duplicates = FALSE)

# UMAP
umap_result <- uwot::umap(mat, n_neighbors = 15, verbose = FALSE)

par(mfrow = c(1, 3))
col <- as.integer(iris$Species)
plot(song_model$embedding, col = col, pch = 16, main = "SONG",
     xlab = "SONG 1", ylab = "SONG 2")
plot(tsne_result$Y, col = col, pch = 16, main = "t-SNE",
     xlab = "tSNE 1", ylab = "tSNE 2")
plot(umap_result, col = col, pch = 16, main = "UMAP",
     xlab = "UMAP 1", ylab = "UMAP 2")
```

![](introduction_files/figure-html/comparison-1.png)

All three methods separate the Iris species, but only SONG supports
incremental updates and retains a parametric codebook model.

## Tuning Guide

| Parameter | Default | Description |
|----|----|----|
| `spread_factor` | 0.5 | Growth threshold; higher = more coding vectors. Range: (0, 1). |
| `k` | 3 | Neighborhood size. Must be \>= `d + 1`. Lower = finer topology. |
| `epsilon` | 0.9 | Edge decay rate (0–1). Lower = sparser, faster-pruning graph. |
| `epochs` | 50 | Number of self-organisation iterations. More = better convergence. |
| `alpha` | 1.0 | Initial learning rate. |
| `a`, `b` | 1.577, 0.895 | Kernel shape parameters from the UMAP literature. |
| `dispersion` | TRUE | UMAP refinement step for visual cluster separation. |

## The Codebook Model

SONG retains a codebook of coding vectors connected by a
topology-preserving graph. This is what enables incremental updates and
fast projection.

``` r
model <- song(as.matrix(iris[, 1:4]), seed = 42, epochs = 15L, verbose = FALSE)
summary(model)
#> SONG model summary
#> ==================
#>   Input: 150 points in 4 dimensions
#>   Coding vectors: 28 
#>   Compression ratio: 5.4:1 
#>   Edges: 48 
#>   Mean edge strength: 0.8365 
#>   Output dimensionality: 2 
#>   Epochs: 15 (max epochs) 
#> 
#> Parameters:
#>   k = 3 | epsilon = 0.9 | spread_factor = 0.5 
#>   a = 1.577 | b = 0.895 | alpha = 1
plot(model, type = "graph", color_by = iris$Species)
```

![](introduction_files/figure-html/codebook-1.png)

## Interactive Comparison App

For interactive exploration, launch the Shiny comparison app:

``` r
run_songR_app()
```

This opens a browser-based interface to compare SONG, t-SNE, and UMAP
side-by-side on your own data.

## Citation

``` r
citation("songR")
#> To cite the songR R package, use:
#> 
#>   Heller, R. (2026). songR: Self-Organizing Nebulous Growths for
#>   Dimensionality Reduction. R package version 0.1.0.
#>   https://github.com/r-heller/songR
#> 
#> To cite the underlying SONG algorithm, use:
#> 
#>   Senanayake, D. A., Wang, W., Naik, S. H., & Halgamuge, S. (2021).
#>   Self-Organizing Nebulous Growths for Robust and Incremental Data
#>   Visualization. IEEE Transactions on Neural Networks and Learning
#>   Systems, 32(10), 4588-4602. doi:10.1109/TNNLS.2020.3023941
#> 
#> To see these entries in BibTeX format, use 'print(<citation>,
#> bibtex=TRUE)', 'toBibtex(.)', or set
#> 'options(citation.bibtex.max=999)'.
```

## Session Info

``` r
sessionInfo()
#> R version 4.5.2 (2025-10-31 ucrt)
#> Platform: x86_64-w64-mingw32/x64
#> Running under: Windows 11 x64 (build 26200)
#> 
#> Matrix products: default
#>   LAPACK version 3.12.1
#> 
#> locale:
#> [1] LC_COLLATE=English_Germany.utf8  LC_CTYPE=English_Germany.utf8   
#> [3] LC_MONETARY=English_Germany.utf8 LC_NUMERIC=C                    
#> [5] LC_TIME=English_Germany.utf8    
#> 
#> time zone: Europe/Berlin
#> tzcode source: internal
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] songR_0.1.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] Matrix_1.7-4       gtable_0.3.6       jsonlite_2.0.0     dplyr_1.2.0       
#>  [5] compiler_4.5.2     tidyselect_1.2.1   Rcpp_1.1.1         FNN_1.1.4.1       
#>  [9] jquerylib_0.1.4    systemfonts_1.3.2  scales_1.4.0       textshaping_1.0.5 
#> [13] yaml_2.3.12        fastmap_1.2.0      uwot_0.2.4         lattice_0.22-7    
#> [17] ggplot2_4.0.2      R6_2.6.1           generics_0.1.4     knitr_1.51        
#> [21] htmlwidgets_1.6.4  tibble_3.3.1       Rtsne_0.17         desc_1.4.3        
#> [25] pillar_1.11.1      bslib_0.10.0       RColorBrewer_1.1-3 rlang_1.1.7       
#> [29] cachem_1.1.0       xfun_0.57          fs_2.0.1           sass_0.4.10       
#> [33] S7_0.2.1           otel_0.2.0         cli_3.6.5          pkgdown_2.2.0     
#> [37] magrittr_2.0.4     digest_0.6.39      grid_4.5.2         lifecycle_1.0.5   
#> [41] vctrs_0.7.1        evaluate_1.0.5     glue_1.8.0         farver_2.1.2      
#> [45] ragg_1.5.2         rmarkdown_2.31     pkgconfig_2.0.3    tools_4.5.2       
#> [49] htmltools_0.5.9
```
