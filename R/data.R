#' Simulated Gaussian Blobs Dataset
#'
#' A list containing a simulated dataset of 1600 points in 20 dimensions,
#' organized into 8 Gaussian clusters. Designed for benchmarking and
#' demonstrating dimensionality reduction methods.
#'
#' @format A list with three elements:
#' \describe{
#'   \item{data}{Numeric matrix (1600 x 20) of simulated features.}
#'   \item{labels}{Factor of length 1600 indicating cluster membership.}
#'   \item{description}{Character string describing the dataset.}
#' }
#' @source Simulated data inspired by the experimental setup in
#'   Senanayake et al. (2021) \doi{10.1109/TNNLS.2020.3023941}.
#' @examples
#' data(songR_blobs)
#' str(songR_blobs)
"songR_blobs"
