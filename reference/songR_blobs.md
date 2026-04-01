# Simulated Gaussian Blobs Dataset

A list containing a simulated dataset of 1600 points in 20 dimensions,
organized into 8 Gaussian clusters. Designed for benchmarking and
demonstrating dimensionality reduction methods.

## Usage

``` r
songR_blobs
```

## Format

A list with three elements:

- data:

  Numeric matrix (1600 x 20) of simulated features.

- labels:

  Factor of length 1600 indicating cluster membership.

- description:

  Character string describing the dataset.

## Source

Simulated data inspired by the experimental setup in Senanayake et al.
(2021)
[doi:10.1109/TNNLS.2020.3023941](https://doi.org/10.1109/TNNLS.2020.3023941)
.

## Examples

``` r
data(songR_blobs)
str(songR_blobs)
#> List of 3
#>  $ data       : num [1:1600, 1:20] -3.11 -1.6 -3.43 1.19 -4.47 ...
#>  $ labels     : Factor w/ 8 levels "cluster_1","cluster_2",..: 1 1 1 1 1 1 1 1 1 1 ...
#>  $ description: chr "Simulated Gaussian blobs dataset"
```
