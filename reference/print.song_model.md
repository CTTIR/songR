# Print a SONG Model

Prints a concise summary of a `"song_model"` object.

## Usage

``` r
# S3 method for class 'song_model'
print(x, ...)
```

## Arguments

- x:

  A `"song_model"` object.

- ...:

  Ignored.

## Value

Invisible `x`.

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
#> Epoch 3/5 | CVs: 9 | QE: 0.5442 | so_lr: 0.4493 | lr: 0.6000
#> Epoch 4/5 | CVs: 16 | QE: 0.4508 | so_lr: 0.1653 | lr: 0.4000
#> Epoch 5/5 | CVs: 25 | QE: 0.3978 | so_lr: 0.0408 | lr: 0.2000
#> Running UMAP dispersion step...
print(model)
#> SONG model
#>   Input: 150 points in 4 dimensions
#>   Coding vectors: 25 
#>   Edges: 42 
#>   Output dimensionality: 2 
#>   Epochs: 5 (max epochs) 
```
