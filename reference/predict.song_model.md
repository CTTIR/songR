# Project New Points into a SONG Embedding

Maps new data points into an existing SONG embedding by assigning each
point to its nearest coding vector and returning that coding vector's
embedding coordinates.

## Usage

``` r
# S3 method for class 'song_model'
predict(object, newdata, ...)
```

## Arguments

- object:

  A trained `"song_model"` object.

- newdata:

  Numeric matrix of new data (`n_new x D`).

- ...:

  Ignored.

## Value

A numeric matrix (`n_new x d`) of embedding coordinates.

## References

Senanayake, D. A., Wang, W., Naik, S. H., & Halgamuge, S. (2021).
Self-Organizing Nebulous Growths for Robust and Incremental Data
Visualization. *IEEE Transactions on Neural Networks and Learning
Systems*, 32(10), 4588–4602.
[doi:10.1109/TNNLS.2020.3023941](https://doi.org/10.1109/TNNLS.2020.3023941)

## See also

[`song`](https://cttir.github.io/songR/reference/song.md),
[`update.song_model`](https://cttir.github.io/songR/reference/update.song_model.md)

## Examples

``` r
model <- song(as.matrix(iris[1:120, 1:4]), epochs = 5L, seed = 42)
#> Epoch 1/5 | CVs: 3 | QE: 1.4789 | so_lr: 1.0000 | lr: 1.0000
#> Epoch 2/5 | CVs: 5 | QE: 0.8328 | so_lr: 0.8187 | lr: 0.8000
#> Epoch 3/5 | CVs: 9 | QE: 0.5362 | so_lr: 0.4493 | lr: 0.6000
#> Epoch 4/5 | CVs: 16 | QE: 0.4402 | so_lr: 0.1653 | lr: 0.4000
#> Epoch 5/5 | CVs: 24 | QE: 0.3847 | so_lr: 0.0408 | lr: 0.2000
#> Running UMAP dispersion step...
new_coords <- predict(model, newdata = as.matrix(iris[121:150, 1:4]))
```
