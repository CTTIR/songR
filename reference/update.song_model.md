# Incrementally Update a SONG Model with New Data

Adds new data to an existing SONG model. This is the key differentiator
of SONG over t-SNE and UMAP: training continues from the existing model.
Coding vectors, edges and embedding positions may change. The supplied
object is unchanged; use
[`predict.song_model()`](https://cttir.github.io/songR/reference/predict.song_model.md)
for frozen projection.

## Usage

``` r
# S3 method for class 'song_model'
update(
  object,
  X_new,
  epochs = 50L,
  alpha = NULL,
  verbose = TRUE,
  ...,
  feature_manifest = NULL,
  seed = NULL
)
```

## Arguments

- object:

  A `"song_model"` object to update.

- X_new:

  Numeric matrix of new data (`n_new x D`). Must have the same number of
  columns as the original training data.

- epochs:

  Integer. Number of additional training epochs (default: 50).

- alpha:

  Numeric or `NULL`. Initial learning rate for the update. If `NULL`,
  uses the original learning rate (default: NULL).

- verbose:

  Logical. Whether to print progress (default: TRUE).

- ...:

  Ignored.

- feature_manifest:

  The unchanged manifest supplied at training, if any. Named features
  must follow training order. See
  [`song()`](https://cttir.github.io/songR/reference/song.md) for the
  contract.

- seed:

  Optional integer seed for update training. `NULL` preserves the
  existing random-stream behavior; the original fit seed is not reused.

## Value

An updated `"song_model"` object with grown codebook incorporating the
new data. `embedding` and `assignments` describe only `X_new`; `n_input`
counts all training rows across updates.

## Details

`lineage` schema 1.0.0 records a revision, a deterministic SHA-256 model
identifier and its parent identifier. Identifiers bind the ordered
projection codebook, coordinates, feature contract and revision
ancestry, not the full training history or authenticity of a manually
modified object. Each update requires reprojection of all earlier
observations with the new model before combining coordinates. Earlier
input rows are not retained or automatically reprojected. Initial
revisions start at 1. Updates to legacy models start a new revision
history at 1 with `parent_history` set to `legacy_unversioned` and a
parent projection fingerprint. Save the model together with any exported
projection to retain its version. Coincident embedding positions reflect
prototype assignment; they do not establish cell contact or physical
spatial distance.

## References

Senanayake, D. A., Wang, W., Naik, S. H., & Halgamuge, S. (2021).
Self-Organizing Nebulous Growths for Robust and Incremental Data
Visualization. *IEEE Transactions on Neural Networks and Learning
Systems*, 32(10), 4588–4602.
[doi:10.1109/TNNLS.2020.3023941](https://doi.org/10.1109/TNNLS.2020.3023941)

## See also

[`song`](https://cttir.github.io/songR/reference/song.md),
[`predict.song_model`](https://cttir.github.io/songR/reference/predict.song_model.md)

## Examples

``` r
model <- song(as.matrix(iris[1:100, 1:4]), epochs = 5L, seed = 42)
#> Epoch 1/5 | CVs: 3 | QE: 1.2359 | so_lr: 1.0000 | lr: 1.0000
#> Epoch 2/5 | CVs: 5 | QE: 0.6649 | so_lr: 0.8187 | lr: 0.8000
#> Epoch 3/5 | CVs: 9 | QE: 0.4649 | so_lr: 0.4493 | lr: 0.6000
#> Epoch 4/5 | CVs: 16 | QE: 0.3477 | so_lr: 0.1653 | lr: 0.4000
#> Epoch 5/5 | CVs: 21 | QE: 0.3056 | so_lr: 0.0408 | lr: 0.2000
#> Running UMAP dispersion step...
model <- update(model, as.matrix(iris[101:150, 1:4]), epochs = 5L)
#> Update Epoch 1/5 | CVs: 21 | QE: 0.5903 | so_lr: 1.0000
#> Update Epoch 2/5 | CVs: 32 | QE: 0.4040 | so_lr: 0.8187
#> Update Epoch 3/5 | CVs: 32 | QE: 0.3603 | so_lr: 0.4493
#> Update Epoch 4/5 | CVs: 32 | QE: 0.3495 | so_lr: 0.1653
#> Update Epoch 5/5 | CVs: 32 | QE: 0.3294 | so_lr: 0.0408
```
