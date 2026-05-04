// [[Rcpp::depends(RcppArmadillo)]]
#include <RcppArmadillo.h>

// Brute-force k-nearest neighbor search among coding vectors
// Returns 0-indexed indices of k nearest rows in C to query point x
// [[Rcpp::export]]
arma::uvec knn_search_cpp(const arma::rowvec& x, const arma::mat& C, int k) {
  int n = C.n_rows;
  if (k > n) k = n;

  arma::vec dists(n);
  for (int i = 0; i < n; i++) {
    arma::rowvec diff = x - C.row(i);
    dists(i) = arma::dot(diff, diff);
  }

  // Get indices of k smallest distances
  arma::uvec sorted_idx = arma::sort_index(dists);
  return sorted_idx.head(k);
}

// Batch k-NN: for each row of X, find k nearest rows in C
// Returns n_X x k matrix of 0-indexed indices
// [[Rcpp::export]]
arma::umat batch_knn_search_cpp(const arma::mat& X, const arma::mat& C, int k) {
  int n = X.n_rows;
  int nc = C.n_rows;
  if (k > nc) k = nc;

  arma::umat result(n, k);
  for (int i = 0; i < n; i++) {
    arma::vec dists(nc);
    for (int j = 0; j < nc; j++) {
      arma::rowvec diff = X.row(i) - C.row(j);
      dists(j) = arma::dot(diff, diff);
    }
    arma::uvec sorted_idx = arma::sort_index(dists);
    result.row(i) = sorted_idx.head(k).t();
  }
  return result;
}
