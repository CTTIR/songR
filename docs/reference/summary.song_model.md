# Summarize a SONG Model

Provides a detailed summary of a `"song_model"` object, including
quantization error and edge statistics.

## Usage

``` r
# S3 method for class 'song_model'
summary(object, ...)
```

## Arguments

- object:

  A `"song_model"` object.

- ...:

  Ignored.

## Value

Invisible `object`.

## References

Senanayake, D. A., Wang, W., Naik, S. H., & Halgamuge, S. (2021).
Self-Organizing Nebulous Growths for Robust and Incremental Data
Visualization. *IEEE Transactions on Neural Networks and Learning
Systems*, 32(10), 4588–4602.
[doi:10.1109/TNNLS.2020.3023941](https://doi.org/10.1109/TNNLS.2020.3023941)

## Examples

``` r
model <- song(as.matrix(iris[, 1:4]), epochs = 5L, seed = 42)
#> Epoch 1/5 | CVs: 3 | QE: 1.5296 | so_lr: 1.0000 | lr: 1.0000
#> Epoch 2/5 | CVs: 5 | QE: 0.8414 | so_lr: 0.8187 | lr: 0.8000
#> Epoch 3/5 | CVs: 9 | QE: 0.5435 | so_lr: 0.4493 | lr: 0.6000
#> Epoch 4/5 | CVs: 16 | QE: 0.4550 | so_lr: 0.1653 | lr: 0.4000
#> Epoch 5/5 | CVs: 26 | QE: 0.3896 | so_lr: 0.0408 | lr: 0.2000
#> Running UMAP dispersion step...
summary(model)
#> SONG model summary
#> ==================
#>   Input: 150 points in 4 dimensions
#>   Coding vectors: 26 
#>   Compression ratio: 5.8:1 
#>   Edges: 44 
#>   Mean edge strength: 0.8091 
#>   Output dimensionality: 2 
#>   Epochs: 5 (max epochs) 
#> 
#> Parameters:
#>   k = 3 | epsilon = 0.9 | spread_factor = 0.5 
#>   a = 1.577 | b = 0.895 | alpha = 1 
```
