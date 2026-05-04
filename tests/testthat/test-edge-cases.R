test_that("song() errors on non-numeric input", {
  expect_error(song(matrix("a", 5, 3)), "numeric")
})

test_that("song() errors on matrix with NAs", {
  m <- as.matrix(iris[1:10, 1:4])
  m[1, 1] <- NA
  expect_error(song(m), "NA")
})

test_that("song() errors on k < d + 1", {
  expect_error(song(as.matrix(iris[, 1:4]), k = 2L, d = 2L),
               "k.*must be >= d \\+ 1")
})

test_that("song() handles single-column input", {
  m <- matrix(rnorm(50), ncol = 1)
  model <- song(m, d = 1L, k = 2L, epochs = 3L, seed = 42, verbose = FALSE)
  expect_s3_class(model, "song_model")
  expect_equal(ncol(model$embedding), 1)
})

test_that("song() handles very small input", {
  m <- matrix(rnorm(15), ncol = 3)
  expect_warning(
    model <- song(m, d = 2L, k = 3L, epochs = 3L, seed = 42, verbose = FALSE),
    "dispersion failed"
  )
  expect_s3_class(model, "song_model")
})

test_that("song() errors on Inf values", {
  m <- as.matrix(iris[1:10, 1:4])
  m[1, 1] <- Inf
  expect_error(song(m), "Inf")
})

test_that("song() errors on single row", {
  expect_error(song(matrix(1:4, nrow = 1)), "at least 2 rows")
})
