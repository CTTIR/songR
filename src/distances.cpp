// [[Rcpp::depends(RcppArmadillo)]]
#include <RcppArmadillo.h>

// Squared Euclidean distance between two vectors
// [[Rcpp::export]]
double sq_euclidean_dist_cpp(const arma::rowvec& a, const arma::rowvec& b) {
  arma::rowvec diff = a - b;
  return arma::dot(diff, diff);
}

// Euclidean distance between two vectors
// [[Rcpp::export]]
double euclidean_dist_cpp(const arma::rowvec& a, const arma::rowvec& b) {
  return std::sqrt(sq_euclidean_dist_cpp(a, b));
}

// Compute squared Euclidean distances from one point to all rows of a matrix
// Returns a vector of length nrow(M)
// [[Rcpp::export]]
arma::vec sq_dist_to_rows_cpp(const arma::rowvec& x, const arma::mat& M) {
  int n = M.n_rows;
  arma::vec dists(n);
  for (int i = 0; i < n; i++) {
    arma::rowvec diff = x - M.row(i);
    dists(i) = arma::dot(diff, diff);
  }
  return dists;
}
