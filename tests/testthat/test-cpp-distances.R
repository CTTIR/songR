# Direct tests for the exported C++ distance primitives in src/distances.cpp.
# These wrap arma::dot and are validated against the reference fixtures when
# available, and against hand-computed values otherwise.

test_that("sq_euclidean_dist_cpp returns the squared Euclidean distance", {
  a <- c(0, 0, 0)
  b <- c(3, 4, 0)
  expect_equal(songR:::sq_euclidean_dist_cpp(a, b), 25)
  expect_equal(songR:::sq_euclidean_dist_cpp(a, a), 0)
})

test_that("euclidean_dist_cpp returns the (non-squared) Euclidean distance", {
  expect_equal(songR:::euclidean_dist_cpp(c(0, 0), c(3, 4)), 5)
  expect_equal(
    songR:::euclidean_dist_cpp(c(1, 2, 3), c(1, 2, 3)),
    0
  )
})

test_that("euclidean_dist_cpp is the square root of sq_euclidean_dist_cpp", {
  set.seed(99)
  a <- rnorm(10); b <- rnorm(10)
  expect_equal(
    songR:::euclidean_dist_cpp(a, b),
    sqrt(songR:::sq_euclidean_dist_cpp(a, b))
  )
})

test_that("sq_dist_to_rows_cpp matches rowwise squared distances", {
  x <- c(1, 2)
  M <- matrix(c(1, 2,
                4, 6,
                1, 2), ncol = 2, byrow = TRUE)
  d <- as.numeric(songR:::sq_dist_to_rows_cpp(x, M))
  expect_length(d, 3L)
  expect_equal(d, c(0, 9 + 16, 0))
})

test_that("sq_dist_to_rows_cpp matches the Tier-A reference squared distances", {
  fx <- file.path("fixtures", "reference")
  skip_if_not(file.exists(file.path(fx, "tierA_sqdist.csv")),
              "reference fixtures not generated")
  A <- as.matrix(utils::read.csv(file.path(fx, "tierA_A.csv"), header = FALSE))
  B <- as.matrix(utils::read.csv(file.path(fx, "tierA_B.csv"), header = FALSE))
  ref_d <- as.matrix(utils::read.csv(file.path(fx, "tierA_sqdist.csv"), header = FALSE))

  song_d <- t(apply(A, 1L, function(x) songR:::sq_dist_to_rows_cpp(as.numeric(x), B)))
  expect_equal(unname(song_d), unname(ref_d), tolerance = 1e-5)
})
